// Import module relative to the current module.
import "../bar" for Bar
// expect: ran bar module

System.print(Bar) // expect: from bar
