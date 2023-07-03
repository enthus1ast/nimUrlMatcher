## A module for matching and capturing url routes.
##
import strutils

import uri, tables
export uri, tables

type 
  MatchTable* = TableRef[string, Elem]
  Tys* = enum
    TyString
    TyFloat
    TyInt
    TyBool
  BElem = tuple[kind: Tys, data: string]
  Elem* = object
   case kind: Tys
   of TyString:
     strVal: string
   of TyFloat:
     floatVal: float
   of TyInt:
     intVal: int
   of TyBool:
     boolVal: bool

proc splitType(str: string): BElem =
  let parts = str.split(":", 1)
  if parts.len == 1:
    return (TyString, parts[0])
  if parts.len == 2:
    case parts[1]
    of "string":
      return (TyString, parts[0])
    of "float":
      return (TyFloat, parts[0])
    of "int":
      return (TyInt, parts[0])
    of "bool":
      return (TyBool, parts[0])

proc match*(path, matcher: string, matchTable: MatchTable, catchPrefix = '@'): bool =
  ## Returns `true` if a route matches, also stores matched variables in 
  ## the `matchTable`.
  ## Valid types to match are:
  ##  - `string` (default, can be omitted)
  ##  - `float`
  ##  - `int`
  ##  - `boolean`
  ##    - y, yes, true, 1, on  => true 
  ##    - n, no, false, 0, off => false
  ##
  ##
  ## Matchers are written like so:
  ##
  ## `"/foo/@name:type"`
  ## 
  ## eg.:
  ## - `"/foo/@uuid"`
  ## - `"/foo/@uuid:string"`
  ## - `"/foo/@id:int"`
  ## - `"/foo/@enabled:bool"`
  ##
  ## .. code-block:: Nim
  ##  var mt = newMatchTable()
  ##
  ##  if match("/api/get/123", "/api/get/@id:int", mt):
  ##    echo mt["id"].intVal # prints 123
  ##
  ##  if match("/api/get/enthus1ast", "/api/get/@name:string", mt):
  ##    echo mt["name"].strVal # prints "enthus1ast"
  ##
  matchTable.clear()
  let pa = path.split("/")
  let ma = matcher.split("/")
  if pa.len != ma.len: return false
  for idx in 0 ..< pa.len:
    let pi = pa[idx]
    let mi = ma[idx]
    if mi.startsWith(catchPrefix):
      let (ty, data) = mi[1..^1].splitType()
      try:
        case ty
        of TyString:
          matchTable[data] = Elem(kind: TyString, strVal: pi)
        of TyFloat:
          matchTable[data] = Elem(kind: TyFloat, floatVal: pi.parseFloat)
        of TyInt:
          matchTable[data] = Elem(kind: TyInt, intVal: pi.parseInt)
        of TyBool:
          matchTable[data] = Elem(kind: TyBool, boolVal: pi.parseBool)
      except:
        return false
    elif pi == mi: continue
    else: return false
  return true

proc newMatchTable*(): MatchTable =
  ## Creates a new table that contains all the matches
  return newTable[string, Elem]()

# when isMainModule:
#   import benchy
#   var mt = newMatchTable()
#   timeit "old": 
#     for idx in 0 .. 10_000:
#       assert true == match("/foo/baa", "/foo/@baa:string", mt)
#       assert mt["baa"].strVal == "baa"

