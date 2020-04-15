import nimsvg
import nimsvg/timeline
import nimsvg/styles
import os
import strformat
import lenientops

let style = defaultStyle()

proc number(xy: (float, float), val: string): Nodes =
  let w = 40.0
  let (x, y) = xy
  buildSvg:
    rect(x=x-(w/2), y=y-(w/2), rx=4, width=w, height=w, stroke="#333", `stroke-width`=1, fill="#FBFBFF")
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
  40.0 + (i+j) * 40.0

let y = 200.0

let pos4 = {"f1": (x(0, 0), y)}
let pos5 = {"f1": (100.0, 50.0), "f2 ease": (x(0, 1), y)}
let pos6 = {"f1": (x(0, 1), y), "f2 ease": (x(0, 2), y)}
let pos8 = {"f1": (x(0, 2), y), "f2 ease": (x(0, 3), y)}

tl.buildAnimation("examples" / sourceBaseName()) do (f: TimelineFrame) -> Nodes:
  let w = 800
  let h = 300
  buildSvg:
    svg(width=w, height=h):
      embed style.fontSize("10").withTextAlignLeft().text(x=10, y=290, &"Created with NimSVG (frame: {f.i:03d}, time: {f.t:.2f})")
      rect(x=20, y=f.calc({"f1 s": v(20), "f1 s ease": v(40), "f1 s ease": v(60)}))
      embed number(f.calc(pos4), "4")
      embed number(f.calc(pos5), "5")
      embed number(f.calc(pos6), "6")
      embed number(f.calc(pos8), "8")

