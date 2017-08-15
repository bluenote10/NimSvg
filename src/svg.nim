import macros
import strutils


type
  Node* = ref object
    tag: string
    children: Nodes
    attributes: seq[(string, string)]

  Nodes* = seq[Node]

proc newNode*(tag: string): Node =
  Node(tag: tag, children: newSeq[Node]())

proc newNode*(tag: string, children: Nodes): Node =
  Node(tag: tag, children: children)

proc prettyString*(n: Node, indent: int): string =
  let pad = spaces(indent)
  result = pad & n.tag & "\n"
  for child in n.children:
    result &= prettyString(child, indent+2)

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
  else:
    var same = true
    for i in 0 ..< a.children.len:
      same = same and a[i] == b[i]
    return same


proc buildNodesBlock(body: NimNode, level: int): NimNode


proc buildNodes(body: NimNode, level: int): NimNode =

  template appendElement(tmp, tag, childrenBlock) {.dirty.} =
    bind newNode
    let tmp = newNode(tag)
    nodes.add(tmp)
    tmp.children = childrenBlock

  let n = copyNimTree(body)
  # echo level, " ", n.kind
  # echo n.treeRepr

  case n.kind
  of nnkCallKinds:
    let tag = newStrLitNode($(n[0]))
    let tmp = genSym(nskLet, "tmp")
    # if the last element is an nnkStmtList (block argument) => recursion for children.
    let children =
      if n.len >= 2 and n[^1].kind == nnkStmtList:
        buildNodesBlock(n[^1], level+1)
      else:
        newNimNode(nnkEmpty)
    result = getAst(appendElement(tmp, tag, children))
  of nnkIdent:
    let tag = newStrLitNode($n)
    let tmp = genSym(nskLet, "tmp")
    result = getAst(appendElement(tmp, tag, newEmptyNode()))

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

  else:
    error "Unknown node kind: " & $n.kind & "\n" & n.repr

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


macro buildSvg*(body: untyped): seq[Node] =
  echo " --------- body ----------- "
  echo body.treeRepr
  echo " --------- body ----------- "

  let kids = newProc(procType=nnkDo, body=body)
  expectKind kids, nnkDo
  result = buildNodesBlock(body(kids), 0)



when isMainModule:
  import unittest

  proc verify(svg, exp: Nodes) =
    if svg != exp:
      echo "Trees don't match"
      echo " *** Generated:\n", svg
      echo " *** Expected:\n", exp
    check svg == exp

  suite "buildSvg":

    test "Nested elements 1":
      let svg = buildSvg:
        g:
          circle
          circle(cx=120, cy=150)
          circle(cx=120, cy=150):
            withSubElement()
        g():
          for i in 0 ..< 3:
            circle()
            circle(cx=120, cy=150)
      let exp = @[
        newNode("g", @[
          newNode("circle"),
          newNode("circle"),
          newNode("circle", @[
            newNode("withSubElement")
          ]),
        ]),
        newNode("g", @[
          newNode("circle"),
          newNode("circle"),
          newNode("circle"),
          newNode("circle"),
          newNode("circle"),
          newNode("circle"),
        ]),
      ]
      verify(svg, exp)

    test "If":
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

    test "Case":
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
