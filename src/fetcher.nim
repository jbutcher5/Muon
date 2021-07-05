import httpclient, json, nancy, strutils, argparse, sequtils

let client = httpclient.newHttpClient()

iterator items(start: int, final: int): int =
  var curr = start

  while curr != final:
    yield curr
    inc curr

type
  ProtoPackage = object of RootObj
    name: string
    description: string
    version: string

  Package* = object of ProtoPackage
    index: string

  Query* = object
    results: seq[Package]
    url: string

proc newProtoPackage(name: string, description: string,
    version: string): ProtoPackage =
  result.name = name
  result.description = description
  result.version = version

proc newPackage(index: string, name: string, description: string,
    version: string): Package =
  result.index = index
  result.name = name
  result.description = description
  result.version = version

proc getMax(data: var seq[Package], largest: int) =

  if data.len > largest:
    var new: seq[Package]
    for i in items(0, largest):
      new.add data[i]

    data = new

proc exactMatch(packageList: var seq[ProtoPackage], packageName: string) =

  for index, package in packageList:
    if package.name == packageName:
      packageList.insert(@[packageList[index]], 0)
      packageList.delete(index+1)
      return

proc xq*(query: string): Query =

  let
    url = "https://xq-api.voidlinux.org/v1/query/x86_64?q=$#" % [query]
    data: JsonNode = parseJson(client.request(url).body)["data"]

  var packageList: seq[ProtoPackage]

  for index, item in data.getElems():
    packageList.add newProtoPackage(item["name"].getStr, item[
        "short_desc"].getStr, item["version"].getStr)

  packageList.exactMatch(query)

  for index, item in packageList:
    result.results.add newPackage($(index+1), item.name, item.description, item.version)

  result.results.getMax(10)

proc aur*(query: string): Query =

  let
    url = "https://aur.archlinux.org/rpc?type=search&arg=$#" % [query]
    data: JsonNode = parseJson(client.request(url).body)["results"]

  var packageList: seq[ProtoPackage]

  for item in data.getElems():
    packageList.add newProtoPackage(item["Name"].getStr, item[
        "Description"].getStr, item["Version"].getStr)

  packageList.exactMatch(query)

  for index, item in packageList:
    result.results.add newPackage($(index+1), item.name, item.description, item.version)

  result.results.getMax(10)

proc createTable*(data: Query) =
  var table: TerminalTable

  table.add "Index", "Package", "Description", "Version"

  for i in data.results:
    table.add i.index, i.name, i.description, i.version

  table.echoTableSeps(seps = boxSeps)
