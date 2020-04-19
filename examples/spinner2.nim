import nimsvg, os, math

let settings = animSettings("examples" / sourceBaseName())
let numFrames = 40

settings.buildAnimation(numFrames) do (frame: int) -> Nodes:
  let w = 200
  let h = 200
  let centerX = w / 2
  let centerY = h / 2
  let numTicks = 80
  let tickLength = 0.05 * w.float
  let circleRadius = 0.4 * w.float
  buildSvg:
    svg(width=w, height=h, baseProfile="full"):
      for i in 0 ..< numTicks:
        let alpha = i / numTicks * 2 * PI
        let peakIndex = 1.0 - frame / numFrames
        let frac = i / numTicks
        let dist = [
          abs(peakIndex - frac),
          abs(peakIndex - frac + 1),
          abs(peakIndex - frac - 1),
        ].min()
        let scale = 1 - max(exp(- dist * 0.2), 0)
        for radius in [circleRadius, circleRadius*0.95, circleRadius*0.90]:
          line(
            x1 = centerX + sin(alpha) * (radius - tickLength * scale),
            y1 = centerY + cos(alpha) * (radius - tickLength * scale),
            x2 = centerX + sin(alpha) * (radius + tickLength * scale),
            y2 = centerY + cos(alpha) * (radius + tickLength * scale),
            stroke="#333",
            `stroke-width`=4
          )
