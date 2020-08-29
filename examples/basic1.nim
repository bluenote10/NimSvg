import nimsvg

buildSvgFile("examples/basic1.svg"):
  svg(width=200, height=200):
    circle(cx=100, cy=100, r=80, stroke="teal", `stroke-width`=4, fill="#EEF")
