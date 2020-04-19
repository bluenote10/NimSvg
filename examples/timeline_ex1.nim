import nimsvg
import nimsvg/timeline
import os
import strformat


let frames = @[
  frame("f_all", 0, 1),
  frame("f1", 0.0, 0.2),
  frame("f2", 0.2, 0.4),
  frame("f3", 0.4, 0.6),
  frame("f4", 0.6, 0.8),
  frame("f5", 0.8, 1.0),
]

animSettings("examples" / sourceBaseName()).buildAnimationTimeline(frames) do (f: TimelineFrame) -> Nodes:
  let w = 200
  let h = 200
  buildSvg:
    svg(width=w, height=h):
      let (x1, x2) = f.calc({"f2": (20.0, 40.0), "f4[end] ease": (100.0, 60.0)})
      let r1 = f.calc({"f2": 10.0, "f4": 20.0})
      let r2 = f.calc({"f1": 1.0, "f2": 2.0, "f3": 3.0, "f4": 4.0, "f5": 5.0})
      call:
        echo "r1 = ", r1
        echo "r2 = ", r2
      circle(cx=20, cy=20, r=r1, stroke="#445", `stroke-width`=4, fill="#EEF")
      circle(cx=80, cy=80, r=r2, stroke="#445", `stroke-width`=4, fill="#EEF")
      circle(cx=x1, cy=x2, r=10, stroke="#445", `stroke-width`=1, fill="#ABF")
      if f.calc({"f2": false, "f3": true, "f4": false}):
        circle(cx=150, cy=150, r=30, stroke="#445", `stroke-width`=4, fill="#EEF")
      text(x=20, y=130): t: &"i = {f.i:03d} t = {f.t:.2f}"

