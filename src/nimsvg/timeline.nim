import nimsvg
import strformat

import sugar
import lenientops
import strutils
import math
import tables
import re

type
  Frame = object
    name: string
    t1: float
    t2: float

  Timeline* = object
    gifFrameTime: int
    frames: TableRef[string, Frame]


proc frames*(frameTuples: openArray[tuple[name: string, t: float]], accumulateTimes = true): seq[Frame] =
  var frames = newSeq[Frame]()
  if not accumulateTimes:
    for i in 0 ..< frameTuples.len:
      let j = min(i + 1, frameTuples.len - 1)
      let a = frameTuples[i]
      let b = frameTuples[j]
      frames.add(Frame(name: a.name, t1: a.t, t2: b.t))
  else:
    var t = 0.0
    for i in 0 ..< frameTuples.len:
      let a = t
      let b = t + frameTuples[i].t
      frames.add(Frame(name: frameTuples[i].name, t1: a, t2: b))
      t += frameTuples[i].t
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
  TimelineFrame* = object
    i*: int
    t*: float
    timeline: Timeline

  EaseKind {.pure.} = enum
    None,
    Linear,
    InOutCubic

  TimeExpression = object
    t: float
    ease: EaseKind

proc computeEase(ease: EaseKind, x: float): float =
  # https://gist.github.com/gre/1650294#file-easing-js-L13
  case ease
  of None, Linear:
    x
  of EaseKind.InOutCubic:
    if x < 0.5: 4*x*x*x else: (x-1)*(2*x-2)*(2*x-2)+1


type
  TimeRefineKind {.pure.} = enum
    None, Sec, Pct, Mid, End, Before, After

  ParsedTimeExpressionComponents = tuple
    frameName: string
    timeRefineKind: TimeRefineKind
    timeRefineValue: float
    easeName: string

let timeExpressionRegex = re"^([^\s\[]*)\s*(?:\[(.*)\])?\s*(\S*)$"
let timeRefineRegex = re"^(mid|end|before|after|([-\.0-9]+)\s*(s|%))$"

proc parseTimeExpressionComponents(texpr: string): ParsedTimeExpressionComponents =

  if texpr =~ timeExpressionRegex:
    # cho matches
    let frameName = matches[0]
    let timeRefineExpr = matches[1]
    let easeName = matches[2]

    var timeRefineKind = TimeRefineKind.None
    var timeRefineValue = 0.0

    if timeRefineExpr != "":
      if timeRefineExpr =~ timeRefineRegex:
        if matches[0] == "mid":
          timeRefineKind = TimeRefineKind.Mid
        elif matches[0] == "end":
          timeRefineKind = TimeRefineKind.End
        elif matches[0] == "before":
          timeRefineKind = TimeRefineKind.Before
        elif matches[0] == "after":
          timeRefineKind = TimeRefineKind.After
        elif matches[1] != "" and matches[2] != "":
          # unit
          if matches[2] == "s":
            timeRefineKind = TimeRefineKind.Sec
          elif matches[2] == "%":
            timeRefineKind = TimeRefineKind.Pct
          else:
            raise newException(ValueError, &"Invalid time refine unit: '{matches[2]}'")
          # value
          timeRefineValue = parseFloat(matches[1])

    return (
      frameName: frameName,
      timeRefineKind: timeRefineKind,
      timeRefineValue: timeRefineValue,
      easeName: easeName,
    )

  else:
    raise newException(ValueError, &"Invalid time expression: '{texpr}'")


