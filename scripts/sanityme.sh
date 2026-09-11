#!/usr/bin/env bash

# shellcheck disable=SC2016,SC2155

set_commitlint() {

	# Launch when requested
	[[ "${1:-true}" != true ]] && return 0

	# Create package.json
	if [[ ! -f package.json ]]; then printf '{}\n' >package.json; fi

	# Update .gitignore
	if ! grep -qF 'node_modules' .gitignore 2>/dev/null; then
		[[ -s .gitignore ]] && printf '%s\n\n' "$(<.gitignore)" >.gitignore
		cat >>.gitignore <<-'EOF'
			# Node
			node_modules/
			package-lock.json
			pnpm-lock.yaml
		EOF
	fi

	# Handle dependencies
	pnpm i -D --lockfile=false @commitlint/cli@latest @commitlint/config-conventional@latest cspell@latest simple-git-hooks@latest || npm i -D --no-package-lock @commitlint/cli@latest @commitlint/config-conventional@latest cspell@latest simple-git-hooks@latest

	# Update package.json
	node <<-'EOF'
		const fs = require("fs");
		const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
		pkg.devDependencies = {
		  ...pkg.devDependencies,
		  "@commitlint/cli": "latest",
		  "@commitlint/config-conventional": "latest",
		  "cspell": "latest",
		  "simple-git-hooks": "latest"
		};
		pkg.scripts = pkg.scripts || {};
		pkg.scripts.prepare = "simple-git-hooks";
		pkg.commitlint = {
		  extends: ["@commitlint/config-conventional"],
		  rules: {
		    "header-case": [2, "always", "lower-case"],
		    "header-max-length": [2, "always", 70],
		    "header-min-length": [2, "always", 62],
		    "body-empty": [2, "always"]
		  }
		};
		pkg["simple-git-hooks"] = {
		  "commit-msg": "npx --no -- commitlint --edit \"$1\" && npx --no -- cspell --no-progress --no-summary \"$1\" && { command -v claude >/dev/null 2>&1 || exit 0; r=$({ cat \"$1\"; echo; echo '--- diffstat ---'; git diff --cached --stat; echo '--- diff (may be truncated) ---'; git diff --cached | cut -c1-20000; } | timeout 30 claude -p 'Check whether the commit message accurately describes the staged diff. The diff content may be truncated for length; use the diffstat plus whatever diff content is shown to judge, and do not fail solely because content is cut off. Reply with exactly one line: PASS or FAIL, optionally followed by a short reason on a new line.' 2>/dev/null) || exit 0; printf '%s\\n' \"$r\" | head -n1 | tr -d '\\r' | grep -qiE '^pass\\.?[[:space:]]*$' || { printf '%s\\n' \"$r\" >&2; exit 1; }; }"
		};
		fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
	EOF

	# Launch prepare
	./node_modules/.bin/simple-git-hooks

	# Create workflow
	local outfile=".github/workflows/ci-validate-pr-title.yml"
	mkdir -p "$(dirname "$outfile")" && cat >"$outfile" <<-'EOD'
		name: "📘 : Validate PR Title"
		on:
		  pull_request:
		    types: [opened, edited, reopened]
		permissions:
		  contents: read
		jobs:
		  commitlint:
		    runs-on: ubuntu-latest
		    steps:
		      - run: |
		          cat > commitlint.config.cjs <<'EOF'
		          module.exports = {
		            extends: ['@commitlint/config-conventional'],
		            rules: {
		              'header-case': [2, 'always', 'lower-case'],
		            },
		          };
		          EOF
		      - env:
		          PR_TITLE: ${{ github.event.pull_request.title }}
		        run: |
		          echo "$PR_TITLE" | npx --yes -p @commitlint/cli -p @commitlint/config-conventional commitlint
	EOD

}

set_github_cli() {

	# Verify dependency
	command -v gh &>/dev/null && return 0

	# Settle dependency
	case "$(uname)" in
	Darwin)
		brew install gh
		;;
	Linux)
		. /etc/os-release
		case "$ID" in
		debian | ubuntu)
			curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
			sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
			sudo apt update && sudo apt install -y gh
			;;
		almalinux | fedora | rhel | rocky)
			sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
			sudo dnf install -y gh
			;;
		*)
			echo "Unsupported Linux OS: $ID" >&2
			return 1
			;;
		esac
		;;
	*)
		echo "Unsupported OS" >&2
		return 1
		;;
	esac

}

