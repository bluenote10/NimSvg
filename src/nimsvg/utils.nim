
template withFile*(f, fn, body: untyped): untyped =
  var f: File
  if open(f, fn, fmWrite):
    try:
      body
    finally:
      close(f)
  else:
    quit("cannot open: " & fn)
