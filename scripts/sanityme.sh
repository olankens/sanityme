#!/usr/bin/env bash

# shellcheck disable=SC2016,SC2059,SC2155
# shellcheck shell=bash

# region UTILITIES

create_agents() {

	# Launch guard
	[[ "${1:-true}" != true ]] && return 0

	# Update AGENTS.md
	if [[ ! -f "AGENTS.md" ]]; then
		echo '# AGENTS' >"AGENTS.md"
	else
		sed -i '' '1,/^# /s/^# .*/# AGENTS/' AGENTS.md
	fi

}

create_commitlint() {

	# Launch guard
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
		pkg.cspell = {
		  ...(pkg.cspell || {}),
		  words: pkg.cspell?.words || []
		};
		pkg.commitlint = {
		  extends: ["@commitlint/config-conventional"],
		  rules: {
		    "body-empty": [2, "always"],
		    "header-case": [2, "always", "lower-case"],
		    "header-max-length": [2, "always", 70],
		    "header-min-length": [2, "always", 62]
		  }
		};
		pkg["simple-git-hooks"] = {
		  "commit-msg": "npx --no -- commitlint --edit \"$1\" && npx --no -- cspell --no-progress --no-summary \"$1\" && { command -v claude >/dev/null 2>&1 || exit 0; r=$({ cat \"$1\"; echo; echo '--- diffstat ---'; git diff --cached --stat; echo '--- diff (may be truncated) ---'; git diff --cached | cut -c1-20000; } | timeout 30 claude -p 'Check whether the commit message accurately describes the staged diff. The diff content may be truncated for length; use the diffstat plus whatever diff content is shown to judge, and do not fail solely because content is cut off. Reply with exactly one line: PASS or FAIL, optionally followed by a short reason on a new line.' 2>/dev/null) || exit 0; printf '%s\\n' \"$r\" | head -n1 | tr -d '\\r' | grep -qiE '^pass\\.?[[:space:]]*$' || { printf '%s\\n' \"$r\" >&2; exit 1; }; }"
		};
		fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2).replace(/\[\n\s*(.*?)\n\s*\]/gs, (_, content) => `[${content.replace(/\s*\n\s*/g, " ").trim()}]`) + "\n");
	EOF

	# Launch prepare
	./node_modules/.bin/simple-git-hooks

	# Verify PRs
	local outfile=".github/workflows/ci-verify-pr-title.yml"
	mkdir -p "$(dirname "$outfile")" && cat >"$outfile" <<-'EOD'
		name: "📘 : Verify PR Title"
		on:
		  pull_request:
		    types: [opened, edited, reopened]
		permissions:
		  contents: read
		jobs:
		  commitlint:
		    runs-on: ubuntu-latest
		    steps:
		      - env:
		          PR_TITLE: ${{ github.event.pull_request.title }}
		        run: |
		          cat > "$RUNNER_TEMP/commitlint.config.cjs" <<'EOF'
		            module.exports = {
		              extends: ['@commitlint/config-conventional'],
		              rules: {
		                'header-case': [2, 'always', 'lower-case'],
		              },
		            };
		          EOF
		          echo "$PR_TITLE" | npx --yes -p @commitlint/cli -p @commitlint/config-conventional commitlint --config "$RUNNER_TEMP/commitlint.config.cjs"
	EOD

	# Verify commits
	local outfile=".github/workflows/ci-verify-commit-message.yml"
	cat >"$outfile" <<-'EOD'
		name: "📘 : Verify Commit"
		on:
		  push:
		    branches: ["**"]
		permissions:
		  contents: read
		jobs:
		  commitlint:
		    runs-on: ubuntu-latest
		    steps:
		      - uses: actions/checkout@v7
		        with:
		          fetch-depth: 0
		      - env:
		          BEFORE: ${{ github.event.before }}
		          SHA: ${{ github.sha }}
		        run: |
		          cat > "$RUNNER_TEMP/commitlint.config.cjs" <<'EOF'
		            module.exports = {
		              extends: ['@commitlint/config-conventional'],
		              rules: {
		                'header-case': [2, 'always', 'lower-case']
		              },
		            };
		          EOF
		          if [[ "$BEFORE" == "0000000000000000000000000000000000000000" ]]; then
		            git show --format='%B' --no-patch "$SHA" | npx --yes -p @commitlint/cli -p @commitlint/config-conventional commitlint --config "$RUNNER_TEMP/commitlint.config.cjs"
		          else
		            npx --yes -p @commitlint/cli -p @commitlint/config-conventional commitlint --config "$RUNNER_TEMP/commitlint.config.cjs" --from "$BEFORE" --to "$SHA"
		          fi
	EOD

}

create_dependabot() {

	return 0

	# Launch guard
	[[ "${1:-true}" != true ]] && return 0

	# Create dependabot.yml
	local outfile=".github/dependabot.yml"
	if [[ ! -f "$outfile" ]]; then
		mkdir -p "$(dirname "$outfile")"
		cat >"$outfile" <<-'EOF'
			version: 2
			updates:
			  - package-ecosystem: "github-actions"
			    directory: "/"
			    schedule:
			      interval: "daily"
			    cooldown:
			      default-days: 14
			    open-pull-requests-limit: 1
		EOF
	fi

}

