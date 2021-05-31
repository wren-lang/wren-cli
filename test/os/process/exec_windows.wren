// platform: Windows
import "os" for Platform, Process
import "io" for Stdout

var TRY = Fn.new { |fn|
  var fiber = Fiber.new {
    fn.call()
  }
  return fiber.try()
}

// TODO: flesh out as much as exec_unix.wrenn

var result
if(Platform.name == "Windows") {
  result = Process.exec("cmd",["/c","echo hi"])
  // expect: hi
  System.print(result) // expect: 0
}


