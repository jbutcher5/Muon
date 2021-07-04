import fetcher, argparse, tables

let functionTranslationTable = {"void": xq, "aur": aur}.toTable

let p = newParser:
  option("-r", "--repo", help="Repository")
  arg("package")

proc main() =
  let args = p.parse(commandLineParams())

  let api = functionTranslationTable[args.repo]
  createTable(api(args.package))

main()
