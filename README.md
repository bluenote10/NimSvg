# NimSvg  [![Build Status](https://travis-ci.org/bluenote10/NimSvg.svg?branch=master)](https://travis-ci.org/bluenote10/NimSvg)

Nim-based DSL allowing to generate SVG files and GIF animations.

## DSL

NimSvg is inspired by [Karax](https://github.com/pragmagic/karax), and offers a similar DSL to generate SVG trees.
A simple hello world

```nimrod
import nimsvg

buildSvgFile("examples/basic1.svg"):
  svg(width=200, height=200):
    circle(cx=100, cy=100, r=80, stroke="teal", `stroke-width`=4, fill="#DDD")
```

produces the following SVG:

```svg
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="200" height="200">
  <circle cx="100" cy="100" r="80" stroke="teal" stroke-width="4" fill="#DDD"/>
</svg>
```

Output:

![basic1](https://rawgit.com/bluenote10/NimSvg/master/examples/basic1.svg?sanitize=true)

The DSL allows to mix tag expressions with regular Nim expressions like variable definitions, for loops, or if statements,
which makes it easy to generate SVGs programmatically:

```nimrod
import nimsvg, ospaths, random

buildSvgFile("examples" / sourceBaseName() & ".svg"):
  let size = 200
  svg(width=size, height=size):
    for _ in 0 .. 1000:
      let x = random(size)
      let y = random(size)
      let radius = random(5)
      circle(cx=x, cy=y, r=radius, stroke="#111122", fill="#E0E0F0", `fill-opacity`=0.5)
```

Output:

![basic2](https://rawgit.com/bluenote10/NimSvg/master/examples/basic2.svg?sanitize=true)

NimSvg also allows to render a sequence of SVG files into an animated GIF (requires Imagemagick for the rendering):

```nimrod
import nimsvg, ospaths

let numFrames = 100
let settings = animSettings().backAndForth(true)

buildAnimation("examples" / sourceBaseName(), numFrames, settings) do (i: int) -> Nodes:
  let w = 200
  let h = 200
  buildSvg:
    svg(width=w, height=h):
      let r = 0.4 * w.float * i.float / numFrames.float + 10
      circle(cx=w/2, cy=h/2, r=r, stroke="#445", `stroke-width`=4, fill="#EEF")
```

Output:

[![animation1](examples/animation1.gif)](examples/animation1.nim)


## Gallery

Click on an image to see the corresponding implementation.

[![spinner1](examples/spinner1.gif)](examples/spinner1.nim)

[![spinner2](examples/spinner2.gif)](examples/spinner2.nim)
