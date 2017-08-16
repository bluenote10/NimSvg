import nimsvg

buildSvgFile("examples/example1.svg"):
  svg(width=100, height=100):
    circle(cx=50, cy=50, r=40, stroke="green", `stroke-width`=4, fill="yellow")

buildAnimation("examples/anim1/anim1", 10) do (i: int) -> Nodes:
  buildSvg:
    svg(width=100, height=100):
      circle(cx=50, cy=50, r=5*i, stroke="green", `stroke-width`=4, fill="yellow")