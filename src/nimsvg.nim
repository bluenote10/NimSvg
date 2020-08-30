import macros
import strutils
import strformat
import sequtils
import sugar
import os

import nimsvg/utils
import nimsvg/html_writer

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


proc prettyString(n: Node, indent: int): string =
  let pad = spaces(indent)
  result = pad & n.tag & "("
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

      var attributes = n.attributes
      if n.tag == "svg":
        var hasXmlns = false
        var hasVersion = false
        for attr in attributes:
          if attr[0] == "xmlns":
            hasXmlns = true
          if attr[0] == "version":
            hasVersion = true
        if not hasXmlns:
          attributes.add(("xmlns", "http://www.w3.org/2000/svg"))
        if not hasVersion:
          attributes.add(("version", "1.1"))

      if attributes.len > 0:
        # TODO: Since attributes are just seqs of (string, string) tuples, it is possible
        # to have the same attribute twice, which is not valid XML. We should filter them
        # to unique attributes. In case of duplicates we should use "later overwrites earlier"
        # semantics, because the "... attributes" syntax prepends other manually specified
        # attributes that should have precedence.
        result &= " "
        result &= $attributes.map(attr => attr[0] & "=\"" & attr[1] & "\"").join(" ")

      if n.children.len > 0:
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


proc `[]`(n: Node, i: int): Node = n.children[i]


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
    result = n.strVal
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
  var baseAttributes: NimNode = nil
  var seqAst = newCall("@", newNimNode(nnkBracket))
  var seqAstLen = 0

  for i in 1 ..< n.len:
    let x = n[i]
    if x.kind == nnkExprEqExpr:
      let key = x[0].getName
      let value = newCall("$", x[1])
      let tupleExpr = newPar(newStrLitNode(key), value)
      seqAst[1].add(tupleExpr)
      seqAstLen += 1
    elif x.kind == nnkPrefix and x[0].strVal == "...":
      if i != 1:
        error("... expression is only allowed as first child", x)
      baseAttributes = x[1]
    elif x.kind == nnkStmtList:
      # Allow for "function bodies"
      continue
    else:
      error(&"Expected an 'attribute=value' expression, got node kind {x.kind} in '{x.repr()}'", x)

  if baseAttributes.isNil:
    result = seqAst
  elif seqAstLen == 0:
    # concat does not make sense if seqAst is empty
    result = baseAttributes
  else:
    result = newCall(bindSym"concat", baseAttributes, seqAst)

proc dummyTextAttributes(text: NimNode): NimNode =
  result = newCall("@", newNimNode(nnkBracket))
  let key = newStrLitNode("text")
  let value = text
  let tupleExpr = newPar(key, value)
  result[1].add(tupleExpr)


proc buildNodesBlock(body: NimNode, level: int): NimNode


