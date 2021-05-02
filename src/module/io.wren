import "scheduler" for Scheduler

class Directory {
  // TODO: Copied from File. Figure out good way to share this.
  static ensureString_(path) {
    if (!(path is String)) Fiber.abort("Path must be a string.")
  }

  static create(path) {
    ensureString_(path)
    return Scheduler.await_ { create_(path, Fiber.current) }
  }

  static delete(path) {
    ensureString_(path)
    return Scheduler.await_ { delete_(path, Fiber.current) }
  }

  static exists(path) {
    ensureString_(path)
    var stat
    Fiber.new {
      stat = Stat.path(path)
    }.try()

    // If we can't stat it, there's nothing there.
    if (stat == null) return false
    return stat.isDirectory
  }

  static list(path) {
    ensureString_(path)
    return Scheduler.await_ { list_(path, Fiber.current) }
  }

  foreign static create_(path, fiber)
  foreign static delete_(path, fiber)
  foreign static list_(path, fiber)
}

foreign class File {
  static create(path) {
    return openWithFlags(path,
        FileFlags.writeOnly |
        FileFlags.create |
        FileFlags.truncate)
  }

  static create(path, fn) {
    return openWithFlags(path,
        FileFlags.writeOnly |
        FileFlags.create |
        FileFlags.truncate, fn)
  }

  static delete(path) {
    ensureString_(path)
    Scheduler.await_ { delete_(path, Fiber.current) }
  }

  static exists(path) {
    ensureString_(path)
    var stat
    Fiber.new {
      stat = Stat.path(path)
    }.try()

    // If we can't stat it, there's nothing there.
    if (stat == null) return false
    return stat.isFile
  }

  static open(path) { openWithFlags(path, FileFlags.readOnly) }

  static open(path, fn) { openWithFlags(path, FileFlags.readOnly, fn) }

  // TODO: Add named parameters and then call this "open(_,flags:_)"?
  // TODO: Test.
  static openWithFlags(path, flags) {
    ensureString_(path)
    ensureInt_(flags, "Flags")
    var fd = Scheduler.await_ { open_(path, flags, Fiber.current) }
    return new_(fd)
  }

  static openWithFlags(path, flags, fn) {
    var file = openWithFlags(path, flags)
    var fiber = Fiber.new { fn.call(file) }

    // Poor man's finally. Can we make this more elegant?
    var result = fiber.try()
    file.close()

    // TODO: Want something like rethrow since now the callstack ends here. :(
    if (fiber.error != null) Fiber.abort(fiber.error)
    return result
  }

  static read(path) {
    return File.open(path) {|file| file.readBytes(file.size) }
  }

  // TODO: This works for directories too, so putting it on File is kind of
  // lame. Consider reorganizing these classes some.
  static realPath(path) {
    ensureString_(path)
    return Scheduler.await_ { realPath_(path, Fiber.current) }
  }

  static size(path) {
    ensureString_(path)
    return Scheduler.await_ { sizePath_(path, Fiber.current) }
  }

  construct new_(fd) {}

  close() {
    if (isOpen == false) return
    return Scheduler.await_ { close_(Fiber.current) }
  }

  foreign descriptor

  isOpen { descriptor != -1 }

  size {
    ensureOpen_()
    return Scheduler.await_ { size_(Fiber.current) }
  }

  stat {
    ensureOpen_()
    return Scheduler.await_ { stat_(Fiber.current) }
  }

  readBytes(count) { readBytes(count, 0) }

  readBytes(count, offset) {
    ensureOpen_()
    File.ensureInt_(count, "Count")
    File.ensureInt_(offset, "Offset")

    return Scheduler.await_ { readBytes_(count, offset, Fiber.current) }
  }

  writeBytes(bytes) { writeBytes(bytes, size) }

  writeBytes(bytes, offset) {
    ensureOpen_()
    if (!(bytes is String)) Fiber.abort("Bytes must be a string.")
    File.ensureInt_(offset, "Offset")

    return Scheduler.await_ { writeBytes_(bytes, offset, Fiber.current) }
  }

  ensureOpen_() {
    if (!isOpen) Fiber.abort("File is not open.")
  }

  static ensureString_(path) {
    if (!(path is String)) Fiber.abort("Path must be a string.")
  }

  static ensureInt_(value, name) {
    if (!(value is Num)) Fiber.abort("%(name) must be an integer.")
    if (!value.isInteger) Fiber.abort("%(name) must be an integer.")
    if (value < 0) Fiber.abort("%(name) cannot be negative.")
  }

  foreign static delete_(path, fiber)
  foreign static open_(path, flags, fiber)
  foreign static realPath_(path, fiber)
  foreign static sizePath_(path, fiber)

  foreign close_(fiber)
  foreign readBytes_(count, offset, fiber)
  foreign size_(fiber)
  foreign stat_(fiber)
  foreign writeBytes_(bytes, offset, fiber)
}

