import "io" for File

File.open(123) {|file|} // expect runtime error: Expected 'String' argument for 'path'
