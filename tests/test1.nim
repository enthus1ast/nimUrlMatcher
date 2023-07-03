import unittest
include urlMatcher

when isMainModule:
  suite "urlMatcher":
    setup:
      var mt = newMatchTable()

    test "Test for basic type splitting":
      check splitType("STR") == (TyString, "STR")
      check splitType("STR:string") == (TyString, "STR")
      check splitType("INT:int") == (TyInt, "INT")
      check splitType("FLOAT:float") == (TyFloat, "FLOAT")
      check splitType("BOOL:bool") == (TyBool, "BOOL")

    test "string":
      # String is the basic type, that matches everything,
      # so ":string" can be omitted entirely!
      check true == match("/foo/baa", "/foo/@baa", mt)
      check mt["baa"].strVal == "baa"

      check true == match("/foo/baa", "/foo/@baa:string", mt)
      check mt["baa"].strVal == "baa"

    test "int":
      # Int can match negative numbers as well
      check true == match("/foo/1337", "/foo/@id:int", mt)
      check mt["id"].intVal == 1337

      check true == match("/foo/-1337", "/foo/@id:int", mt)
      check mt["id"].intVal == -1337

    # TODO do a positive only int!

    test "float":
      # Float can also match int
      check true == match("/foo/13.37", "/foo/@id:float", mt)
      check mt["id"].floatVal == 13.37

      check true == match("/foo/1337", "/foo/@id:float", mt)
      check mt["id"].floatVal == 1337.0
    test "bool":
      #
      # Bool matches multiple values 
      check true == match("/foo/true", "/foo/@id:bool", mt)
      check mt["id"].boolVal == true 

      check true == match("/foo/yes", "/foo/@id:bool", mt)
      check mt["id"].boolVal == true 

      check true == match("/foo/on", "/foo/@id:bool", mt)
      check mt["id"].boolVal == true 

    test "Not matching":
      check false == match("/foo/baa", "/foo/@baa:int", mt)
      check false == match("/foo/FOO13.37", "/foo/@id:float", mt)

