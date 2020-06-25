import "io" for File, Directory
import "os" for Platform

System.print(Platform.homedir is String) // expect: true
System.print(!Platform.homedir.isEmpty) // expect: true
System.print(File.realPath(Platform.homedir) == Platform.homedir) // expect: true
System.print(Directory.exists(Platform.homedir)) // expect: true
