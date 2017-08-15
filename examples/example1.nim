import ../src/svg as svg_module

let svg = buildSvg:
  svg(width=100, height=100):
    circle(cx=50, cy=50, r=40, stroke="green", `stroke-width`=4, fill="yellow")

open("example1.svg", fmWrite).write(svg.render())
echo svg.render()


