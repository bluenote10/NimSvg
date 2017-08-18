import macros
import strutils
import sequtils
import future
import os


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
  for n in nodes:
    let pad = spaces(indent)
    result &= pad & "<" & n.tag
    if not n.attributes.isNil and n.attributes.len > 0:
      result &= " "
      result &= $n.attributes.map(attr => attr[0] & "=\"" & attr[1] & "\"").join(" ")
    if not n.children.isNil and n.children.len > 0:
      result &= ">\n"
      result &= render(n.children, indent+2)
      result &= pad & "</" & n.tag & ">"
    else:
      result &= "/>\n"


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
    let tag = newStrLitNode($(n[0]))
    if $(n[0]) == "embed":
      let nodesSeqExpr = n[1]
      result = getAst(embedSeq(nodesSeqExpr))
    elif $(n[0]) == "!":
      result = n[1]
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
  if level == 0:
    echo result.repr


macro buildSvg*(body: untyped): Nodes =
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


template buildSvgFile*(filename: string, body: untyped): untyped =
  let nodes = buildSvg(body)
  withFile(f, filename):
    f.write(nodes.render())


proc buildAnimation*(filenameBase: string, numFrames: int, builder: int -> Nodes) =
  for i in 0 ..< numFrames:
    let filename = filenameBase & "_frame_" & align($i, 4, '0') & ".svg"
    let nodes = builder(i)
    withFile(f, filename):
      f.write(nodes.render())
 
  let pattern = filenameBase & "_frame_*.svg"
  let outFile = filenameBase & ".gif"
  let cmd = "bash -c \"convert -delay 5 -loop 0 -dispose previous $1 -reverse $1 $2\"" % [pattern, outFile]
  echo "Running: ", cmd
  discard execShellCmd(cmd)


when isMainModule:
  import unittest

  proc verify(svg, exp: Nodes) =
    if svg != exp:
      echo "Trees don't match"
      echo " *** Generated:\n", svg
      echo " *** Expected:\n", exp
      check false

  suite "buildSvg":

    test "Nested elements 1":
      let svg = buildSvg:
        g:
          circle
          circle(cx=120, cy=150)
          circle():
            withSubElement()
        g():
          for i in 0 ..< 3:
            circle()
            circle(cx=120, cy=150)
      let exp = @[
        newNode("g", @[
          newNode("circle"),
          newNode("circle", @[("cx", "120"), ("cy", "150")]),
          newNode("circle", @[
            newNode("withSubElement")
          ]),
        ]),
        newNode("g", @[
          newNode("circle"),
          newNode("circle", @[("cx", "120"), ("cy", "150")]),
          newNode("circle"),
          newNode("circle", @[("cx", "120"), ("cy", "150")]),
          newNode("circle"),
          newNode("circle", @[("cx", "120"), ("cy", "150")]),
        ]),
      ]
      verify(svg, exp)

    test "if":
      let svg = buildSvg:
        g():
          if true:
            a()
          else:
            b()
        g():
          if false:
            a()
          else:
            b()
        for i in 0..2:
          if i mod 2 == 0:
            c()
          else:
            d()
      let exp = @[
        newNode("g", @[
          newNode("a"),
        ]),
        newNode("g", @[
          newNode("b"),
        ]),
        newNode("c"),
        newNode("d"),
        newNode("c"),
      ]
      verify(svg, exp)

    test "case":
      let x = 1
      let svg = buildSvg:
        g():
          case x
          of 0:
            a()
          of 1:
            b()
          else:
            c()
      let exp = @[
        newNode("g", @[
          newNode("b"),
        ]),
      ]
      verify(svg, exp)

    test "var/let/const":
      let svg = buildSvg:
        var x = 1
        a(x=x)
        let y = 2
        a(y=y)
        const z = 3
        a(z=z)
      let exp = @[
        newNode("a", @[("x", "1")]),
        newNode("a", @[("y", "2")]),
        newNode("a", @[("z", "3")]),
      ]
      verify(svg, exp)

    test "infix op":
      let svg = buildSvg:
        var x = 1
        x += 1
        a(x=x)
      let exp = @[
        newNode("a", @[("x", "2")]),
      ]
      verify(svg, exp)

    test "embed":
      proc sub(): Nodes = buildSvg:
        a()
        b()
      proc withArg(x: int): Nodes = buildSvg:
        for i in 0 .. x:
          x(x=i)
      let svg = buildSvg:
        x()
        embed sub()
        embed(sub())
        embed sub() & sub()
        embed(sub() & sub())
        embed withArg(2)
        y()
      let exp = @[
        newNode("x"),
        newNode("a"), newNode("b"),
        newNode("a"), newNode("b"),
        newNode("a"), newNode("b"), newNode("a"), newNode("b"),
        newNode("a"), newNode("b"), newNode("a"), newNode("b"),
        newNode("x", @[("x", "0")]), newNode("x", @[("x", "1")]), newNode("x", @[("x", "2")]),
        newNode("y"),
      ]
      verify(svg, exp)
