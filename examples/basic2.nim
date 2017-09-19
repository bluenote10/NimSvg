import nimsvg, ospaths, random

buildSvgFile("examples" / sourceBaseName() & ".svg"):
  let size = 200
  svg(width=size, height=size, xmlns="http://www.w3.org/2000/svg", version="1.1"):
    for _ in 0 .. 1000:
      let x = random(size)
      let y = random(size)
      let radius = random(5)
      circle(cx=x, cy=y, r=radius, stroke="#111122", fill="#E0E0F0", `fill-opacity`=0.5)
