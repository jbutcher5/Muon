import fetcher, argparse, tables

let functionTranslationTable = {"void": xq, "aur": aur}.toTable

let p = newParser:
  option("-r", "--repo", help="Repository to search")
  option("-i", "--items", default=some("10"), help="Number of possibilities to display")
  arg("package")

proc main() =
  let args = p.parse(commandLineParams())
  let api = functionTranslationTable[args.repo]
  createTable(api(args.package, args.items.parseInt()))

main()
