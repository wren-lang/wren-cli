import "io" for File, Directory
import "os" for Platform

System.print(Platform.homePath is String) // expect: true
System.print(!Platform.homePath.isEmpty) // expect: true
System.print(File.realPath(Platform.homePath) == Platform.homePath) // expect: true
System.print(Directory.exists(Platform.homePath)) // expect: true