proc buildNodes(body: NimNode, level: int): NimNode =

  # TODO we could probably simplify these three templates into one?
  template appendElement(tmp, tag, attrs, childrenBlock) {.dirty.} =
    bind newNode
    let tmp = newNode(tag)
    nodes.add(tmp)
    tmp.attributes = attrs
    tmp.children = childrenBlock

  template appendElementNoChilren(tmp, tag, attrs) {.dirty.} =
    bind newNode
    let tmp = newNode(tag)
    nodes.add(tmp)
    tmp.attributes = attrs

  template appendElementNoChilrenNoAttrs(tmp, tag) {.dirty.} =
    bind newNode
    let tmp = newNode(tag)
    nodes.add(tmp)

  template embedSeq(nodesSeqExpr) {.dirty.} =
    for node in nodesSeqExpr:
      nodes.add(node)

  let n = copyNimTree(body)
  # echo level, " ", n.kind
  # echo n.treeRepr

  const nnkCallKindsNoInfix = {nnkCall, nnkPrefix, nnkPostfix, nnkCommand, nnkCallStrLit}

  case n.kind
  of nnkCallKindsNoInfix:
    let tagStr = $(n[0])
    if tagStr == "embed":
      let nodesSeqExpr = n[1]
      result = getAst(embedSeq(nodesSeqExpr))
    elif tagStr == "call":
      result = n[1]
    elif tagStr == "t":
      let tmp = genSym(nskLet, "tmp")
      let tag = newStrLitNode("#text")
      let attributes = dummyTextAttributes(n[1])
      result = getAst(appendElementNoChilren(tmp, tag, attributes))
    else:
      let tmp = genSym(nskLet, "tmp")
      let tag = newStrLitNode(tagStr)
      # if the last element is an nnkStmtList (block argument)
      # => full recursion to build block statement for children
      let attributes = extractAttributes(n)
      # echo attributes.repr
      if n.len >= 2 and n[^1].kind == nnkStmtList:
        let childrenBlock = buildNodesBlock(n[^1], level+1)
        result = getAst(appendElement(tmp, tag, attributes, childrenBlock))
      else:
        result = getAst(appendElementNoChilren(tmp, tag, attributes))

  of nnkIdent:
    # Currently a single ident is treated as an empty tag. Not sure if
    # there more important use cases. Maybe `embed` them?
    let tmp = genSym(nskLet, "tmp")
    let tag = newStrLitNode($n)
    result = getAst(appendElementNoChilrenNoAttrs(tmp, tag))

  of nnkForStmt, nnkIfExpr, nnkElifExpr, nnkElseExpr,
      nnkOfBranch, nnkElifBranch, nnkExceptBranch, nnkElse,
      nnkConstDef, nnkWhileStmt, nnkIdentDefs, nnkVarTuple, nnkBlockStmt:
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
      echo " --------- output ----------- "
      echo result.repr

# -----------------------------------------------------------------------------
# SVG Builder
# -----------------------------------------------------------------------------

macro buildSvg*(body: untyped): Nodes =
  when defined(debugDsl):
    echo " --------- input ----------- "
    echo body.treeRepr

  let kids = newProc(procType=nnkDo, body=body)
  expectKind kids, nnkDo
  result = buildNodesBlock(body(kids), 0)


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
  AnimSettings* = object
    filenameBase*: string
    renderGif*: bool
    gifFrameTime*: int
    backAndForth*: bool


proc animSettings*(
  filenameBase: string,
  renderGif: bool = false,
  gifFrameTime: int = 5,
  backAndForth: bool = false,
): AnimSettings =
  AnimSettings(
    filenameBase: filenameBase,
    renderGif: renderGif,
    gifFrameTime: gifFrameTime,
    backAndForth: backAndForth,
  )

proc buildAnimation*(settings: AnimSettings, numFrames: int, builder: int -> Nodes) =
  let filenameBase = settings.filenameBase

  createDir(filenameBase & "_frames")
  let filenameOnly = filenameBase.splitFile().name

  proc svgFrameFileName(suffix: string): string =
    filenameBase & "_frames" / filenameOnly & "_frame_" & suffix & ".svg"

  var htmlWriter = HtmlWriter()

  for i in 0 ..< numFrames:
    let filename = svgFrameFileName(align($i, 4, '0'))
    let nodes = builder(i)
    let svgCode = nodes.render()
    withFile(f, filename):
      f.write(svgCode)
    htmlWriter.addFrame(svgCode)

  htmlWriter.writeHtml(filenameBase & ".html")

  if settings.renderGif:
    let pattern = svgFrameFileName("*")
    let outFile = filenameBase & ".gif"

    var cmdElems = @[
      "convert",
      "-delay", $settings.gifFrameTime,
      "-loop", "0",
      "-dispose", "previous",
      pattern
    ]
    if settings.backAndForth:
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
  bind splitFile
  instantiationInfo().filename.splitFile().name

template sourceToSvgPath*(prefix: string = ""): string =
  bind splitFile
  if prefix.len == 0:
    (instantiationInfo().filename.splitFile().name & ".svg")
  else:
    prefix / (instantiationInfo().filename.splitFile().name & ".svg")

proc loadSVG*(filename: string): Nodes =
  ## Helper function that allows to embed existing SVG files.
  let content = readFile(filename)
  let offsetSvgTag = content.find("<svg")
  let contentStripped = content[offsetSvgTag..^1]
  buildSvg:
    t contentStripped

