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


proc buildSvgProc(body: NimNode, level: int): NimNode =

  template appendElement(tmp, tag, childrenArg) {.dirty.} =
    let tmp = newNode(tag)
    nodes.add(tmp)
    tmp.children = childrenArg

  # `elements` will be a stmt list of `appendElement` ASTs
  var elements = newNimNode(nnkStmtList)

  for n in body:
    echo n.treeRepr
    case n.kind
    of nnkCallKinds:
      let tag = newStrLitNode($(n[0]))
      let tmp = genSym(nskLet, "tmp")
      # if the last element is an nnkStmtList (block argument) => recursion for children.
      let children =
        if n.len >= 2 and n[^1].kind == nnkStmtList:
          buildSvgProc(n[^1], level+1)
        else:
          newNimNode(nnkEmpty)
      elements.add(getAst(appendElement(tmp, tag, children)))
    of nnkIdent:
      let tag = newStrLitNode($n)
      let tmp = genSym(nskLet, "tmp")
      elements.add(getAst(appendElement(tmp, tag, newEmptyNode())))

    of nnkForStmt, nnkIfExpr, nnkElifExpr, nnkElseExpr,
        nnkOfBranch, nnkElifBranch, nnkExceptBranch, nnkElse,
        nnkConstDef, nnkWhileStmt, nnkIdentDefs, nnkVarTuple:
      # recurse for the last son:
      let subtree = copyNimTree(n)
      let L = n.len
      if L > 0:
        subtree[L-1] = buildSvgProc(subtree[L-1], level+1)
      elements.add(subtree)
    #[
    of nnkStmtList, nnkStmtListExpr, nnkWhenStmt, nnkIfStmt, nnkTryStmt,
      nnkFinally:
      # recurse for every child:
      result = copyNimNode(n)
      for x in n:
        result.add tcall2(x, tmpContext)
    of nnkCaseStmt:
      # recurse for children, but don't add call for case ident
      result = copyNimNode(n)
      result.add n[0]
      for i in 1 ..< n.len:
        result.add tcall2(n[i], tmpContext)
    ]#
    else:
      error "Unknown node kind: " & $n.kind & "\n" & n.repr

  # Final output template wraps everything in a block and provides the `nodes` variable.
  template resultTemplate(elementBuilder) {.dirty.} =
    block:
      var nodes = newSeq[Node]()
      elementBuilder
      nodes

  result = getAst(resultTemplate(elements))
  if level == 0:
    echo result.repr


macro buildSvg(body: untyped): seq[Node] =
  echo " --------- body ----------- "
  echo body.treeRepr
  echo " --------- body ----------- "

  let kids = newProc(procType=nnkDo, body=body)
  expectKind kids, nnkDo
  result = buildSvgProc(body(kids), 0)


let svg = buildSvg:
  g:
    circle
    circle(cx=120, cy=150)
    circle(cx=120, cy=150):
      withSubElement()
  g():
    for i in 0 .. 3:
      circle()
      circle(cx=120, cy=150)

echo svg


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

when false:
  static:
    dumpTree:
      block:
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