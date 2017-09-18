import nimsvg, math

let numFrames = 40

buildAnimation("examples/anim2/anim2", numFrames, animSettings()) do (frame: int) -> Nodes:
  let w = 200
  let h = 200
  let centerX = w / 2
  let centerY = h / 2
  let numDots = 20
  let dotRadius = w / 40
  let circleRadius = 0.4 * w.float
  buildSvg:
    svg(width=w, height=h, xmlns="http://www.w3.org/2000/svg", version="1.1", baseProfile="full"):
      defs:
        filter(id="shadow", x="-200%", y="-200%", width="500%", height="500%"):
          feOffset(result="offOut", `in`="SourceAlpha", dx="2", dy="2")
          feGaussianBlur(result="blurOut", `in`="offOut", stdDeviation="5")
          feBlend(`in`="SourceGraphic", in2="blurOut", mode="normal")
      for i in 0 ..< numDots:
        let alpha = i / numDots * 2 * PI
        let x = centerX + circleRadius * sin(alpha)
        let y = centerY + circleRadius * cos(alpha)
        let peakIndex = 1.0 - frame / numFrames
        let frac = i / numDots
        let dist = [
          abs(peakIndex - frac),
          abs(peakIndex - frac + 1),
          abs(peakIndex - frac - 1),
        ].min()
        let radius = dotRadius + max(dotRadius - dist*dist * 20, 0)
        # call: echo(i, " ", frame, " ", dist, " ", peakIndex, " ", frac)
        circle(
          cx=x, cy=y, r=radius, stroke="#3D4574", `stroke-width`=1, fill="#DDD",
          filter="url(#shadow)"
        )
