import nimsvg

buildSvgFile("examples/embed_other_svgs.svg"):
  svg(width=200, height=200):
    embed loadSVG("examples/basic1.svg")
    embed loadSVG("examples/basic2.svg")
