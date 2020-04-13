import nimsvg, os

let settings = animSettings(numFrames=100, backAndForth=true)

buildAnimation("examples" / sourceBaseName(), settings) do (i: int) -> Nodes:
  let w = 200
  let h = 200
  buildSvg:
    svg(width=w, height=h):
      let r = 0.4 * w.float * i.float / settings.numFrames.float + 10
      circle(cx=w/2, cy=h/2, r=r, stroke="#445", `stroke-width`=4, fill="#EEF")