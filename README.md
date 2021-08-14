<img align="left" src="https://duckduckgo.com/i/e93a72e0.png" width="100"></img>
Muon is a void linux and arch aur package query tool. Simply you can query the name of a package you are looking for. Muon wraps the void linux repo and the arch user repository

---

<img align="right" src="https://user-images.githubusercontent.com/36408549/129447824-e48225cd-7730-4c41-a34a-574cabde3198.png" width="600"></img>

### Usage

`muon <package_name> -r <repo>`

### Options

`-r` - repo to search

`-i` - search results to print (default 10)

### Examples

`muon gcc -r aur`

`muon gcc -r void`

`muon gcc -r void -i 20`
