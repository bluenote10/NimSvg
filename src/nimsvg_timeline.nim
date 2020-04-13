import nimsvg
import strformat

import sugar
import lenientops
import strutils
import math
import tables


type
  Frame = object
    t1: float
    t2: float

  Timeline* = object
    i: int
    t: float
    gifFrameTime: int
    frames: TableRef[string, Frame]

  ValueKind* {.pure.} = enum
    String,
    Float,

  Value* = object
    case kind: ValueKind
    of String:
      s: string
    of Float:
      f: float

  KeyPoint* = (string, Value)



proc v*(s: string): Value =
  Value(kind: ValueKind.String, s: s)

proc v*(f: float): Value =
  Value(kind: ValueKind.Float, f: f)

proc val*(v: Value): string =
  case v.kind
  of ValueKind.String:
    v.s
  of ValueKind.Float:
    $v.f


proc newTimeline*(gifFrameTime = 5): Timeline =
  Timeline(
    gifFrameTime: gifFrameTime,
    frames: newTable[string, Frame]()
  )

proc addFrame*(t: var Timeline, name: string, t1: float, t2: float) =
  t.frames[name] = Frame(t1: t1, t2: t2)

proc getMinMaxTime*(t: Timeline): (float, float) =
  var min = +Inf
  var max = -Inf
  for (k, v) in t.frames.pairs():
    if v.t1 < min:
      min = v.t1
    if v.t2 > max:
      max = v.t2
  (min, max)

proc getDuration*(t: Timeline): float =
  let (min, max) = t.getMinMaxTime()
  max - min

proc getTimeOfFrame*(t: Timeline, i: int): float =
  let (min, _) = t.getMinMaxTime()
  min + (i * 0.01 * t.gifFrameTime)


type
  Callback* = openArray[KeyPoint] -> string

  FrameInfo* = object
    i*: int
    t*: float

  EaseKind {.pure.} = enum
    None,
    Linear,
    InOutCubic

  Ease = object
    case kind: EaseKind
    of None, Linear, InOutCubic:
      discard

  TimeExpression = object
    t: float
    ease: Ease

proc computeEase(ease: Ease, x: float): float =
  # https://gist.github.com/gre/1650294#file-easing-js-L13
  case ease.kind
  of None, Linear:
    x
  of EaseKind.InOutCubic:
    if x < 0.5: 4*x*x*x else: (x-1)*(2*x-2)*(2*x-2)+1


proc parseTimeExpression(t: Timeline, texpr: string): TimeExpression =
  let fields = texpr.split()
  let frameName = fields[0]
  let isStart = if fields[1] == "s": true else: false

  let frame = t.frames[frameName] # TODO robustify lookup

  let t =
    if isStart:
      frame.t1
    else:
      frame.t2

  let ease =
    if fields.len == 2:
      Ease(kind: None)
    else:
      if fields[2] == "linear":
        Ease(kind: Linear)
      else:
        Ease(kind: InOutCubic)
  TimeExpression(t: t, ease: ease)


proc splitTimeExprsAndValues(t: Timeline, keypoints: openArray[KeyPoint]): (seq[TimeExpression], seq[Value]) =
  var timeExprs = newSeqOfCap[TimeExpression](keypoints.len)
  var values = newSeqOfCap[Value](keypoints.len)
  for keypoint in keypoints:
    let (texpr, value) = keypoint
    let timeExpr = t.parseTimeExpression(texpr)
    timeExprs.add(timeExpr)
    values.add(value)
  (timeExprs, values)


proc createCallback(tl: Timeline, t: float): Callback =

  proc callback(keypoints: openArray[KeyPoint]): string =
    let (times, values) = tl.splitTimeExprsAndValues(keypoints)

    # May be replaced by binary search, but unlikely to hit performance issues here.
    var j = 0
    while j < times.len and t >= times[j].t:
      j += 1

    let jCurr = if j > 0: j - 1 else: 0
    let jNext = if j < times.len: j else: times.len - 1

    echo "times: ", times, " j = ", j, " jCurr = ", jCurr, " jNext = ", jNext

    if jCurr != jNext and times[jNext].ease.kind != EaseKind.None:
      let ease = times[jNext].ease
      let t1 = times[jCurr].t
      let t2 = times[jNext].t
      let relative = (t - t1) / (t2 - t1)
      let v1 = values[jCurr]
      let v2 = values[jNext]
      if v1.kind == ValueKind.Float and v2.kind == ValueKind.Float:
        let v = v1.f + (v2.f - v1.f) * ease.computeEase(relative)
        echo &"relative = {relative}    v = {v}"
        return $v
      else:
        values[jCurr].val
    else:
      return values[jCurr].val

  return callback


proc buildAnimation*(tl: Timeline, filenameBase: string, builder: (cb: Callback, fi: FrameInfo) -> Nodes) =
  let numFrames = (tl.getDuration() / (0.01 * tl.gifFrameTime)).ceil().int + 1
  echo "Num required frames: ", numFrames
  echo "Timeline min: ": tl.getMinMaxTime()[0]
  echo "Timeline max: ": tl.getMinMaxTime()[1]
  echo "Duration: ": tl.getDuration()

  let settings = animSettings(numFrames, gifFrameTime=tl.gifFrameTime)

  buildAnimation(filenameBase, settings) do (i: int) -> Nodes:
    let t = tl.getTimeOfFrame(i)
    let frameInfo = FrameInfo(i: i, t: t)
    echo "\n", frameInfo

    let callback = tl.createCallback(t)

    return builder(callback, frameInfo)
