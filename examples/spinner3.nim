import nimsvg, os, math

let settings = animSettings("examples" / sourceBaseName())
let numFrames = 100


settings.buildAnimation(numFrames) do (frame: int) -> Nodes:
  let w = 200
  let h = 200
  let centerX = w / 2
  let centerY = h / 2
  let dotRadius = w / 30
  let circleRadius = 0.3 * w.float
  buildSvg:
    svg(width=w, height=h, baseProfile="full"):
      defs:
        filter(id="dropshadow", x="-200%", y="-200%", width="500%", height="500%"):
          feOffset(result="offOut", `in`="SourceGraphic", dx="2", dy="2")
          feColorMatrix(result="matrixOut", `in`="offOut", type="matrix", values="0.2 0 0 0 0 0 0.2 0 0 1 0 0 0.2 0 0 0 0 0 1 0")
          feGaussianBlur(result="blurOut", `in`="matrixOut", stdDeviation=5)
          feBlend(`in`="SourceGraphic", in2="blurOut", mode="normal")
        filter(id="shadow", x="-200%", y="-200%", width="500%", height="500%"):
          feOffset(result="offOut", `in`="SourceAlpha", dx="2", dy="2")
          feGaussianBlur(result="blurOut", `in`="offOut", stdDeviation="5")
          feBlend(`in`="SourceGraphic", in2="blurOut", mode="normal")
      rect(x=0, y=0, width=w, height=h, fill="#1F1D1D")
      block:
        let alpha = - frame / numFrames * 2 * PI
        let x = centerX + circleRadius * sin(alpha)
        let y = centerY + circleRadius * cos(alpha)
        circle(
          cx=x, cy=y, r=dotRadius, stroke="#3D4574", `stroke-width`=1, fill="#ACC",
          filter="url(#shadow)"
        )
      block:
        let alpha = - frame*2 / numFrames * 2 * PI
        let x = centerX + circleRadius * sin(alpha) * 0.9
        let y = centerY + circleRadius * cos(alpha) * 0.9
        circle(
          cx=x, cy=y, r=dotRadius, stroke="#3D4574", `stroke-width`=1, fill="#CAC",
          filter="url(#shadow)"
        )
      block:
        let alpha = - frame*3 / numFrames * 2 * PI
        let x = centerX + circleRadius * sin(alpha) * 1.1
        let y = centerY + circleRadius * cos(alpha) * 1.1
        circle(
          cx=x, cy=y, r=dotRadius, stroke="#3D4574", `stroke-width`=1, fill="#CCA",
          filter="url(#shadow)"
        )
