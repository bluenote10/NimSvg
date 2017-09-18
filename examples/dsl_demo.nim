import nimsvg

proc circles(): Nodes =
  buildSvg:
    circle(cx=0, cy=0)
    circle(cx=1, cy=0)
    g():
      circle(cx=0, cy=1)
      circle(cx=1, cy=1)
      circle(cx=2, cy=1)

proc main(): Nodes =
  buildSvg:
    embed circles()
    embed circles()

buildSvgFile("examples/example1.svg"):
  svg(width=100, height=100):
    embed main()

