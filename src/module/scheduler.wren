class Scheduler {
  static add(callable) {
    __scheduled.add(Fiber.new {
      callable.call()
      runNextScheduled_()
    })
  }

  // Called by native code.
  static resume_(fiber) { fiber.transfer() }
  static resume_(fiber, arg) { fiber.transfer(arg) }
  static resumeError_(fiber, error) { fiber.transferError(error) }

  // wait for a method to finish that has a callback on the C side
  static await_(fn) {
    fn.call()
    return Scheduler.runNextScheduled_()
  }

  static runNextScheduled_() {
    if (__scheduled.isEmpty) {
      return Fiber.suspend()
    } else {
      return __scheduled.removeAt(0).transfer()
    }
  }

  static start_() { __scheduled = [] }
  foreign static captureMethods_()
}

Scheduler.start_()
Scheduler.captureMethods_()