proc parseTimeExpression(tl: Timeline, texpr: string): TimeExpression =

  let components = parseTimeExpressionComponents(texpr)
  let frameName = components.frameName

  let frame =
    try:
      tl.frames[frameName]
    except KeyError:
      raise newException(KeyError, &"Frame name '{frameName}' does not exist in lookup table")

  let t =
    case components.timeRefineKind
    of TimeRefineKind.None:
      frame.t1
    of TimeRefineKind.Mid:
      (frame.t1 + frame.t2) / 2.0
    of TimeRefineKind.End:
      frame.t2
    of TimeRefineKind.Pct:
      frame.t1 + (components.timeRefineValue / 100.0) * (frame.t2 - frame.t1)
    of TimeRefineKind.Sec:
      frame.t1 + components.timeRefineValue
    of TimeRefineKind.Before:
      frame.t1 - (tl.gifFrameTime * 0.01) / 2
    of TimeRefineKind.After:
      frame.t1 + (tl.gifFrameTime * 0.01) / 2


  let ease =
    case components.easeName
    of "":
      EaseKind.None
    of "linear":
      EaseKind.Linear
    of "ease":
      EaseKind.InOutCubic
    else:
      raise newException(ValueError, &"Illegal ease value: '{components.easeName}'")

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

  # echo $T, " times: ", times, " j = ", j, " jCurr = ", jCurr, " jNext = ", jNext

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
    # echo &"\ni = {frame.i}, t = {frame.t}"

    return builder(frame)


when defined(unittest):
  import unittest

  suite "timeline":

    test "parseTimeExpressionComponents":

      check parseTimeExpressionComponents("f1.name") == (
        frameName: "f1.name",
        timeRefineKind: TimeRefineKind.None,
        timeRefineValue: 0.0,
        easeName: "",
      )
      check parseTimeExpressionComponents("f1.name ") == (
        frameName: "f1.name",
        timeRefineKind: TimeRefineKind.None,
        timeRefineValue: 0.0,
        easeName: "",
      )
      check parseTimeExpressionComponents("f1.name   someEase") == (
        frameName: "f1.name",
        timeRefineKind: TimeRefineKind.None,
        timeRefineValue: 0.0,
        easeName: "someEase",
      )
      check parseTimeExpressionComponents("f1.name[0.5s]") == (
        frameName: "f1.name",
        timeRefineKind: TimeRefineKind.Sec,
        timeRefineValue: 0.5,
        easeName: "",
      )
      check parseTimeExpressionComponents("f1.name[0.5 s]") == (
        frameName: "f1.name",
        timeRefineKind: TimeRefineKind.Sec,
        timeRefineValue: 0.5,
        easeName: "",
      )
      check parseTimeExpressionComponents("f1.name[0.5%]") == (
        frameName: "f1.name",
        timeRefineKind: TimeRefineKind.Pct,
        timeRefineValue: 0.5,
        easeName: "",
      )
      check parseTimeExpressionComponents("f1.name[0.5 %]") == (
        frameName: "f1.name",
        timeRefineKind: TimeRefineKind.Pct,
        timeRefineValue: 0.5,
        easeName: "",
      )
      check parseTimeExpressionComponents("f1.name[0.5 s]   someEase") == (
        frameName: "f1.name",
        timeRefineKind: TimeRefineKind.Sec,
        timeRefineValue: 0.5,
        easeName: "someEase",
      )

    test "parseTimeExpression":
      let tl = newTimeLine(frames({
        "f1": 5.0,
      }), gifFrameTime=1)

      check tl.parseTimeExpression("f1") == TimeExpression(t: 0.0, ease: EaseKind.None)
      check tl.parseTimeExpression("f1[mid]") == TimeExpression(t: 2.5, ease: EaseKind.None)
      check tl.parseTimeExpression("f1[end]") == TimeExpression(t: 5.0, ease: EaseKind.None)

      check tl.parseTimeExpression("f1[-10%]") == TimeExpression(t: -0.5, ease: EaseKind.None)
      check tl.parseTimeExpression("f1[-10 %]") == TimeExpression(t: -0.5, ease: EaseKind.None)

      check tl.parseTimeExpression("f1[200%]") == TimeExpression(t: 10.0, ease: EaseKind.None)
      check tl.parseTimeExpression("f1[200 %]") == TimeExpression(t: 10.0, ease: EaseKind.None)

      check tl.parseTimeExpression("f1[1s]") == TimeExpression(t: 1.0, ease: EaseKind.None)
      check tl.parseTimeExpression("f1[1 s]") == TimeExpression(t: 1.0, ease: EaseKind.None)

      check tl.parseTimeExpression("f1[before]") == TimeExpression(t: -0.005, ease: EaseKind.None)
      check tl.parseTimeExpression("f1[after]") == TimeExpression(t: 0.005, ease: EaseKind.None)
