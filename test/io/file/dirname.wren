import "io" for File
import "os" for Platform

var tests = [
  {"given": "", "expect": ".",}, // expect: true
  {"given": ".", "expect": ".",}, // expect: true
  {"given": "..", "expect": ".",}, // expect: true
  {"given": "file.txt", "expect": ".",}, // expect: true
  {"given": "/", "expect": "/",}, // expect: true
  {"given": "/foo", "expect": "/",}, // expect: true
  {"given": "/foo/", "expect": "/",}, // expect: true
  {"given": "/foo/bar", "expect": "/foo",}, // expect: true
  {"given": "/foo/bar/", "expect": "/foo",}, // expect: true
  {"given": "/foo/bar/baz", "expect": "/foo/bar",}, // expect: true
  {"given": "dir1/dir2/file", "expect": "dir1/dir2",}, // expect: true
  {"given": "dir1/file", "expect": "dir1",}, // expect: true
  {"given": "dir1/", "expect": ".",}, // expect: true
  {"given": "dir1///", "expect": ".",}, // expect: true
  {"given": "/////////", "expect": "/",}, // expect: true
  {"given": "///foo", "expect": "/",}, // expect: true
  {"given": "///foo//", "expect": "/",}, // expect: true
  {"given": "///foo//bar", "expect": "///foo",} // expect: true
]

if (Platform.isWindows) {
  tests = tests.map {|t|
    t["given"]    = t["given"].replace("/", "\\")
    t["expect"] = t["expect"].replace("/", "\\")
    return t
  }.toList
}

for (test in tests) {
  System.print(File.dirname(test["given"]) == test["expect"])
}

