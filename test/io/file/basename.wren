import "io" for File
import "os" for Platform

var tests = [
  {"given": "", "expect": ""}, // expect: true
  {"given": ".", "expect": "."}, // expect: true
  {"given": "..", "expect": ".."}, // expect: true
  {"given": "file.txt", "expect": "file.txt"}, // expect: true
  {"given": "/", "expect": "/"}, // expect: true
  {"given": "/foo", "expect": "foo"}, // expect: true
  {"given": "/foo/", "expect": "foo"}, // expect: true
  {"given": "/foo/bar", "expect": "bar"}, // expect: true
  {"given": "/foo/bar/", "expect": "bar"}, // expect: true
  {"given": "/foo/bar/baz", "expect": "baz"}, // expect: true
  {"given": "dir1/dir2/file", "expect": "file"}, // expect: true
  {"given": "dir1/file"     , "expect": "file"}, // expect: true
  {"given": "dir1/"  , "expect": "dir1"}, // expect: true
  {"given": "dir1///", "expect": "dir1"}, // expect: true
  {"given": "/////////"  , "expect": "/"}, // expect: true
  {"given": "///foo"     , "expect": "foo"}, // expect: true
  {"given": "///foo//"   , "expect": "foo"}, // expect: true
  {"given": "///foo//bar", "expect": "bar"}, // expect: true

  // 2 argument signature
  {"given": "dir1/file.txt", "suffixes": [".txt"]       , "expect": "file"}, // expect: true
  {"given": "dir1/file.txt", "suffixes": [".c", ".txt"] , "expect": "file"}, // expect: true
  {"given": "dir1/file.txt", "suffixes": [".c", ".wren"], "expect": "file.txt"} // expect: true
]



if (Platform.isWindows) {
  tests = tests.map {|t|
    t["given"]    = t["given"].replace("/", "\\")       
    t["expect"] = t["expect"].replace("/", "\\")
    return t
  }.toList
}

for (test in tests) {
  if (test["suffixes"]) {
    System.print(File.basename(test["given"],test["suffixes"]) == test["expect"])
  } else {
    System.print(File.basename(test["given"]) == test["expect"])
  }
}