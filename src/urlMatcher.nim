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
    TyAbsInt
    TyBool
  BElem = tuple[kind: Tys, data: string]
  Elem* = object
    case kind: Tys
    of TyString:
      strVal*: string
    of TyFloat:
      floatVal*: float
    of TyInt, TyAbsInt:
      intVal*: int
    of TyBool:
      boolVal*: bool

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
    of "absint":
      return (TyAbsInt, parts[0])
    of "bool":
      return (TyBool, parts[0])

proc match*(path, matcher: string or static string, matchTable: MatchTable, catchPrefix = '@'): bool =
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
  ## Wildcard (*):
  ##    - `foo/*/baa/*/baz`
  ##      - every "*" is captured as `TyString`
  ##      - is named `*0`, `*1` etc..
  ##
  ## Wildcard (**):
  ##    - `static/**` 
  ##      - only allowed once (at the end)
  ##      - is captured as a `TyString`
  ##      - used to capture all the "rest"
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
  ## - `"/foo/*/baa"`
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

  # Strip all after (including) #, ?, & 
  var startOfEndChar = path.find({'#', '?', '&'})
  if startOfEndChar == -1:
    startOfEndChar = path.len - 1
  else:
    startOfEndChar -= 1

  let pa = path[0 .. startOfEndChar].split("/")
  when matcher is static string:
    const ma = matcher.split("/")
  else:
    let ma = matcher.split("/")
  if not matcher.contains("**"): # TODO find a better way, we scan the matcher multiple times
    if pa.len != ma.len: return false 
  var staridx = 0 # used for ONE '*' 
  for idx in 0 ..< ma.len:
    let pi = pa[idx]
    let mi = ma[idx]
    if mi == "**":
      ## ** is only allowed once (at the end)
      let rest = pa[idx .. ^1].join("/")
      matchTable["**"] = Elem(kind: TyString, strVal: rest)
      break
    elif mi == "*":
      matchTable["*" & $staridx] = Elem(kind: TyString, strVal: pi)
      staridx.inc
    elif mi.startsWith(catchPrefix):
      let (ty, data) = mi[1..^1].splitType() # TODO this could also be done on compile time if static string
      try:
        case ty
        of TyString:
          matchTable[data] = Elem(kind: TyString, strVal: pi)
        of TyFloat:
          matchTable[data] = Elem(kind: TyFloat, floatVal: pi.parseFloat)
        of TyInt:
          matchTable[data] = Elem(kind: TyInt, intVal: pi.parseInt)
        of TyAbsInt:
          let intVal = pi.parseInt
          if intVal < 0:
            raise newException(ValueError, "TyAbsInt must be positive!")
          matchTable[data] = Elem(kind: TyInt, intVal: intVal)
        of TyBool:
          matchTable[data] = Elem(kind: TyBool, boolVal: pi.parseBool)
      except CatchableError:
        return false
    elif pi == mi: continue
    else: return false
  return true

proc newMatchTable*(): MatchTable =
  ## Creates a new table that contains all the matches
  return newTable[string, Elem]()

