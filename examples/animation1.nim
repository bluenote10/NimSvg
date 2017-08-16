import nimsvg

let numFrames = 100

buildAnimation("examples/anim1/anim1", numFrames) do (i: int) -> Nodes:
  let w = 200
  let h = 200
  buildSvg:
    svg(width=w, height=h):
      let r = (w / 2) * i.float / numFrames.float
      circle(cx=w/2, cy=h/2, r=r, stroke="green", `stroke-width`=4, fill="yellow")