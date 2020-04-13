import nimsvg
import nimsvg/timeline
import os
import strformat
import lenientops

proc number(i: int, val: string): Nodes =
  let w = 40.0
  let x = w + w * i
  buildSvg:
    rect(x=x-(w/2), y=50-(w/2), rx=4, width=w, height=w, stroke="#333", `stroke-width`=1, fill="#FBFBFF")
    text(
      x=x, y=50,
      `dominant-baseline`="middle",
      `text-anchor`="middle",
      style="font-family: 'Ubuntu'",
      `font-size`=24,
      fill: "#333",
    ): t: val


let tl = newTimeline(
  frames([
    ("f1", 0.0),
    ("f2", 1.0),
    ("f3", 2.0),
  ]),
  gifFrameTime=2
)

tl.buildAnimation("examples" / sourceBaseName()) do (f: TimelineFrame) -> Nodes:
  let w = 200
  let h = 200
  buildSvg:
    svg(width=w, height=h):
      text(x=10, y=10): t: &"i = {f.i:03d} t = {f.t:.2f}"
      rect(x=20, y=f.calc({"f1 s": v(20), "f1 s ease": v(40), "f1 s ease": v(60)}))
      embed number(0, "4")
      embed number(1, "6")
      embed number(2, "8")

