import nimsvg
import nimsvg/timeline
import nimsvg/styles
import os
import strformat
import lenientops

let style = defaultStyle()

let w = 30.0

proc number(xy: (float, float), val: string): Nodes =
  let (x, y) = xy
  buildSvg:
    embed style.stroke("#333").fill("#FBFBFF").rx(4).rectCentered(x, y, w, w)
    embed style.fontSize(16).fill("#444").stroke("#111").text(x, y, val)


let frameTime = 0.5
let tl = newTimeline(
  frames([
    ("f1", 0.0 * frameTime),
    ("f2", 1.0 * frameTime),
    ("f3", 2.0 * frameTime),
  ]),
  gifFrameTime=2
)

proc x(i, j: int): float =
  w + (i * w * 5) + j * w

let y = 200.0

let pos04 = {"f1": (x(0, 0), y)}
let pos05 = {"f1": (100.0, 50.0), "f2 ease": (x(0, 1), y)}
let pos06 = {"f1": (x(0, 1), y), "f2 ease": (x(0, 2), y)}
let pos08 = {"f1": (x(0, 2), y), "f2 ease": (x(0, 3), y)}

let pos13 = {"f1": (x(1, 0), y)}
let pos16 = {"f1": (x(1, 1), y)}
let pos17 = {"f1": (x(1, 2), y)}

let pos24 = {"f1": (x(2, 0), y)}
let pos31 = {"f1": (x(2, 1), y)}

tl.buildAnimation("examples" / sourceBaseName()) do (f: TimelineFrame) -> Nodes:
  let w = 800
  let h = 300
  buildSvg:
    svg(width=w, height=h):
      embed style.fontSize("10").withTextAlignLeft().text(
        x=10, y=290, &"Created with NimSVG (frame: {f.i:03d}, time: {f.t:.2f})"
      )
      embed number(f.calc(pos04), "4")
      embed number(f.calc(pos06), "6")
      embed number(f.calc(pos08), "8")

      embed number(f.calc(pos13), "13")
      embed number(f.calc(pos16), "16")
      embed number(f.calc(pos17), "17")

      embed number(f.calc(pos24), "24")
      embed number(f.calc(pos31), "31")

      embed number(f.calc(pos05), "5")

