import "io" for File

System.print(Fiber.new {
  File.create("file.temp") {|file|
    file.writeBytes("", -1)
  }
}.try()) // expect: Expected positive integer (Num) argument for 'offset'

File.delete("file.temp")
