import nimsvg

let numFrames = 100
let settings = animSettings().backAndForth(true)

buildAnimation("examples/anim1/anim1", numFrames, settings) do (i: int) -> Nodes:
  let w = 200
  let h = 200
  buildSvg:
    svg(width=w, height=h):
      let r = 0.4 * w.float * i.float / numFrames.float + 10
      circle(cx=w/2, cy=h/2, r=r, stroke="#445", `stroke-width`=4, fill="#EEF")