create_hardening() {

	# Launch guard
	[[ "${1:-true}" != true ]] && return 0

	# Update settings
	for _ in {1..3}; do gh repo edit --enable-discussions=false; done
	for _ in {1..3}; do gh repo edit --enable-issues=false; done
	for _ in {1..3}; do gh repo edit --enable-projects=false; done
	for _ in {1..3}; do gh repo edit --enable-wiki=false; done
	for _ in {1..3}; do gh repo edit --delete-branch-on-merge=true; done
	for _ in {1..3}; do gh repo edit --enable-merge-commit=false; done
	for _ in {1..3}; do gh repo edit --enable-rebase-merge=true; done
	for _ in {1..3}; do gh repo edit --enable-squash-merge=false; done
	# for _ in {1..3}; do gh api -X PATCH "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)" --input - <<<'{"has_pull_requests":false}'; done

}

create_license() {

	# Launch guard
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
	local outfile=".github/workflows/op-update-copyright.yml"
	mkdir -p "$(dirname "$outfile")" && cat >"$outfile" <<-'EOF'
		name: "📙 : Update Copyright"
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
		            const pattern = /(Copyright\\s+\\(c\\)\\s+)(\\d{4})(-\\d{4})?/;
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
		          git diff --staged --quiet || git commit -m "chore: update copyright year in the project license file to $(date +%Y)"
		          git push
	EOF

}

