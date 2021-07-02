import httpclient, json, nancy

let client = httpclient.newHttpClient()

iterator items(start: int, final: int): int =
  var curr = start

  while curr != final:
    yield curr
    inc curr

proc void(qwery: string): JsonNode =
  return parseJson(client.request("https://xq-api.voidlinux.org/v1/query/x86_64?q=gcc").body)["data"]

proc main() =
  var data: JsonNode = void("gcc")
  var table: TerminalTable

  table.add "Index", "Package", "Description", "Version"

  for i in items(0, data.len):
    table.add $i, data[i]["name"].getStr, data[i]["short_desc"].getStr, data[i]["version"].getStr

  table.echoTableSeps(seps = boxSeps)


main()
