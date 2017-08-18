import nimsvg, math

let numFrames = 20

buildAnimation("examples/anim2/anim2", numFrames) do (frame: int) -> Nodes:
  let w = 200
  let h = 200
  let centerX = w / 2
  let centerY = h / 2
  let numDots = 20
  let dotRadius = w / 40
  let circleRadius = 0.4 * w.float
  buildSvg:    
    svg(width=w, height=h):
      defs:
        filter(id="shadow", x=0, y=0, width="200%", height="200%"):
          feOffset(result="offOut", `in`="SourceAlpha", dx="20", dy="20")
          feGaussianBlur(result="blurOut", `in`="offOut", stdDeviation="10")
          feBlend(`in`="SourceGraphic", in2="blurOut", mode="normal")
      for i in 0 ..< numDots:
        let alpha = i / numDots * 2 * PI
        let x = centerX + circleRadius * sin(alpha)
        let y = centerY + circleRadius * cos(alpha)
        let peakIndex = frame / numFrames
        let frac = i / numDots
        let dist = [
          abs(peakIndex - frac),
          abs(peakIndex - frac + 1),
          abs(peakIndex - frac - 1),
        ].min()
        let radius = dotRadius + max(dotRadius - dist*dist * 20, 0)
        ! echo(i, " ", frame, " ", dist, " ", peakIndex, " ", frac)
        circle(
          cx=x, cy=y, r=radius, stroke="#333", `stroke-width`=1, fill="#EEE",
          filter="url(#shadow)"
        )
