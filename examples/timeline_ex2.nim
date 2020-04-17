import nimsvg
import nimsvg/timeline
import nimsvg/styles
import os
import strformat
import lenientops

let style = defaultStyle()

let w = 800
let h = 300
let rectW = 30.0

let (insertX, insertY) = (w.float / 2.0, 30.0)

let topY = 120.0
let botY = 200.0

proc number(xy: (float, float), val: string, ghost: bool = false): Nodes =
  let (stroke, fill) =
    if ghost:
      ("#DDDDDD", "#DDDDDD")
    else:
      ("#111", "#444")

  let (x, y) = xy
  buildSvg:
    embed style.stroke("#333").fill("#FBFBFF").rx(4).rectCentered(x, y, rectW, rectW)
    embed style.fontSize(16).fill(fill).stroke(stroke).text(x, y, val)


let frameTime = 0.5
let tl = newTimeline(
  frames([
    ("f1.init", frameTime),
    ("f1.bs1", frameTime),
    ("f1.bs2", frameTime),
    ("f2.init", frameTime),
    ("f2.bs1", frameTime),
    ("f2.bs2", frameTime),
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


  proc x(i, j: int): float =
    rectW + (i * rectW * 5) + j * rectW

  let pos04 = {"f1.init": (x(0, 0), botY)}
  let pos05 = {"f1.init": (insertX, insertY), "f2.init ease": (x(0, 1), botY)}
  let pos06 = {"f1.init": (x(0, 1), botY), "f2.init ease": (x(0, 2), botY)}
  let pos08 = {"f1.init": (x(0, 2), botY), "f2.init ease": (x(0, 3), botY)}

  let pos13 = {"f1.init": (x(1, 0), botY)}
  let pos16 = {"f1.init": (x(1, 1), botY)}
  let pos17 = {"f1.init": (x(1, 2), botY)}

  let pos24 = {"f1.init": (x(2, 0), botY)}
  let pos31 = {"f1.init": (x(2, 1), botY)}

  buildSvg:
    svg(width=w, height=h):
      embed style.fontSize(10).withTextAlignLeft().text(
        x=10, y=290, &"Created with NimSVG (frame: {f.i:03d}, time: {f.t:.2f})"
      )

      embed style.withTextAlignRight().text(x=w / 2.0 - 30, y=insertY, "Insert:")

      embed number(f.calc({
        "f1.init": (topX(0), topY)
      }), "4", ghost=true)
      embed number(f.calc({
        "f1.init": (topX(1), topY)
      }), "13", ghost=true)
      embed number(f.calc({
        "f1.init": (topX(2), topY)
      }), "24", ghost=true)

      let opacityBinSearch1 = f.calc({
        "f1.init": 0.0,
        "f1.bs1 ease": 1.0,
        "f1.bs2 ease": 0.0,
      })
      let r = f.calc({
        "f1.init": rectW / 2 * 0.9,
        "f1.bs2 ease": rectW / 2 * 1.1,
      })
      let circleStyle = style.fill("none").stroke("#333").strokeOpacity(opacityBinSearch1)
      embed circleStyle.circle(x=topX(0), y=topY, r=r)
      embed circleStyle.circle(x=topX(1), y=topY, r=r)
      embed circleStyle.circle(x=topX(2), y=topY, r=r)

      embed number(f.calc(pos04), "4")
      embed number(f.calc(pos06), "6")
      embed number(f.calc(pos08), "8")

      embed number(f.calc(pos13), "13")
      embed number(f.calc(pos16), "16")
      embed number(f.calc(pos17), "17")

      embed number(f.calc(pos24), "24")
      embed number(f.calc(pos31), "31")

      embed number(f.calc(pos05), "5")

