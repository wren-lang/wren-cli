import "io" for File

File.realPath(123) // expect runtime error: Expected 'String' argument for 'path'

// TODO: Write success case tests too when we have an API to create symlinks
// from Wren.
