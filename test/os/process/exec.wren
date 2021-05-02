import "os" for Platform, Process

var result
if(Platform.name == "Windows") {
  result = Process.exec("cmd.exe", [])
} else {
  // works on Mac
  result = Process.exec("/usr/bin/true", [])
}
System.print(result) // expect: 0

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
