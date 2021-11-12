import httpclient, json, nancy, strutils, argparse, sequtils, re

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

  AURProtoPackage = object of ProtoPackage
    votes: int

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

proc newAURProtoPackage(name: string, description: string,
    version: string, votes: int): AURProtoPackage =
  result.name = name
  result.description = description
  result.version = version
  result.votes = votes

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

proc htmlASCII(text: string): string =

  for i in text:
    result &= "%" & ($i).toHex()

proc regexMatch(packageList: var seq[ProtoPackage], packageName: string) =

  var reversedSeq = packageList

  reversedSeq.reverse()

  for index, package in reversedSeq:
    if find(package.name, re packageName) >= 0:
      reversedSeq.insert(@[reversedSeq[index]], len(reversedSeq)-1)
      reversedSeq.delete(index+1)

  reversedSeq.reverse()

  packageList = reversedSeq

proc exactMatch(packageList: var seq[ProtoPackage], packageName: string) =

  for index, package in packageList:
    if package.name == packageName:
      packageList.insert(@[packageList[index]], 0)
      packageList.delete(index+1)
      return

proc voteMatch(packageList: var seq[AURProtoPackage]) =

  var complete = false

  while not complete:
    for index, package in packageList:
      for i in 0 ..< index:
        if packageList[i].votes < package.votes:
          swap(packageList[i], packageList[index])

    var correctOrder: int = 0
    for i in 0 ..< packageList.len-1:
      if packageList[i].votes >= packageList[i+1].votes:
        correctOrder += 1

    if correctOrder == packageList.len-1:
      complete = true

proc toProtoSeq(packageList: seq[AURProtoPackage]): seq[ProtoPackage] =
  for package in packageList:
    result.add newProtoPackage(package.name, package.description, package.version)

proc xq*(query: string, quantity: int): Query =

  let
    url = "https://xq-api.voidlinux.org/v1/query/x86_64?q=$#" % [htmlASCII(query)]
    data: JsonNode = parseJson(client.request(url).body)["data"]

  var packageList: seq[ProtoPackage]

  for index, item in data.getElems():
    packageList.add newProtoPackage(item["name"].getStr, item[
        "short_desc"].getStr, item["version"].getStr)

  packageList.regexMatch(query)
  packageList.exactMatch(query)

  for index, item in packageList:
    result.results.add newPackage($(index+1), item.name, item.description, item.version)

  result.results.getMax(quantity)

proc aur*(query: string, quantity: int): Query =

  let
    url = "https://aur.archlinux.org/rpc?type=search&arg=$#" % [htmlASCII(query)]
    data: JsonNode = parseJson(client.request(url).body)["results"]

  var packageListAUR: seq[AURProtoPackage]
  var packageList: seq[ProtoPackage]

  for item in data.getElems():
    packageListAUR.add newAURProtoPackage(item["Name"].getStr, item[
        "Description"].getStr, item["Version"].getStr, item["NumVotes"].getInt)

  packageListAUR.voteMatch()
  packageList = packageListAUR.toProtoSeq()

  packageList.regexMatch(query)
  packageList.exactMatch(query)

  for index, item in packageList:
    result.results.add newPackage($(index+1), item.name, item.description, item.version)

  result.results.getMax(quantity)

proc createTable*(data: Query) =
  var table: TerminalTable

  table.add "Index", "Package", "Description", "Version"

  for i in data.results:
    table.add i.index, i.name, i.description, i.version

  table.echoTableSeps(seps = boxSeps)
