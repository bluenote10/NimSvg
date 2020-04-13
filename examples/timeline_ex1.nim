import nimsvg
import nimsvg_timeline
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


tl.buildAnimation("examples" / sourceBaseName()) do (c: Callback, frameInfo: FrameInfo) -> Nodes:
  let w = 200
  let h = 200
  buildSvg:
    svg(width=w, height=h):
      let x1 = c([("f2 s", v(20)), ("f4 e ease", v(100))])
      let r1 = c([("f2 s", v(10)), ("f4 s", v(20))])
      let r2 = c([("f1 s", v(1)), ("f2 s", v(2)), ("f3 s", v(3)), ("f4 s", v(4)), ("f5 s", v(5))])
      call:
        echo "r1 = ", r1
        echo "r2 = ", r2
      circle(cx=20, cy=20, r=r1, stroke="#445", `stroke-width`=4, fill="#EEF")
      circle(cx=80, cy=80, r=r2, stroke="#445", `stroke-width`=4, fill="#EEF")
      circle(cx=x1, cy=40, r=10, stroke="#445", `stroke-width`=1, fill="#ABF")
      text(x=20, y=130): t: &"i = {frameInfo.i:03d} t = {frameInfo.t:.2f}"