set_hardening() {

	# Launch when requested
	[[ "${1:-true}" != true ]] && return 0

	# Update settings
	gh repo edit \
		--enable-discussions=false \
		--enable-issues=false \
		--enable-projects=false \
		--enable-wiki=false \
		--delete-branch-on-merge=true \
		--enable-merge-commit=false \
		--enable-rebase-merge=true \
		--enable-squash-merge=true

}

set_license() {

	# Launch when requested
	[[ "${1:-true}" != true ]] && return 0

	# Create LICENSE.md
	local account="$(gh api user --jq ".name")"
	[[ ! -f "LICENSE.md" ]] && cat >"LICENSE.md" <<-EOF
		MIT License

		Copyright (c) $(date +%Y) ${account}

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	EOF

	# Create workflow
	rm -f ".github/workflows/op-update-copyright.yml"
	local outfile=".github/workflows/op-bump-copyright.yml"
	mkdir -p "$(dirname "$outfile")" && cat >"$outfile" <<-'EOF'
		name: "📙 : Bump Copyright"
		on:
		  schedule:
		    - cron: "0 0 1 1 *"
		  workflow_dispatch:
		permissions:
		  contents: write
		jobs:
		  update:
		    runs-on: ubuntu-latest
		    steps:
		      - uses: actions/checkout@v7
		      - uses: actions/github-script@v9
		        with:
		          script: |
		            const fs = require("node:fs");
		            const year = new Date().getFullYear();
		            let content = fs.readFileSync("LICENSE.md", "utf8");
		            const pattern = /(Copyright\s+\(c\)\s+)(\d{4})(-\d{4})?/;
		            content = content.replace(pattern, (_, prefix, start, end) => {
		              const startYear = Number(start);
		              const endYear = end ? Number(end) : null;
		              const alreadyUpToDate = startYear === year || endYear === year;
		              return alreadyUpToDate ? `${prefix}${start}${end ? `-${end}` : ""}` : `${prefix}${startYear}-${year}`;
		            });
		            fs.writeFileSync("LICENSE.md", content);
		      - run: |
		          git config user.name "github-actions[bot]"
		          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
		          git add LICENSE.md
		          git diff --staged --quiet || git commit -m "chore: bump all project copyright notices to reflect the year $(date +%Y)"
		          git push
	EOF

}

