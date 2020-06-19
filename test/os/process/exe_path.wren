import "io" for File, Directory
import "os" for Process

System.print(Process.exePath is String) // expect: true
System.print(!Process.exePath.isEmpty) // expect: true
System.print(File.realPath(Process.exePath) == Process.exePath) // expect: true
System.print(File.exists(Process.exePath)) // expect: true
