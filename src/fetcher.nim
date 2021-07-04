import httpclient, json, nancy, strutils, argparse

let client = httpclient.newHttpClient()

iterator items(start: int, final: int): int =
  var curr = start

  while curr != final:
    yield curr
    inc curr

type
  Package* = object
    index: string
    name: string
    description: string
    version: string

  Query* = object
    results: seq[Package]
    url: string

proc newPackage(index: string, name: string, description: string, version: string): Package =
  result.index = index
  result.name = name
  result.description = description
  result.version = version

proc getMax(data: JsonNode, largest: int): int =
  if data.len > largest:
    return largest

  return data.len

proc void*(query: string): Query =

  let
    url = "https://xq-api.voidlinux.org/v1/query/x86_64?q=$#" % [query]
    data: JsonNode = parseJson(client.request(url).body)["data"]

  for i in items(0, getMax(data, 10)):
    result.results.add newPackage($(i+1), data[i]["name"].getStr, data[i]["short_desc"].getStr, data[i]["version"].getStr)

proc aur*(query: string): Query =

  let
    url = "https://aur.archlinux.org/rpc?type=search&arg=$#" % [query]
    data: JsonNode = parseJson(client.request(url).body)["results"]

  for i in items(0, getMax(data, 10)):
    result.results.add newPackage($(i+1), data[i]["Name"].getStr, data[i]["Description"].getStr, data[i]["Version"].getStr)

proc createTable*(data: Query) =
  var table: TerminalTable

  table.add "Index", "Package", "Description", "Version"

  for i in data.results:
    table.add i.index, i.name, i.description, i.version

  table.echoTableSeps(seps = boxSeps)
