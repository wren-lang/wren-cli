import "io" for Directory, Stat
import "os" for Platform

if (Directory.exists("tmp")) {
    Directory.delete("tmp")
}

System.print(Directory.exists("tmp")) // expect: false
Directory.create("tmp")
System.print(Directory.exists("tmp")) // expect: true

// Windows does not support mode
if (Platform.isPosix) {
    var stat = Stat.path("tmp")
    // 511 is 0755
    System.print(stat.mode && 0x1ff) // expect: 511
}

Directory.delete("tmp")
System.print(Directory.exists("tmp")) // expect: false



