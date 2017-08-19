# Package

version       = "0.1.0"
author        = "Fabian Keller"
description   = "DSL to generate SVG files"
license       = "MIT"

# Dependencies

srcDir = "src"

requires "nim >= 0.17.1"

task test, "Runs unit tests":
  exec "nim c -r tests/tester.nim"

task examples, "Runs examples":
  exec "nim c -r examples/example1.nim"
  exec "nim c -r examples/animation1.nim"
  exec "nim c -r examples/animation2.nim"
