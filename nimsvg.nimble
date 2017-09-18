# Package

version       = "0.1.0"
author        = "Fabian Keller"
description   = "Nim-based DSL allowing to generate SVG files and GIF animations."
license       = "MIT"

# Dependencies

srcDir = "src"

requires "nim >= 0.17.1"

task test, "Runs unit tests":
  exec "nim c -r -d:debugDsl tests/tester.nim"

task examples, "Runs examples":
  exec "nim c -r examples/basic1.nim"
  exec "nim c -r examples/basic2.nim"
  exec "nim c -r examples/text1.nim"
  exec "nim c -r examples/animation1.nim"
  exec "nim c -r examples/animation2.nim"
  exec "nim c -r examples/dsl_demo.nim"
