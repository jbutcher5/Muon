import httpclient, json, nancy, strutils

let client = httpclient.newHttpClient()

iterator items(start: int, final: int): int =
  var curr = start

  while curr != final:
    yield curr
    inc curr

type
  Package = object
    index: string
    name: string
    description: string
    version: string

  Query = object
    results: seq[Package]
    url: string

proc newPackage(index: string, name: string, description: string, version: string): Package =
  result.index = index
  result.name = name
  result.description = description
  result.version = version

proc void(query: string): Query =

  let
    url = "https://xq-api.voidlinux.org/v1/query/x86_64?q=$#" % [query]
    data: JsonNode = parseJson(client.request(url).body)["data"]

  for i in items(0, data.len):
    result.results.add newPackage($(i+1), data[i]["name"].getStr, data[i]["short_desc"].getStr, data[i]["version"].getStr)

proc aur(query: string): Query =

  let
    url = "https://aur.archlinux.org/rpc?type=search&arg=$#" % [query]
    data: JsonNode = parseJson(client.request(url).body)["results"]

  var length: int

  if data.len > 50:
    length = 49

  else:
    length = data.len

  for i in items(0, length):
    result.results.add newPackage($(i+1), data[i]["Name"].getStr, data[i]["Description"].getStr, data[i]["Version"].getStr)


proc main() =
  var
    data: Query = aur("cargo")
    table: TerminalTable

  table.add "Index", "Package", "Description", "Version"

  for i in data.results:
    table.add i.index, i.name, i.description, i.version

  table.echoTableSeps(seps = boxSeps)

main()
