import nimsvg

buildSvgFile("examples/text1.svg"):
  let s = "b"
  svg(width=100, height=100, baseProfile="full"):
    text(x=50,
         y=50,
         `text-anchor`="middle",
         `dominant-baseline`="central",
         style="font-family: 'Open Sans'",
         transform="rotate(-90 50 50)"):
      t: "Hello World"