class FileFlags {
  // Note: These must be kept in sync with mapFileFlags() in io.c.

  static readOnly  { 0x01 }
  static writeOnly { 0x02 }
  static readWrite { 0x04 }
  static sync      { 0x08 }
  static create    { 0x10 }
  static truncate  { 0x20 }
  static exclusive { 0x40 }
}

foreign class Stat {
  static path(path) {
    if (!(path is String)) Fiber.abort("Path must be a string.")

    return Scheduler.await_ { path_(path, Fiber.current) }
  }

  foreign static path_(path, fiber)

  foreign blockCount
  foreign blockSize
  foreign device
  foreign group
  foreign inode
  foreign linkCount
  foreign mode
  foreign size
  foreign specialDevice
  foreign user

  foreign isFile
  foreign isDirectory
  // TODO: Other mode checks.
}

class Stdin {
  foreign static isRaw
  foreign static isRaw=(value)
  foreign static isTerminal

  static readByte() {
    return read_ {
      // Peel off the first byte.
      var byte = __buffered.bytes[0]
      __buffered = __buffered[1..-1]
      return byte
    }
  }

  static readLine() {
    return read_ {
      // TODO: Handle Windows line separators.
      var lineSeparator = __buffered.indexOf("\n")
      if (lineSeparator == -1) return null

      // Split the line at the separator.
      var line = __buffered[0...lineSeparator]
      __buffered = __buffered[lineSeparator + 1..-1]
      return line
    }
  }

  static read_(handleData) {
    // See if we're already buffered enough to immediately produce a result.
    if (__buffered != null && !__buffered.isEmpty) {
      var result = handleData.call()
      if (result != null) return result
    }

    if (__isClosed == true) Fiber.abort("Stdin was closed.")

    // Otherwise, we need to wait for input to come in.
    __handleData = handleData

    // TODO: Error if other fiber is already waiting.
    readStart_()

    __waitingFiber = Fiber.current
    var result = Scheduler.runNextScheduled_()

    readStop_()
    return result
  }

  static onData_(data) {
    // If data is null, it means stdin just closed.
    if (data == null) {
      __isClosed = true
      readStop_()

      if (__buffered != null) {
        // TODO: Is this correct for readByte()?
        // Emit the last remaining bytes.
        var result = __buffered
        __buffered = null
        __waitingFiber.transfer(result)
      } else {
        __waitingFiber.transferError("Stdin was closed.")
      }
    }

    // Append to the buffer.
    if (__buffered == null) {
      __buffered = data
    } else {
      // TODO: Instead of concatenating strings each time, it's probably faster
      // to keep a list of buffers and flatten lazily.
      __buffered = __buffered + data
    }

    // Ask the data handler if we have a complete result now.
    var result = __handleData.call()
    if (result != null) __waitingFiber.transfer(result)
  }

  foreign static readStart_()
  foreign static readStop_()
}

class Stdout {
  foreign static flush()
}
