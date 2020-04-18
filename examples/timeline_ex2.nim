import nimsvg
import nimsvg/timeline
import nimsvg/styles
import os
import strformat
import math
import lenientops

let style = defaultStyle()

let w = 800
let h = 300
let rectW = 30.0

let (insertX, insertY) = (w.float / 2.0, 30.0)

let topY = 120.0
let botY = 200.0

proc number(xy: (float, float), val: string, ghost: bool = false, opacity = 1.0): Nodes =
  let (stroke, fill) =
    if ghost:
      ("#DDDDDD", "#DDDDDD")
    else:
      ("#111", "#444")

  let (x, y) = xy
  let style = style.fillOpacity(opacity).strokeOpacity(opacity)
  buildSvg:
    embed style.stroke("#333").fill("#FBFBFF").rx(4).rectCentered(x, y, rectW, rectW)
    embed style.fontSize(16).fill(fill).stroke(stroke).text(x, y, val)


proc binarySearchVis(f: TimelineFrame, xs: seq[float], y: float, frame: string): Nodes =
  let middle = xs.sum() / xs.len()
  buildSvg:
    let opacity = f.calc({
      &"{frame}[-0.1 s]": 0.0,
      &"{frame} ease": 1.0,
      &"{frame}[end] ease": 0.0,
    })
    let offset = f.calc({
      &"{frame}[-0.1 s]": 10.0,
      &"{frame}[end] linear": 0.0,
    })
    let r = f.calc({
      &"{frame}[-0.1 s]": rectW / 2 * 1.2,
      &"{frame}[end] ease": rectW / 2 * 1.0,
    })
    let circleStyle = style.fill("none").stroke("#333").strokeOpacity(opacity)
    for x in xs:
      embed circleStyle.circle(x=x, y=y, r=r)
    embed style.fillOpacity(opacity).fontSize(10).text(middle, y - 28 - offset, "binary search")


let durHighlight = 1.0
let durBS = 1.0
let durInsert = 1.0
let tl = newTimeline(
  frames([

    ("f1.init", durHighlight),
    ("f1.bs1", durBS),
    ("f1.bs2", durBS),
    ("f1.insert", durInsert),

    ("f2.init", durHighlight),
    ("f2.bs1", durBS),
    ("f2.split", 2.0),
    ("f2.bs2", durBS),
    ("f2.insert", durInsert),

  ]),
)

tl.buildAnimation("examples" / sourceBaseName()) do (f: TimelineFrame) -> Nodes:

  let numTopElements = f.calc({
    "f1.init": 3,
  })

  proc topX(i: int): float =
    let left = w.float / 2.0 - (numTopElements * rectW / 2.0)
    left + i * rectW


  proc botX(i, j: int): float =
    rectW + (i * rectW * 5) + j * rectW

  let pos02 = {"f1.init": (botX(0, 0), botY)}
  let pos03 = {"f1.insert": (insertX, insertY), "f1.insert[end] ease": (botX(0, 1), botY)}
  let pos05 = {"f1.insert": (botX(0, 1), botY), "f1.insert[end] ease": (botX(0, 2), botY)}

  let pos08 = {"f1.init": (botX(1, 0), botY)}
  let pos11 = {"f1.init": (botX(1, 1), botY)}
  let pos13 = {"f2.split": (botX(1, 2), botY), "f2.split[end] ease": (botX(2, 0), botY)}
  let pos15 = {"f2.insert": (insertX, insertY), "f2.insert[end] ease": (botX(2, 1), botY)}
  let pos16 = {"f2.split": (botX(1, 3), botY), "f2.split[end] ease": (botX(2, 1), botY), "f2.insert[end] ease": (botX(2, 2), botY)}

  let pos19 = {"f2.split": (botX(2, 0), botY), "f2.split[end] ease": (botX(3, 0), botY)}
  let pos22 = {"f2.split": (botX(2, 1), botY), "f2.split[end] ease": (botX(3, 1), botY)}

  let pos28 = {"f2.split": (botX(3, 0), botY), "f2.split[end] ease": (botX(4, 0), botY)}
  let pos32 = {"f2.split": (botX(3, 1), botY), "f2.split[end] ease": (botX(4, 1), botY)}
  let pos38 = {"f2.split": (botX(3, 2), botY), "f2.split[end] ease": (botX(4, 2), botY)}

  buildSvg:
    svg(width=w, height=h):
      embed style.fontSize(10).withTextAlignLeft().text(
        x=10, y=290, &"Created with NimSVG (frame: {f.i:03d}, time: {f.t:.2f})"
      )

      let offset = f.calc({
        "f1.init": 50.0,
        "f1.init[end] outcubic": 0.0,
      })
      let opacity = f.calc({
        "f1.init": 0.0,
        "f1.init[end] outcubic": 1.0,
      })
      embed style.withTextAlignRight().fillOpacity(opacity).text(x=w / 2.0 - 30 - offset, y=insertY, "Insert:")

      embed style.withTextAlignLeft().text(x=30, y=insertY, "Max leaf capacity: 4")
      let maxLeafWarnOpacity = f.calc({
        "f2.split[-0.1s]": 0.0,
        "f2.split linear": 1.0,
        "f2.split[end] linear": 0.0,
      })
      let warnColor = "#de133f"
      let styleRed = style.fill(warnColor).stroke(warnColor).strokeOpacity(maxLeafWarnOpacity).fillOpacity(maxLeafWarnOpacity)
      embed styleRed.fillOpacity(maxLeafWarnOpacity*0.01).rx(8).rect(20, insertY-20, 165, 40)
      embed styleRed.withTextAlignCenter().noStroke().fontSize(10).text(20.0 + 165.0/2.0, insertY+30, "split leaf")

      embed number(f.calc({
        "f1.init": (topX(0), topY)
      }), "2", ghost=true)
      embed number(f.calc({
        "f1.init": (topX(1), topY)
      }), "8", ghost=true)
      embed number(f.calc({
        "f1.init": (topX(2), topY)
      }), "19", ghost=true)
      embed number(f.calc({
        "f1.init": (topX(3), topY)
      }), "28", ghost=true)

      embed number(f.calc(pos02), "2")
      embed number(f.calc(pos05), "5")

      embed number(f.calc(pos08), "8")
      embed number(f.calc(pos11), "11")
      embed number(f.calc(pos13), "13")
      embed number(f.calc(pos16), "16")

      embed number(f.calc(pos19), "19")
      embed number(f.calc(pos22), "22")

      embed number(f.calc(pos28), "28")
      embed number(f.calc(pos32), "32")
      embed number(f.calc(pos38), "38")

      # inserted numbers
      embed number(f.calc(pos03), "3", opacity=f.calc({
        "f1.init": 0.0,
        "f1.init[end] linear": 1.0,
      }))
      embed number(f.calc(pos15), "15", opacity=f.calc({
        "f2.init": 0.0,
        "f2.init[end] linear": 1.0,
      }))

      embed f.binarySearchVis(
        xs= @[topX(0), topX(1), topX(2), topX(3)],
        y=topY,
        frame="f1.bs1"
      )
      embed f.binarySearchVis(
        xs= @[botX(0, 0), botX(0, 1)],
        y=botY,
        frame="f1.bs2"
      )
      embed f.binarySearchVis(
        xs= @[topX(0), topX(1), topX(2), topX(3)],
        y=topY,
        frame="f2.bs1"
      )
      embed f.binarySearchVis(
        xs= @[botX(2, 0), botX(2, 1)],
        y=botY,
        frame="f2.bs2"
      )
