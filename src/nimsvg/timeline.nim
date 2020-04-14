import nimsvg
import strformat

import sugar
import lenientops
import strutils
import math
import tables

type
  Frame = object
    name: string
    t1: float
    t2: float

  Timeline* = object
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

proc frames*(frameTuples: openArray[tuple[name: string, t: float]]): seq[Frame] =
  var frames = newSeq[Frame]()
  for i in 0 ..< frameTuples.len:
    let j = min(i + 1, frameTuples.len - 1)
    let a = frameTuples[i]
    let b = frameTuples[j]
    frames.add(Frame(name: a.name, t1: a.t, t2: b.t))
  echo frames
  frames


proc newTimeline*(frames: openArray[Frame] = [], gifFrameTime = 5): Timeline =
  var framesTable = newTable[string, Frame]()
  for frame in frames:
    framesTable[frame.name] = frame

  Timeline(
    gifFrameTime: gifFrameTime,
    frames: framesTable
  )

proc addFrame*(t: var Timeline, name: string, t1: float, t2: float) =
  t.frames[name] = Frame(name: name, t1: t1, t2: t2)

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

  TimelineFrame* = object
    i*: int
    t*: float
    timeline: Timeline

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
  let isStart =
    if fields.len > 1 and fields[1].startsWith("e"):
      false
    else:
      true

  let frame =
    try:
      t.frames[frameName]
    except KeyError:
      raise newException(KeyError, &"Frame name '{frameName}' does not exist in lookup table")

  let t =
    if isStart:
      frame.t1
    else:
      frame.t2

  let ease =
    if fields[^1] == "linear":
      Ease(kind: Linear)
    elif fields[^1] == "ease":
      Ease(kind: InOutCubic)
    else:
      Ease(kind: None)
  TimeExpression(t: t, ease: ease)


proc splitTimeExprsAndValues[T](t: Timeline, keypoints: openArray[(string, T)]): (seq[TimeExpression], seq[T]) =
  var timeExprs = newSeqOfCap[TimeExpression](keypoints.len)
  var values = newSeqOfCap[T](keypoints.len)
  for keypoint in keypoints:
    let (texpr, value) = keypoint
    let timeExpr = t.parseTimeExpression(texpr)
    timeExprs.add(timeExpr)
    values.add(value)
  (timeExprs, values)


proc interpolate*(a: float, b: float, r: float): float =
  a + (b - a) * r

proc interpolate*[A, B](a: (A, B), b: (A, B), r: float): (A, B) =
  (interpolate(a[0], b[0], r), interpolate(a[1], b[1], r))

proc interpolate*[A, B, C](a: (A, B, C), b: (A, B, C), r: float): (A, B, C) =
  (interpolate(a[0], b[0], r), interpolate(a[1], b[1], r), interpolate(a[2], b[2], r))

proc interpolate*[T: not tuple](a: T, b: T, r: float): T =
  echo &"WARNING: Type {$(T)} cannot be interpolated."
  a

proc calc*[T](tlf: TimelineFrame, keypoints: openArray[(string, T)]): T =
  let t = tlf.t

  let (times, values) = tlf.timeline.splitTimeExprsAndValues(keypoints)

  # May be replaced by binary search, but unlikely to hit performance issues here.
  var j = 0
  while j < times.len and t >= times[j].t:
    j += 1

  let jCurr = if j > 0: j - 1 else: 0
  let jNext = if j < times.len: j else: times.len - 1

  echo $T, " times: ", times, " j = ", j, " jCurr = ", jCurr, " jNext = ", jNext

  if jCurr != jNext and times[jNext].ease.kind != EaseKind.None:
    let ease {.used.} = times[jNext].ease
    let t1 = times[jCurr].t
    let t2 = times[jNext].t
    let relative {.used.} = (t - t1) / (t2 - t1)
    let v1 {.used.} = values[jCurr]
    let v2 {.used.} = values[jNext]
    return interpolate(v1, v2, ease.computeEase(relative))
  else:
    return values[jCurr]


proc buildAnimation*(tl: Timeline, filenameBase: string, builder: (tf: TimelineFrame) -> Nodes) =
  let numFrames = (tl.getDuration() / (0.01 * tl.gifFrameTime)).ceil().int + 1
  echo "Num required frames: ", numFrames
  echo "Timeline min: ": tl.getMinMaxTime()[0]
  echo "Timeline max: ": tl.getMinMaxTime()[1]
  echo "Duration: ": tl.getDuration()

  let settings = animSettings(numFrames, gifFrameTime=tl.gifFrameTime)

  buildAnimation(filenameBase, settings) do (i: int) -> Nodes:
    let t = tl.getTimeOfFrame(i)
    let frame = TimelineFrame(i: i, t: t, timeline: tl)
    echo &"\ni = {frame.i}, t = {frame.t}"

    return builder(frame)
