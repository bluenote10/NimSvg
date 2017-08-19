import nimsvg
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
