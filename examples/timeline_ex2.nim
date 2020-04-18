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


let durHighlight = 0.5
let durBS = 0.7
let durInsert = 0.5
let tl = newTimeline(
  frames([
    ("f1.init", durHighlight),
    ("f1.bs1", durBS),
    ("f1.bs2", durBS),
    ("f2.init", durHighlight),
    ("f2.highlight", durBS),
    ("f2.bs1", durBS),
    ("f2.bs2", durInsert),
  ]),
  gifFrameTime=2
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
  let pos03 = {"f1.bs2": (insertX, insertY), "f2.init ease": (botX(0, 1), botY)}
  let pos05 = {"f1.bs2": (botX(0, 1), botY), "f2.init ease": (botX(0, 2), botY)}

  let pos08 = {"f1.init": (botX(1, 0), botY)}
  let pos11 = {"f1.init": (botX(1, 1), botY)}
  let pos13 = {"f1.init": (botX(1, 2), botY)}
  let pos16 = {"f1.init": (botX(1, 3), botY)}

  let pos19 = {"f1.init": (botX(2, 0), botY)}
  let pos22 = {"f1.init": (botX(2, 1), botY)}

  let pos28 = {"f1.init": (botX(3, 0), botY)}
  let pos32 = {"f1.init": (botX(3, 1), botY)}
  let pos38 = {"f1.init": (botX(3, 2), botY)}

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

      #[
      let opacityBinSearch1 = f.calc({
        "f1.highlight": 0.0,
        "f1.bs1 ease": 1.0,
        "f1.bs2 ease": 0.0,
      })
      let offsetBinSearch1 = f.calc({
        "f1.highlight": 10.0,
        "f1.bs1 linear": 0.0,
      })
      let r = f.calc({
        "f1.highlight": rectW / 2 * 1.2,
        "f1.bs2 ease": rectW / 2 * 1.0,
      })
      let circleStyle = style.fill("none").stroke("#333").strokeOpacity(opacityBinSearch1)
      embed circleStyle.circle(x=topX(0), y=topY, r=r)
      embed circleStyle.circle(x=topX(1), y=topY, r=r)
      embed circleStyle.circle(x=topX(2), y=topY, r=r)
      embed circleStyle.circle(x=topX(3), y=topY, r=r)
      embed style.fillOpacity(opacityBinSearch1).fontSize(10).text(w / 2, topY - 28 - offsetBinSearch1, "binary search")

      let opacityBinSearch2 = f.calc({
        "f1.bs1": 0.0,
        "f1.bs2 ease": 1.0,
        "f1.bs2[end] ease": 0.0,
      })
      let offsetBinSearch2 = f.calc({
        "f1.bs1": 10.0,
        "f1.bs2 linear": 0.0,
      })
      let r2 = f.calc({
        "f1.highlight": rectW / 2 * 1.2,
        "f1.bs2 ease": rectW / 2 * 1.0,
      })
      let circleStyle2 = style.fill("none").stroke("#333").strokeOpacity(opacityBinSearch2)
      embed circleStyle2.circle(x=botX(0, 0), y=botY, r=r2)
      embed circleStyle2.circle(x=botX(0, 1), y=botY, r=r2)
      embed style.fillOpacity(opacityBinSearch1).fontSize(10).text(0.5 * (botX(0, 0) + botX(0, 1)), botY - 28 - offsetBinSearch2, "binary search")
      ]#