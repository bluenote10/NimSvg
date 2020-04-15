import options

export options

# Why is this still not part of the standard library :(
iterator items*[T](o: Option[T]): T =
  if o.isSome:
    yield o.get
