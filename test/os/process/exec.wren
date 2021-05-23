import "os" for Platform, Process

var TRY = Fn.new { |fn|
  var fiber = Fiber.new {
    fn.call()
  }
  return fiber.try()
}

var result
if(Platform.name == "Windows") {
  result = Process.exec("cmd.exe")
} else {
  result = Process.exec("true")
}
System.print(result) // expect: 0

// basics

if (Platform.isWindows) {
  // TODO: more windows argument specific tests
} else {
  // known output of success/fail based on only command name
  System.print(Process.exec("true")) // expect: 0
  System.print(Process.exec("false")) // expect: 1
  // these test that our arguments are being passed as it proves
  // they effect the result code returned
  System.print(Process.exec("test", ["2", "-eq", "2"])) // expect: 0
  System.print(Process.exec("test", ["2", "-eq", "3"])) // expect: 1
}

// cwd

if (Platform.isWindows) {
  // TODO: can this be done with dir on windows?
} else {
  // tests exists in our project folder
  System.print(Process.exec("ls", ["test"])) // expect: 0
  // but does not in our `src` folder
  System.print(Process.exec("ls", ["test"], "./src/")) // expect: 1
}

// env

if (Platform.name == "Windows") { 
  // TODO: how?
} else {
  System.print(Process.exec("true",[],null,{})) // expect: 0
  var result = TRY.call { 
    Process.exec("ls",[],null,{"PATH": "/whereiscarmen/"}) 
  }
  System.print(result) 
  // TODO: should be on stderr
  // expect: Could not launch ls, reason: no such file or directory
  // TODO: should this be a runtime error?????
  // expect: Could not spawn process.
}