import nimsvg, ospaths, random

buildSvgFile("examples" / sourceBaseName() & ".svg"):
  let size = 200
  svg(width=size, height=size):
    for _ in 0 .. 1000:
      let x = rand(size)
      let y = rand(size)
      let radius = rand(5)
      circle(cx=x, cy=y, r=radius, stroke="#111122", fill="#E0E0F0", `fill-opacity`=0.5)
