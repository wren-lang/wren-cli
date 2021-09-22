import "io" for File
import "os" for Platform

var tests = []
tests.add({"given": "", "expect": "."}) // expect: true
tests.add({"given": ".", "expect": "."}) // expect: true
tests.add({"given": "..", "expect": "."}) // expect: true
tests.add({"given": "file.txt", "expect": "."}) // expect: true
tests.add({"given": "/", "expect": "/"}) // expect: true
tests.add({"given": "/foo", "expect": "/"}) // expect: true
tests.add({"given": "/foo/", "expect": "/"}) // expect: true
tests.add({"given": "/foo/bar", "expect": "/foo"}) // expect: true
tests.add({"given": "/foo/bar/", "expect": "/foo"}) // expect: true
tests.add({"given": "/foo/bar/baz", "expect": "/foo/bar"}) // expect: true
tests.add({"given": "dir1/dir2/file", "expect": "dir1/dir2"}) // expect: true
tests.add({"given": "dir1/file", "expect": "dir1"}) // expect: true
tests.add({"given": "dir1/", "expect": "."}) // expect: true
tests.add({"given": "dir1///", "expect": "."}) // expect: true
tests.add({"given": "/////////", "expect": "/"}) // expect: true
tests.add({"given": "///foo", "expect": "/"}) // expect: true
tests.add({"given": "///foo//", "expect": "/"}) // expect: true
tests.add({"given": "///foo//bar", "expect": "///foo"}) // expect: true

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

