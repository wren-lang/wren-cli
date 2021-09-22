import "io" for File

System.print(Fiber.new {
  File.create("file.temp") {|file|
    file.writeBytes(123)
  }
}.try()) // expect: Expected 'String' argument for 'bytes'

File.delete("file.temp")
