import "os" for Platform, Process

var TRY = Fn.new { |fn|
  var fiber = Fiber.new {
    fn.call()
  }
  return fiber.try()
}

var result
if(Platform.name == "Windows") {
  result = Process.exec("cmd.exe", [])
} else {
  // works on Mac
  result = Process.exec("/usr/bin/true", [])
}
System.print(result) // expect: 0

// basics

if (Platform.isPosix) {
  // known output of success/fail based on only command name
  System.print(Process.exec("/usr/bin/true")) // expect: 0
  System.print(Process.exec("/usr/bin/false")) // expect: 1
  // these test that our arguments are being passed as it proves
  // they effect the result code returned
  System.print(Process.exec("/bin/test", ["2", "-eq", "2"])) // expect: 0
  System.print(Process.exec("/bin/test", ["2", "-eq", "3"])) // expect: 1
} else if (Platform.name == "Windows") {
  // TODO: more windows argument specific tests
}

// cwd

if (Platform.isPosix) {
  // tests exists in our root
  System.print(Process.exec("ls", ["test"])) // expect: 0
  // but not in our `src` folder
  System.print(Process.exec("ls", ["test"], "./src/")) // expect: 1
} else if (Platform.name == "Windows") {
  // TODO: can this be done with dir on windows?
}

// env

if (Platform.isPosix) {
  System.print(Process.exec("/usr/bin/true",[],null,{})) // expect: 0
  var r = TRY.call { 
    Process.exec("ls",[],null,{"PATH": "/binx/"}) 
  }
  System.print(r) 
  // TODO: should be on stderr
  // expect: Could not launch ls, reason: no such file or directory
  // TODO: should this be a runtime error?????
  // expect: Could not spawn process.
} else if (Platform.name == "Windows") { 

}