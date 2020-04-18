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
    fillOpacity: Option[string]
    strokeOpacity: Option[string]
    opacity: Option[string]

    fontSize: Option[string]
    fontFamily: Option[string]
    fontWeight: Option[string]
    textAnchor: Option[string]
    dominantBaseline: Option[string]
    paintOrder: Option[string]

    rx: Option[string]

    transform: Option[string]

    customAttrs: seq[(string, string)]


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
makeGetterSetter(fillOpacity)
makeGetterSetter(strokeOpacity)
makeGetterSetter(opacity)

makeGetterSetter(fontSize)
makeGetterSetter(fontFamily)
makeGetterSetter(fontWeight)
makeGetterSetter(textAnchor)
makeGetterSetter(dominantBaseline)
makeGetterSetter(paintOrder)

makeGetterSetter(rx)

makeGetterSetter(transform)


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

proc customAttr*(s: Style, attr: string, value: string): Style =
  ## To allow for setting attributes that are not yet covered by the explici API.
  result = s
  result.customAttrs.add((attr, value))


proc getAttributes*(s: Style): seq[(string, string)] =
  var attrs = s.customAttrs

  for fill in s.fill:
    attrs.add(("fill", fill))
  for stroke in s.stroke:
    attrs.add(("stroke", stroke))
  for strokeWidth in s.strokeWidth:
    attrs.add(("stroke-width", strokeWidth))
  for fillOpacity in s.fillOpacity:
    attrs.add(("fill-opacity", fillOpacity))
  for strokeOpacity in s.strokeOpacity:
    attrs.add(("stroke-opacity", strokeOpacity))
  for opacity in s.opacity:
    attrs.add(("opacity", opacity))

  for fontSize in s.fontSize:
    attrs.add(("font-size", fontSize))
  for fontFamily in s.fontFamily:
    attrs.add(("font-family", fontFamily))
  for fontWeight in s.fontWeight:
    attrs.add(("font-weight", fontWeight))
  for textAnchor in s.textAnchor:
    attrs.add(("text-anchor", textAnchor))
  for dominantBaseline in s.dominantBaseline:
    attrs.add(("dominant-baseline", dominantBaseline))
  for paintOrder in s.paintOrder:
    attrs.add(("paint-order", paintOrder))

  for rx in s.rx:
    attrs.add(("rx", rx))

  for transform in s.transform:
    attrs.add(("transform", transform))

  attrs


proc text*(s: Style, x: float, y: float, text: string): Nodes =
  buildSvg:
    text(
      ... s.getAttributes(),
      x=x,
      y=y,
    ): t(text)

proc rectCentered*(s: Style, x: float, y: float, w: float, h: float): Nodes =
  buildSvg:
    rect(... s.getAttributes(), x=x-(w/2), y=y-(h/2), width=w, height=w)

proc circle*(s: Style, x: float, y: float, r: float): Nodes =
  buildSvg:
    circle(... s.getAttributes(), cx=x, cy=y, r=r)


proc defaultStyle*(): Style =
  Style(
    stroke: some("#3333333"),
    fill: some("#555555"),
    strokeWidth: some("1"),
    fontSize: some("16"),
    fontFamily: some("Ubuntu"),
    textAnchor: some("middle"),
    dominantBaseline: some("middle"),
    paintOrder: some("normal"),
  )