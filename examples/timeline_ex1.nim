import nimsvg
import nimsvg/timeline
import os
import strformat


let tl = block:
  var tl = newTimeline(gifFrameTime=2)
  tl.addFrame("f_all", 0, 1)
  tl.addFrame("f1", 0.0, 0.2)
  tl.addFrame("f2", 0.2, 0.4)
  tl.addFrame("f3", 0.4, 0.6)
  tl.addFrame("f4", 0.6, 0.8)
  tl.addFrame("f5", 0.8, 1.0)
  tl


tl.buildAnimation("examples" / sourceBaseName()) do (f: TimelineFrame) -> Nodes:
  let w = 200
  let h = 200
  buildSvg:
    svg(width=w, height=h):
      let x1 = f.calc({"f2 s": 20.0, "f4 e ease": 100.0})
      let r1 = f.calc({"f2 s": 10.0, "f4 s": 20.0})
      let r2 = f.calc({"f1 s": 1.0, "f2 s": 2.0, "f3 s": 3.0, "f4 s": 4.0, "f5 s": 5.0})
      call:
        echo "r1 = ", r1
        echo "r2 = ", r2
      circle(cx=20, cy=20, r=r1, stroke="#445", `stroke-width`=4, fill="#EEF")
      circle(cx=80, cy=80, r=r2, stroke="#445", `stroke-width`=4, fill="#EEF")
      circle(cx=x1, cy=40, r=10, stroke="#445", `stroke-width`=1, fill="#ABF")
      if f.calc({"f2": false, "f3": true, "f4": false}):
        circle(cx=150, cy=150, r=30, stroke="#445", `stroke-width`=4, fill="#EEF")
      text(x=20, y=130): t: &"i = {f.i:03d} t = {f.t:.2f}"

