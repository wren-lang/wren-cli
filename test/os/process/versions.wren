import "os" for Process

System.print(Process.versions is Map) // expect: true
System.print(Process.versions.count >= 2) // expect: true
System.print(Process.versions["wren"] is String) // expect: true
System.print(Process.versions["wren"].isEmpty) // expect: false
System.print(Process.versions["uv"] is String) // expect: true
System.print(Process.versions["uv"].isEmpty) // expect: false

var isNumber = Fn.new {|str| Num.fromString(str) != null }
System.print(Process.versions["wren"].split(".").all(isNumber)) // expect: true
System.print(Process.versions["uv"].split(".").all(isNumber)) // expect: true
