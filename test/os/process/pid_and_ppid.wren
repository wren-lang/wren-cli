import "os" for Process

System.print(Process.pid is Num) // expect: true
System.print(Process.pid.isInteger) // expect: true
System.print(Process.pid > 0) // expect: true

System.print(Process.ppid is Num) // expect: true
System.print(Process.ppid.isInteger) // expect: true
System.print(Process.ppid > 0) // expect: true

System.print(Process.pid > Process.ppid) // expect: true
