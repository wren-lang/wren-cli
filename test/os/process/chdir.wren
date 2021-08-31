import "io" for Directory
import "os" for Process

var tmpdir = "tmp.%(Process.pid)"

if (Directory.exists(tmpdir)) Directory.delete(tmpdir)
Directory.create(tmpdir)

var oldCwd = Process.cwd

Process.chdir(tmpdir)
var cwd = Process.cwd

System.print(oldCwd == cwd) // expect: false
System.print(cwd.endsWith(tmpdir)) // expect: true

Process.chdir("..")
cwd = Process.cwd

System.print(oldCwd == cwd) // expect: true
System.print(cwd.endsWith(tmpdir)) // expect: false

Directory.delete(tmpdir)
