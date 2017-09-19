import macros
import strutils
import sequtils
import future
import os


# -----------------------------------------------------------------------------
# XML Node stuff
# -----------------------------------------------------------------------------

type
  Attributes = seq[(string, string)]

  Node* = ref object
    tag: string
    children: Nodes
    attributes: Attributes

  Nodes* = seq[Node]


proc newNode*(tag: string): Node =
  Node(tag: tag, children: newSeq[Node]())


proc newNode*(tag: string, children: Nodes): Node =
  Node(tag: tag, children: children)


proc newNode*(tag: string, attributes: Attributes): Node =
  Node(tag: tag, children: newSeq[Node](), attributes: attributes)


proc prettyString*(n: Node, indent: int): string =
  let pad = spaces(indent)
  result = pad & n.tag & "("
  if not n.attributes.isNil:
    result &= $n.attributes.map(attr => attr[0] & "=" & attr[1]).join(", ")
  result &= ")\n"
  for child in n.children:
    result &= prettyString(child, indent+2)


proc render*(nodes: Nodes, indent: int = 0): string =
  result = newStringOfCap(1024)
  if indent == 0:
    result &= """<?xml version="1.0" encoding="UTF-8" ?>"""
    result &= "\n"
    result &= """<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">"""
    result &= "\n"
  for n in nodes:
    let pad = spaces(indent)
    if n.tag != "#text":
      result &= pad & "<" & n.tag
      if not n.attributes.isNil and n.attributes.len > 0:
        result &= " "
        result &= $n.attributes.map(attr => attr[0] & "=\"" & attr[1] & "\"").join(" ")
      if not n.children.isNil and n.children.len > 0:
        result &= ">\n"
        result &= render(n.children, indent+2)
        result &= pad & "</" & n.tag & ">\n"
      else:
        result &= "/>\n"
    else:
      result &= pad & n.attributes[0][1] & "\n"


proc `$`*(n: Node): string =
  n.prettyString(0)


proc `$`*(nodes: Nodes): string =
  result = ""
  for n in nodes:
    result &= n.prettyString(0)


proc `[]`*(n: Node, i: int): Node = n.children[i]


proc `==`*(a, b: Node): bool =
  if a.tag != b.tag:
    return false
  elif a.children.len != b.children.len:
    return false
  elif a.attributes.len != b.attributes.len:
    return false
  else:
    var same = true
    for i in 0 ..< a.children.len:
      same = same and a[i] == b[i]
    for i in 0 ..< a.attributes.len:
      same = same and a.attributes[i][0] == b.attributes[i][0]
      same = same and a.attributes[i][1] == b.attributes[i][1]
    return same


# -----------------------------------------------------------------------------
# Internal macros
# -----------------------------------------------------------------------------

proc getName(n: NimNode): string =
  case n.kind
  of nnkIdent:
    result = $n.ident
  of nnkAccQuoted:
    result = ""
    for i in 0..<n.len:
      result.add getName(n[i])
  of nnkStrLit..nnkTripleStrLit:
    result = n.strVal
  else:
    #echo repr n
    expectKind(n, nnkIdent)


proc extractAttributes(n: NimNode): NimNode =
  ## Extracts named parameters from a callkind node and
  ## converts it to a seq[(str, str)] ast.
  result = newCall("@", newNimNode(nnkBracket))
  for i in 1 ..< n.len:
    let x = n[i]
    if x.kind == nnkExprEqExpr:
      let key = x[0].getName
      let value = newCall("$", x[1])
      let tupleExpr = newPar(newStrLitNode(key), value)
      result[1].add(tupleExpr)


proc dummyTextAttributes(text: NimNode): NimNode =
  result = newCall("@", newNimNode(nnkBracket))
  let key = newStrLitNode("text")
  let value = text
  let tupleExpr = newPar(key, value)
  result[1].add(tupleExpr)


proc buildNodesBlock(body: NimNode, level: int): NimNode