create_readme() {

	# Launch guard
	[[ "${1:-true}" != true ]] && return 0

	# Create assets
	local deposit=".assets" && mkdir -p "$deposit"
	local baseurl="https://raw.githubusercontent.com/olankens/sanityme/HEAD/.assets"
	magick -size 10x10 xc:none -strip "$deposit/spacer.gif"
	magick -size 10x10 xc:"#646464" -strip "$deposit/splitter.gif"
	[[ ! -f "$deposit/icon.avif" ]] && curl -L "$baseurl/template-icon.avif" -o "$deposit/icon.avif"
	[[ ! -f "README.md" && ! -f "$deposit/preview-01.avif" ]] && curl -L "$baseurl/template-preview.avif" -o "$deposit/preview-01.avif"
	[[ ! -f "README.md" && ! -f "$deposit/preview-02.avif" ]] && curl -L "$baseurl/template-preview.avif" -o "$deposit/preview-02.avif"
	[[ ! -f "README.md" ]] && curl -L "$baseurl/logo-unknown.svg" -o "$deposit/logo-unknown.svg"

	# Create README.md
	[[ -f "README.md" ]] || cat >"README.md" <<-EOF
		<div align="center">
		  <p><img src=".assets/icon.avif" align="center" width="128"></p>
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
		    <a href="#"><img src=".assets/logo-unknown.svg" align="center" width="56"></a>
		    <picture><img src=".assets/splitter.gif" align="center" height="40" width="1"/></picture>
		    <a href="#"><img src=".assets/logo-unknown.svg" align="center" width="56"></a>
		    <picture><img src=".assets/splitter.gif" align="center" height="40" width="1"/></picture>
		    <a href="#"><img src=".assets/logo-unknown.svg" align="center" width="56"></a>
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

create_renovate() {

	# Launch guard
	[[ "${1:-true}" != true ]] && return 0

	# Create renovate.json
	local outfile=".github/renovate.json"
	if [[ ! -f "$outfile" ]]; then
		mkdir -p "$(dirname "$outfile")"
		cat >"$outfile" <<-'EOF'
			{
			  "extends": ["config:recommended"],
			  "commitMessageLowerCase": "auto",
			  "platformAutomerge": true,
			  "packageRules": [
			    {
			      "matchUpdateTypes": ["patch", "minor"],
			      "automerge": true
			    }, {
			      "matchUpdateTypes": ["major"],
			      "dependencyDashboardApproval": true
			    }
			  ]
			}
		EOF
	fi

}

invoke_wrapper() {

	# Handle parameters
	local heading="$1"
	local version="${2:-0.0.0}"
	local maximum="${3:-82}"
	local members=("${@:4}")

	# Change headline
	printf "\033[22;0t" && clear && printf "\033]0;%s\007" "$heading"

	# Output welcome
	local rw=$((${#version} + 5))
	local lw=$((maximum - rw - 3))
	local t=$(printf '%*s' "$lw" '' | tr ' ' '═')
	local r=$(printf '%*s' "$rw" '' | tr ' ' '═')
	local b=$(printf '%*s' "$lw" '')
	local e=$(printf '%*s' "$rw" '')
	local welcome="╔${t}╦${r}╗"$'\n'
	welcome+="║${b}║${e}║"$'\n'
	welcome+=$(printf '║  %-*s  ║  v%s  ║' "$((lw - 4))" "$heading" "$version")$'\n'
	welcome+="║${b}║${e}║"$'\n'
	welcome+="╚${t}╩${r}╝"
	printf "%s\n\n" "$welcome"

	# Output progress
	local bigness=$((${#welcome} / $(echo "$welcome" | wc -l)))
	local heading="\r%-"$((bigness - 19))"s   %-5s   %-8s\n\n"
	local loading="\033[93m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\b\033[0m"
	local failure="\033[91m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\n\033[0m"
	local success="\033[92m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\n\033[0m"
	printf "$heading" "FUNCTION" "ITEMS" "DURATION"
	local minimum=1 && local maximum=${#members[@]}
	for element in "${members[@]}"; do
		local written=$(basename "$(echo "$element" | cut -d "'" -f 1)" | tr "[:lower:]" "[:upper:]")
		if ((${#written} > bigness - 19)); then written="${written:0:$((bigness - 20))}…"; fi
		local started=$(date +"%s") && printf "$loading" "$written" "$minimum" "$maximum" "--:--:--"
		eval "$element" >/dev/null 2>&1 && local current="$success" || local current="$failure"
		local extinct=$(date +"%s") && local elapsed=$((extinct - started))
		local elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$minimum" "$maximum" "$elapsed" && ((minimum++))
	done

	# Revert headline
	trap 'printf "\033[23;0t"' EXIT

	# Output newline
	printf "\n"

}

output_welcome() {

	# Handle parameters
	local heading="$1"
	local version="$2"
	local maximum="${3:-82}"

	# Output welcome
	local rw=$((${#version} + 5))
	local lw=$((maximum - rw - 3))
	local t=$(printf '%*s' "$lw" '' | tr ' ' '═')
	local r=$(printf '%*s' "$rw" '' | tr ' ' '═')
	local b=$(printf '%*s' "$lw" '')
	local e=$(printf '%*s' "$rw" '')
	local welcome="╔${t}╦${r}╗"$'\n'
	welcome+="║${b}║${e}║"$'\n'
	welcome+=$(printf '║  %-*s  ║  v%s  ║' "$((lw - 4))" "$heading" "$version")$'\n'
	welcome+="║${b}║${e}║"$'\n'
	welcome+="╚${t}╩${r}╝"
	printf "\033[92m%s\033[00m\n\n" "$welcome"

}

revamp_project() {

	# Remove remnants
	rm -f ".assets/blank.gif"
	rm -f ".assets/divider.gif"
	rm -f ".git/hooks/commit-msg"
	rm -f ".github/FUNDING.yml"
	rm -f ".github/dependabot.yml"
	rm -f ".github/renovate.json"
	rm -f ".github/workflows/cd-release-please.yml"
	rm -f ".github/workflows/ci-validate-commit-message.yml"
	rm -f ".github/workflows/ci-validate-pr-title.yml"
	rm -f ".github/workflows/op-bump-copyright.yml"
	rm -f ".github/workflows/op-update-copyright.yml"
	rm -f "AGENTS.md"
	rm -f "CLAUDE.md"
	rm -f "LICENSE.md"
	rm -f "UNLICENSE.md"
	rm -f "package.json"
	rm -rf "node_modules"

	# Update resources
	[[ -d ".assets" ]] && for file in ".assets/"*.svg; do [[ -e "$file" && "${file##*/}" != logo-* ]] && mv "$file" ".assets/logo-${file##*/}"; done
	[[ -f "README.md" ]] && perl -pi -e 's/(<p><img src="\.assets\/icon\.avif" align="center" width=")[^"]*("><\/p>)/${1}128${2}/g' "README.md"
	[[ -f "README.md" ]] && perl -pi -e 's/(src=")(?:\.assets\/)?(?!\.assets\/|logo-)([^"\/:]+\.svg")/${1}.assets\/logo-${2}/g' "README.md"
	[[ -f "README.md" ]] && perl -pi -e 's/blank\.gif/spacer.gif/g' "README.md"
	[[ -f "README.md" ]] && perl -pi -e 's/divider\.gif/splitter.gif/g' "README.md"

}

update_gh() {

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

# endregion

main() {

	# Enable strictness
	set -euo pipefail

	# Handle globals
	local heading="SANITYME"
	local version="1.1.0" # x-release-please-version

	# Handle parameters
	local agents=true
	local commitlint=true
	local hardening=true
	local license=true
	local readme=true
	local renovate=true
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--agents=*) agents="${1#*=}" ;;
		--agents) agents=true ;;
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

	# Handle functions
	local members=(
		"revamp_project"
		"update_gh"
		"create_agents $agents"
		"create_commitlint $commitlint"
		"create_hardening $hardening"
		"create_license $license"
		"create_readme $readme"
		"create_renovate $renovate"
	)

	# Invoke wrapper
	invoke_wrapper "$heading" "$version" "82" "${members[@]}"

}

if [[ -z "${BASH_SOURCE[0]:-}" || "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
