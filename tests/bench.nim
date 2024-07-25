import ../src/urlMatcher

when isMainModule:
  import benchy
  var mt = newMatchTable()
  timeit "static":
    for idx in 0 .. 10_000:
      # for idx in 0 .. 10:
      assert true == match("/foo/baa", "/foo/@baa:string", mt)
      assert mt["baa"].strVal == "baa"
  timeit "non static":
    var matcher = "/foo/@baa:string"
    for idx in 0 .. 10_000:
      # for idx in 0 .. 10:
      assert true == match("/foo/baa", matcher, mt)
      assert mt["baa"].strVal == "baa"


