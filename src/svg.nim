import macros
import strutils


type
  Node = ref object
    tag: string
    children: Nodes

  Nodes = seq[Node]

proc newNode(tag: string): Node =
  Node(tag: tag, children: newSeq[Node]())

proc prettyString(n: Node, indent: int): string =
  let pad = spaces(indent)
  result = pad & n.tag & "\n"
  for child in n.children:
    result &= prettyString(child, indent+2)

proc `$`(n: Node): string =
  n.prettyString(0)

proc `$`(nodes: Nodes): string =
  result = ""
  for n in nodes:
    result &= n.prettyString(0)


proc buildSvgProc(body: NimNode): NimNode =

  template buildElement(tmp, tag, sub) {.dirty.} =
    let tmp = newNode(tag)
    nodes.add(tmp)
    tmp.children = sub

  template resultTemplate(elementBuilder) =
    block:
      var nodes = newSeq[Node]()
      elementBuilder
      nodes

  var stmts = newNimNode(nnkStmtList)
  echo stmts.treeRepr

  for n in body:
    echo n.treeRepr
    case n.kind
    of nnkCallKinds:
      let tag = newStrLitNode($(n[0]))
      let tmp = genSym(nskLet, "tmp")
      let sub =
        if n.len >= 2:
          buildSvgProc(n[1])
        else:
          newNimNode(nnkEmpty)
      #echo tmp.treeRepr
      #echo tmp.name
      #echo tmp
      stmts.add(getAst(buildElement(tmp, tag, sub)))
      #stmts.add(newLetStmt(tmp, newCall(bindsym"newNode", tag)))
      #stmts.add(newCall("add", ))
    else:
      discard

  echo stmts.treeRepr
  echo stmts.repr
  result = stmts


macro buildSvg(body: untyped): seq[Node] =
  echo body.treeRepr

  let kids = newProc(procType=nnkDo, body=body)
  expectKind kids, nnkDo
  result = buildSvgProc(body(kids))

  result = quote do:
    @[newNode("a")]


let svg = buildSvg:
  g:
    circle
    circle(cx=120, cy=150)
  g():
    #for i in 0 .. 3:
    circle()
    circle(cx=120, cy=150)


let svg2 = (block:
  let tmp = newNode("g")
  when declared(curNode):
    curNode.children.add(tmp)
  else:
    var curNode = newNode("svg")
  curNode.children.add(tmp)
  block:
    var curNode = tmp
    let tmp1 = newNode("circle")
    curNode.children.add(tmp1)
    block:
      var curNode = tmp1
      discard
    for i in 0 .. 3:
      let tmp2 = newNode("circle")
      curNode.children.add(tmp2)
      block:
        var curNode = tmp2
        discard
  curNode
)

echo svg2

let svg3 = (block:
  var nodes = newSeq[Node]()

  let tmp = newNode("g")
  nodes.add(tmp)
  tmp.children = (block:
    var nodes = newSeq[Node]()
    let tmp1 = newNode("circle")
    nodes.add(tmp1)
    let tmp2 = newNode("circle")
    nodes.add(tmp1)
    nodes
  )

  nodes
)

echo svg3