import nimsvg

buildSvgFile("examples/basic1.svg"):
  svg(width=200, height=200, xmlns="http://www.w3.org/2000/svg", version="1.1"):
    circle(cx=100, cy=100, r=80, stroke="teal", `stroke-width`=4, fill="#DDD")
