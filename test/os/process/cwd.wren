import "io" for File, Directory
import "os" for Process, Platform

System.print(Process.cwd is String) // expect: true
System.print(!Process.cwd.isEmpty) // expect: true

if (Platform.isWindows) {
  System.print(Process.cwd[1..-1].startsWith(":\\"))
} else {
  System.print(Process.cwd.startsWith("/")) 
}
// expect: true

System.print(File.realPath(Process.cwd) == Process.cwd) // expect: true
System.print(Directory.exists(Process.cwd)) // expect: true
