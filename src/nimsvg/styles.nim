import nimsvg

type
  Style* = object
    fill: string
    stroke: string
    strokeWidth: string

    fontSize: string
    fontFamily: string
    textAnchor: string
    dominantBaseline: string
    paintOrder: string

#[
proc with*(
  style: Style,
  fill = style.fill,
  stroke = style.stroke,
  strokeWidth = style.strokeWidth,
  fontSize = style.fontSize,
  fontFamily = style.fontFamily,
  textAnchor = style.textAnchor,
  dominantBaseline = style.dominantBaseline,
): Style =
  Style(
    stroke: stroke,
    fill: fill,
    strokeWidth: strokeWidth,
    fontSize: fontSize,
    fontFamily: fontFamily,
    textAnchor: textAnchor,
    dominantBaseline: dominantBaseline,
  )
]#

template makeSetter(funcname, field) =
  proc funcname*(s: Style, field: string): Style =
    result = s
    result.field = field

makeSetter(withfill, fill)
makeSetter(withStroke, stroke)
makeSetter(withStrokeWidth, strokeWidth)

makeSetter(withFontSize, fontSize)
makeSetter(withFontFamily, fontFamily)
makeSetter(withTextAnchor, textAnchor)
makeSetter(withDominantBaseline, dominantBaseline)

proc withTextAlignLeft*(s: Style): Style =
  result = s
  result.textAnchor = "start"

proc withTextAlignCenter*(s: Style): Style =
  result = s
  result.textAnchor = "middle"

proc withTextAlignRight*(s: Style): Style =
  result = s
  result.textAnchor = "end"

proc withPaintOrderStroke*(s: Style): Style =
  result = s
  result.paintOrder = "stroke"

proc text*(s: Style, x: float, y: float, text: string): Nodes =
  buildSvg:
    text(
      x=x,
      y=y,
      fill=s.fill,
      stroke=s.stroke,
      `text-anchor`=s.textAnchor,
      `dominant-baseline`=s.dominantBaseline,
      `font-size`=s.fontSize,
      `font-family`=s.fontFamily,
      `paint-order`=s.paintOrder,
    ): t(text)

proc defaultStyle*(): Style =
  Style(
    stroke: "#3333333",
    fill: "#555555",
    strokeWidth: "1px",
    fontSize: "16",
    fontFamily: "Ubuntu",
    textAnchor: "middle",
    dominantBaseline: "middle",
    paintOrder: "normal",
  )