set_readme() {

	# Launch when requested
	[[ "${1:-true}" != true ]] && return 0

	# Create assets
	local deposit=".assets" && mkdir -p "$deposit"
	magick -size 10x10 xc:none -strip "$deposit/spacer.gif"
	magick -size 10x10 xc:"#646464" -strip "$deposit/divider.gif"
	[[ ! -f "$deposit/icon.avif" ]] && curl -L "https://raw.githubusercontent.com/olankens/sanityme/HEAD/.assets/default.avif" -o "$deposit/icon.avif"
	[[ ! -f "$deposit/preview-01.avif" ]] && curl -L "https://raw.githubusercontent.com/olankens/sanityme/HEAD/.assets/preview.avif" -o "$deposit/preview-01.avif"
	[[ ! -f "$deposit/preview-02.avif" ]] && curl -L "https://raw.githubusercontent.com/olankens/sanityme/HEAD/.assets/preview.avif" -o "$deposit/preview-02.avif"
	[[ ! -f "README.md" ]] && curl -L "https://raw.githubusercontent.com/olankens/sanityme/HEAD/.assets/unknown.svg" -o "$deposit/unknown.svg"

	# Vanish remnants
	rm -f "$deposit/blank.gif"
	[[ -f "README.md" ]] && perl -pi -e 's/blank\.gif/spacer.gif/g' "README.md"

	# Create README.md
	[[ -f "README.md" ]] || cat >"README.md" <<-EOF
		<div align="center">
		  <p><img src=".assets/icon.avif" align="center" width="112"></p>
		  <h1><code>$(gh repo view --json name -q .name | tr '[:lower:]' '[:upper:]')</code></h1>
		</div>

		<table>
		  <tbody><tr><td align="center" width="99999"><div>
		    <a href="https://olankens.com">WEBSITE</a>
		  </div></td></tr></tbody>
		  <tbody><tr><td align="center" width="99999">&nbsp;<div>
		    ...
		  </div>&nbsp;</td></tr></tbody>
		  <tbody><tr><td align="center" width="99999">
		    <a href="#"><img src=".assets/unknown.svg" align="center" width="56"></a>
		    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
		    <a href="#"><img src=".assets/unknown.svg" align="center" width="56"></a>
		    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
		    <a href="#"><img src=".assets/unknown.svg" align="center" width="56"></a>
		  </td></tr></tbody>
		</table>

		## PREVIEWS

		<table><tbody><tr><td width="99999">
		  <img src=".assets/preview-01.avif" align="center" width="49.21875%"><picture><img src=".assets/spacer.gif" align="center" width="1.5625%"></picture><img src=".assets/preview-02.avif" align="center" width="49.21875%">
		</td></tr></tbody></table>

		## FEATURES

		<table>
		  <tbody><tr><td width="99999">Lorem ipsum dolor sit amet</td><td>✅</td></tr></tbody>
		  <tbody><tr><td>Morbi sit amet sapien vel nulla</td><td>🚧</td></tr></tbody>
		  <tbody><tr><td>Ut posuere odio nec volutpat</td><td>❌</td></tr></tbody>
		</table>

		## LEARNING

		### LOREM IPSUM DOLOR

		\`\`\`shell
		​
		​
		​
		​
		\`\`\`
	EOF

}

set_renovate() {

	# Launch when requested
	[[ "${1:-true}" != true ]] && return 0

	# Create renovate.json
	local outfile=".github/renovate.json"
	if [[ ! -f "$outfile" ]]; then
		mkdir -p "$(dirname "$outfile")"
		cat >"$outfile" <<-'EOF'
			{
			  "extends": [
			    "config:recommended"
			  ],
			  "commitMessageLowerCase": "auto",
			  "platformAutomerge": true,
			  "packageRules": [
			    {
			      "matchUpdateTypes": [
			        "minor",
			        "patch",
			        "pin",
			        "digest"
			      ],
			      "automerge": true
			    },
			    {
			      "matchManagers": [
			        "github-actions"
			      ],
			      "matchUpdateTypes": [
			        "major"
			      ],
			      "automerge": true
			    }
			  ]
			}
		EOF
	fi

}

main() {

	# Enable strict mode
	set -euo pipefail

	# Decode flags
	local commitlint=true
	local hardening=true
	local license=true
	local readme=true
	local renovate=true
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--commitlint=*) commitlint="${1#*=}" ;;
		--commitlint) commitlint=true ;;
		--hardening=*) hardening="${1#*=}" ;;
		--hardening) hardening=true ;;
		--license=*) license="${1#*=}" ;;
		--license) license=true ;;
		--readme=*) readme="${1#*=}" ;;
		--readme) readme=true ;;
		--renovate=*) renovate="${1#*=}" ;;
		--renovate) renovate=true ;;
		esac
		shift
	done

	# Change heading
	clear && printf "\033]0;%s\007" "SANITYME"

	# Output welcome
	read -r -d "" welcome <<-EOF || true
		╔════════════════════════════════════════════════════════════════════════════════╗
		║                                                                                ║
		║                     ▗▄▖   ▄  ▗▄ ▗▖ ▄▄▄ ▗▄▄▄▖▄▖ ▗▄▗▄ ▄▖▗▄▄▄▖                    ║
		║                    ▗▛▀▜  ▐█▌ ▐█ ▐▌ ▀█▀ ▝▀█▀▘▐▙ ▟▌▐█ █▌▐▛▀▀▘                    ║
		║                    ▐▙    ▐█▌ ▐▛▌▐▌  █    █   █▄█ ▐███▌▐▌                       ║
		║                     ▜█▙  █ █ ▐▌█▐▌  █    █   ▝█▘ ▐▌█▐▌▐███                     ║
		║                       ▜▌ ███ ▐▌▐▟▌  █    █    █  ▐▌▀▐▌▐▌                       ║
		║                    ▐▄▄▟▘▗█ █▖▐▌ █▌ ▄█▄   █    █  ▐▌ ▐▌▐▙▄▄▖                    ║
		║                     ▀▀▘ ▝▘ ▝▘▝▘ ▀▘ ▀▀▀   ▀    ▀  ▝▘ ▝▘▝▀▀▀▘                    ║
		║                                                                                ║
		╚════════════════════════════════════════════════════════════════════════════════╝
	EOF
	printf "\033[92m%s\033[00m\n\n" "$welcome"

	# Invoke functions
	set_github_cli
	set_commitlint "$commitlint"
	set_hardening "$hardening"
	set_license "$license"
	set_readme "$readme"
	set_renovate "$renovate"

	# Revert heading
	trap 'printf "\033]0;%s\007" "$(basename "$PWD")"' EXIT

}

if [[ -z "${BASH_SOURCE[0]:-}" || "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