proc buildNodes(body: NimNode, level: int): NimNode =

  template appendElement(tmp, tag, attrs, childrenBlock) {.dirty.} =
    bind newNode
    let tmp = newNode(tag)
    nodes.add(tmp)
    tmp.attributes = attrs
    tmp.children = childrenBlock

  template embedSeq(nodesSeqExpr) {.dirty.} =
    for node in nodesSeqExpr:
      nodes.add(node)

  let n = copyNimTree(body)
  # echo level, " ", n.kind
  # echo n.treeRepr

  const nnkCallKindsNoInfix = {nnkCall, nnkPrefix, nnkPostfix, nnkCommand, nnkCallStrLit}

  case n.kind
  of nnkCallKindsNoInfix:
    let tmp = genSym(nskLet, "tmp")
    let tagStr = $(n[0])
    let tag = newStrLitNode(tagStr)
    if tagStr == "embed":
      let nodesSeqExpr = n[1]
      result = getAst(embedSeq(nodesSeqExpr))
    elif tagStr == "call":
      result = n[1]
    elif tagStr == "t":
      let tmp = genSym(nskLet, "tmp")
      let tag = newStrLitNode("#text")
      let childrenBlock = newEmptyNode()
      let attributes = dummyTextAttributes(n[1])
      result = getAst(appendElement(tmp, tag, attributes, childrenBlock))
    else:
      # if the last element is an nnkStmtList (block argument)
      # => full recursion to build block statement for children
      let childrenBlock =
        if n.len >= 2 and n[^1].kind == nnkStmtList:
          buildNodesBlock(n[^1], level+1)
        else:
          newNimNode(nnkEmpty)
      let attributes = extractAttributes(n)
      # echo attributes.repr
      # TODO: handle nil cases explicitly by constructing empty seqs to avoid nil issues
      result = getAst(appendElement(tmp, tag, attributes, childrenBlock))
  of nnkIdent:
    # Currently a single ident is treated as an empty tag. Not sure if
    # there more important use cases. Maybe `embed` them?
    let tmp = genSym(nskLet, "tmp")
    let tag = newStrLitNode($n)
    let childrenBlock = newEmptyNode()
    let attributes = newEmptyNode()
    result = getAst(appendElement(tmp, tag, attributes, childrenBlock))

  of nnkForStmt, nnkIfExpr, nnkElifExpr, nnkElseExpr,
      nnkOfBranch, nnkElifBranch, nnkExceptBranch, nnkElse,
      nnkConstDef, nnkWhileStmt, nnkIdentDefs, nnkVarTuple:
    # recurse for the last son:
    result = copyNimTree(n)
    let L = n.len
    if L > 0:
      result[L-1] = buildNodes(result[L-1], level+1)

  of nnkStmtList, nnkStmtListExpr, nnkWhenStmt, nnkIfStmt, nnkTryStmt,
      nnkFinally:
    # recurse for every child:
    result = copyNimNode(n)
    for x in n:
      result.add buildNodes(x, level+1)

  of nnkCaseStmt:
    # recurse for children, but don't add call for case ident
    result = copyNimNode(n)
    result.add n[0]
    for i in 1 ..< n.len:
      result.add buildNodes(n[i], level+1)

  of nnkVarSection, nnkLetSection, nnkConstSection:
    result = n
  of nnkInfix:
    result = n

  else:
    error "Unhandled node kind: " & $n.kind & "\n" & n.repr

  #result = elements


proc buildNodesBlock(body: NimNode, level: int): NimNode =
  ## This proc finializes the node building by wrapping everything
  ## in a block which provides and returns the `nodes` variable.
  template resultTemplate(elementBuilder) {.dirty.} =
    block:
      var nodes = newSeq[Node]()
      elementBuilder
      nodes

  let elements = buildNodes(body, level)
  result = getAst(resultTemplate(elements))
  when defined(debugDsl):
    if level == 0:
      echo result.repr

# -----------------------------------------------------------------------------
# SVG Builder
# -----------------------------------------------------------------------------

macro buildSvg*(body: untyped): Nodes =
  when defined(debugDsl):
    echo " --------- body ----------- "
    echo body.treeRepr
    echo " --------- body ----------- "

  let kids = newProc(procType=nnkDo, body=body)
  expectKind kids, nnkDo
  result = buildNodesBlock(body(kids), 0)


template withFile(f, fn, body: untyped): untyped =
  var f: File
  if open(f, fn, fmWrite):
    try:
      body
    finally:
      close(f)
  else:
    quit("cannot open: " & fn)


proc ensureParentDirExists(filename: string) =
  let parent = parentDir(filename)
  if parent != "":
    createDir(parent)


template buildSvgFile*(filename: string, body: untyped): untyped =
  ensureParentDirExists(filename)
  let nodes = buildSvg(body)
  withFile(f, filename):
    f.write(nodes.render())


# -----------------------------------------------------------------------------
# Animations Builder
# -----------------------------------------------------------------------------

type
  AnimSettings = object
    backAndForth: bool


proc animSettings*(): AnimSettings =
  AnimSettings(
    backAndForth: false
  )


proc backAndForth*(animSettings: AnimSettings, backAndForth: bool): AnimSettings =
  result = animSettings
  result.backAndForth = backAndForth


proc buildAnimation*(filenameBase: string, numFrames: int, animSettings: AnimSettings = animSettings(), builder: int -> Nodes) =
  createDir(filenameBase & "_frames")

  proc svgFileName(suffix: string): string =
    let filenameOnly = filenameBase.splitFile().name
    result = filenameBase & "_frames" / filenameOnly & "_frame_" & suffix & ".svg"

  for i in 0 ..< numFrames:
    let filename = svgFileName(align($i, 4, '0'))
    let nodes = builder(i)
    withFile(f, filename):
      f.write(nodes.render())

  let pattern = svgFileName("*")
  let outFile = filenameBase & ".gif"

  var cmdElems = @[
    "convert",
    "-delay", "5",
    "-loop", "0",
    "-dispose", "previous",
    pattern
  ]
  if animSettings.backAndForth:
    cmdElems &= @[
      "-reverse",
      pattern
    ]
  cmdElems &= outfile

  let cmd = cmdElems.join(" ")

  echo "Running: ", cmd
  discard execShellCmd(cmd)


# -----------------------------------------------------------------------------
# Misc utils
# -----------------------------------------------------------------------------

template sourceBaseName*(): string =
  instantiationInfo().filename.splitFile().name


