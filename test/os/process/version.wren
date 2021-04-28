import "os" for Process

System.print(Process.version is String) // expect: true
System.print(Process.version.isEmpty) // expect: false

var isNumber = Fn.new {|str| Num.fromString(str) != null }
System.print(Process.version.split(".").all(isNumber)) // expect: true
System.print(Process.version.split(".").count) // expect: 3