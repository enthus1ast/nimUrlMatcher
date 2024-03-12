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

    test "absint":
      # Int can match negative numbers as well
      check true == match("/foo/1337", "/foo/@id:absint", mt)
      check mt["id"].intVal == 1337

      check false == match("/foo/-1337", "/foo/@id:absint", mt)

    test "float":
      # Float can also match int
      check true == match("/foo/13.37", "/foo/@id:float", mt)
      check mt["id"].floatVal == 13.37

      check true == match("/foo/1337", "/foo/@id:float", mt)
      check mt["id"].floatVal == 1337.0

    test "bool":
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

    test "Other catchPrefix":
      check true == match("/foo/true", "/foo/;id:bool", mt, catchPrefix = ';')
      check mt["id"].boolVal == true 

    test "Robustnes: # in url":
      check true == match("/foo/13.37#foo", "/foo/@id:float", mt)
      check mt["id"].floatVal == 13.37

    test "Robustnes: ? in url":
      check true == match("/foo/13.37?foo", "/foo/@id:float", mt)
      check mt["id"].floatVal == 13.37

    test "Robustnes: & in url":
      check true == match("/foo/13.37&foo", "/foo/@id:float", mt)
      check mt["id"].floatVal == 13.37

    test "* star match simple":
      check false == match("/nomatch/baa.png", "/static/*", mt) 
      check true == match("/static/baa.png", "/static/*", mt) 
      check mt["*0"].strVal == "baa.png"

    test "* star match simple 2x":
      check false == match("/nomatch/images/baa.png", "/static/*/*", mt) 
      check true == match("/static/images/baa.png", "/static/*/*", mt) 
      check mt["*0"].strVal == "images"
      check mt["*1"].strVal == "baa.png"

    test "* star match middle":
      check false == match("/nomatch/images/baa.png", "/static/*/baa.png", mt) 
      check true == match("/static/images/baa.png", "/static/*/baa.png", mt) 
      check mt["*0"].strVal == "images"

    test "** star star match 1x":
     check false == match("/nomatch/baa", "/static/**", mt)
     check true == match("/static/baa", "/static/**", mt)
     check mt["**"].strVal == "baa"

    test "** star star match nx":
     check false == match("/nomatch/baa", "/foo/**", mt)
     check true == match("/static/images/foo.png", "/static/**", mt)
     check mt["**"].strVal == "images/foo.png"
