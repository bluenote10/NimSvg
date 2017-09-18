import nimsvg

buildSvgFile("examples/example1.svg"):
  let size = 100
  svg(width=size, height=size):
    circle(cx=50, cy=50, r=40, stroke="green", `stroke-width`=4, fill="yellow")
