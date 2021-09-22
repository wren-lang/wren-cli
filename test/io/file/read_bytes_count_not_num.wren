import "io" for File

var file = File.open("test/io/file/file.txt")
file.readBytes("not num") // expect runtime error: Expected positive integer (Num) argument for 'count'
