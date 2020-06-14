import "io" for File, Directory
import "os" for Process

System.print(Process.cwd is String) // expect: true
System.print(!Process.cwd.isEmpty) // expect: true
System.print(Process.cwd.startsWith("/")) // expect: true
System.print(File.realPath(Process.cwd) == Process.cwd) // expect: true
System.print(Directory.exists(Process.cwd)) // expect: true
