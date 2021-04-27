import "os" for Platform

var platforms = [
    "Windows",
    "iOS",
    "OS X",
    "Unknown",
    "Linux",
    "Unix",
    "POSIX"
]

// Can't test for certain values since this test is cross-platform, but we can
// at least make sure it is callable and returns a string.
System.print(Platform.name is String) // expect: true
System.print(platforms.contains(Platform.name)) // expect: true