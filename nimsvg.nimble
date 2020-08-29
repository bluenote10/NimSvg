# Package

version       = "0.1.0"
author        = "Fabian Keller"
description   = "Nim-based DSL allowing to generate SVG files and GIF animations."
license       = "MIT"

# Dependencies

srcDir = "src"

requires "nim >= 0.17.1"

task test, "Runs unit tests":
  exec "nim c -r -d:debugDsl -d:unittest tests/tester.nim"

task examples, "Runs examples":
  exec "nim c -r examples/basic1.nim"
  exec "nim c -r examples/basic2.nim"
  exec "nim c -r examples/text1.nim"
  exec "nim c -r examples/animation1.nim"
  exec "nim c -r examples/spinner1.nim"
  exec "nim c -r examples/spinner2.nim"
  exec "nim c -r examples/spinner3.nim"
  exec "nim c -r examples/dsl_demo.nim"
  exec "nim c -r examples/timeline_ex1.nim"
  exec "nim c -r examples/timeline_ex2.nim"
  exec "nim c -r examples/embed_other_svgs.nim"

task docs, "Generates docs":
  exec "nim doc2 --project --docSeeSrcUrl:https://github.com/bluenote10/NimSvg/blob/master -o:./docs/ src/nimsvg.nim"