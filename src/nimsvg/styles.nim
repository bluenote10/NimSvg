import nimsvg
import options
import better_options

# General reference:
# https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute

type
  Style* = object
    fill: Option[string]
    stroke: Option[string]
    strokeWidth: Option[string]

    fontSize: Option[string]
    fontFamily: Option[string]
    textAnchor: Option[string]
    dominantBaseline: Option[string]
    paintOrder: Option[string]

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

template makeGetterSetter(field) =

  proc field*(s: Style): Option[string] =
    s.field

  proc field*[T](s: Style, x: T): Style =
    result = s
    result.field = some($x)

  proc `no field`*(s: Style): Style =
    result = s
    result.field = none[string]()


makeGetterSetter(fill)
makeGetterSetter(stroke)
makeGetterSetter(strokeWidth)

makeGetterSetter(fontSize)
makeGetterSetter(fontFamily)
makeGetterSetter(textAnchor)
makeGetterSetter(dominantBaseline)
makeGetterSetter(paintOrder)


proc withTextAlignLeft*(s: Style): Style =
  result = s
  result.textAnchor = some("start")

proc withTextAlignCenter*(s: Style): Style =
  result = s
  result.textAnchor = some("middle")

proc withTextAlignRight*(s: Style): Style =
  result = s
  result.textAnchor = some("end")

proc withPaintOrderStroke*(s: Style): Style =
  result = s
  result.paintOrder = some("stroke")


proc getAttributes*(s: Style): seq[(string, string)] =
  var attrs = newSeq[(string, string)]()

  for fill in s.fill:
    attrs.add(("fill", fill))
  for stroke in s.stroke:
    attrs.add(("stroke", stroke))
  for strokeWidth in s.strokeWidth:
    attrs.add(("stroke-width", strokeWidth))

  for fontSize in s.fontSize:
    attrs.add(("font-size", fontSize))
  for fontFamily in s.fontFamily:
    attrs.add(("font-family", fontFamily))
  for textAnchor in s.textAnchor:
    attrs.add(("text-anchor", textAnchor))
  for dominantBaseline in s.dominantBaseline:
    attrs.add(("dominant-baseline", dominantBaseline))
  for paintOrder in s.paintOrder:
    attrs.add(("paint-order", paintOrder))

  attrs


proc text*(s: Style, x: float, y: float, text: string): Nodes =
  buildSvg:
    text(
      ... s.getAttributes(),
      x=x,
      y=y,
    ): t(text)

proc defaultStyle*(): Style =
  Style(
    stroke: some("#3333333"),
    fill: some("#555555"),
    strokeWidth: some("1px"),
    fontSize: some("16"),
    fontFamily: some("Ubuntu"),
    textAnchor: some("middle"),
    dominantBaseline: some("middle"),
    paintOrder: some("normal"),
  )