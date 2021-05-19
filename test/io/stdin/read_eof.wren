import "io" for Stdin
import "timer" for Timer

// stdin: one line
// stdin: two line
// stdin: three line
var read = Stdin.read() 
System.print(Stdin.isClosed) // expect: null

// we have to try reading a second time to give the EOF
// a chance to register
Stdin.read() 

System.print(read) 
// expect: one line
// expect: two line
// expect: three line

System.print(Stdin.isClosed) // expect: true
