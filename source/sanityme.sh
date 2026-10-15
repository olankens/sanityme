#!/usr/bin/env bash

# shellcheck disable=SC2016,SC2059,SC2155

create_agents() {

	# Launch guard
	[[ "${1:-true}" != true ]] && return 0

	# Update AGENTS.md
	sed -i '' '1s/^# .*/# AGENTS/' AGENTS.md 2>/dev/null || echo '# AGENTS' >"AGENTS.md"

	# Harden commit messages
	cat >/tmp/s <<-'EOF'
		## COMMIT MESSAGES

		- Always follow the project's current git commit-msg hook rules for every commit message.
		- Always use the word and before the final item in every written enumeration in message.
		- Never use --no-verify to bypass the project's git commit-msg hook under any circumstances.
	EOF
	awk '/^## COMMIT MESSAGES$/{print "";system("cat /tmp/s");x=1;next}/^## /{x=0}!x' AGENTS.md >AGENTS.md.tmp && mv AGENTS.md.tmp AGENTS.md
	if ! grep -q '^## COMMIT MESSAGES$' AGENTS.md; then printf '\n' >>AGENTS.md && cat /tmp/s >>AGENTS.md; fi
	cat -s AGENTS.md >AGENTS.md.tmp && mv AGENTS.md.tmp AGENTS.md

}

create_conventional() {

	# Launch guard
	[[ "${1:-true}" != true ]] && return 0

	# Update hook
	mkdir -p "$(git rev-parse --git-path hooks)"
	curl -fsSL --retry 3 'https://raw.githubusercontent.com/olankens/subduing/HEAD/source/subduing.sh' -o "$(git rev-parse --git-path hooks)/commit-msg"
	chmod +x "$(git rev-parse --git-path hooks)/commit-msg"

	# Create commit workflow
	local ymlfile=".github/workflows/verify-commit.yml"
	mkdir -p "$(dirname "$ymlfile")" && cat >"$ymlfile" <<-'EOF'
		name: 'Verify Commit'
		on:
		  push:
		    branches: [ '**' ]
		permissions: { }
		concurrency:
		  group: ${{ github.workflow }}-${{ github.ref }}
		  cancel-in-progress: true
		jobs:
		  verify:
		    if: ${{ ! (endsWith(github.actor, '[bot]') || endsWith(github.event.head_commit.author.name, '[bot]') || endsWith(github.event.head_commit.committer.name, '[bot]') || contains(github.event.head_commit.author.email, '[bot]') || contains(github.event.head_commit.committer.email, '[bot]')) }}
		    runs-on: ubuntu-latest
		    steps:
		      - uses: actions/checkout@v7
		        with:
		          fetch-depth: 1
		      - run: |
		          curl -fsSL -m 10 --retry 3 'https://raw.githubusercontent.com/olankens/subduing/HEAD/source/subduing.sh' -o "$RUNNER_TEMP/subduing.sh"
		      - env:
		          MESSAGE: ${{ github.event.head_commit.message }}
		        run: |
		          printf '%s\n' "$MESSAGE" > "$RUNNER_TEMP/commit-msg"
		          sh "$RUNNER_TEMP/subduing.sh" "$RUNNER_TEMP/commit-msg"
	EOF

	# Create pull request workflow
	local ymlfile=".github/workflows/verify-pull-request.yml"
	mkdir -p "$(dirname "$ymlfile")" && cat >"$ymlfile" <<-'EOF'
		name: 'Verify Pull Request'
		on:
		  pull_request:
		    types: [ opened, edited, synchronize, reopened ]
		permissions:
		  contents: read
		concurrency:
		  group: ${{ github.workflow }}-${{ github.event.pull_request.number }}
		  cancel-in-progress: true
		jobs:
		  heading:
		    if: ${{ !endsWith(github.event.pull_request.user.login, '[bot]') }}
		    runs-on: ubuntu-latest
		    steps:
		      - run: |
		          curl -fsSL -m 10 --retry 3 'https://raw.githubusercontent.com/olankens/subduing/HEAD/source/subduing.sh' -o "$RUNNER_TEMP/subduing.sh"
		      - env:
		          HEADING: ${{ github.event.pull_request.title }}
		        run: |
		          printf '%s\n' "$HEADING" > "$RUNNER_TEMP/commit-msg"
		          sh "$RUNNER_TEMP/subduing.sh" "$RUNNER_TEMP/commit-msg"
		  commits:
		    if: ${{ github.event.action != 'edited' && !endsWith(github.event.pull_request.user.login, '[bot]') }}
		    runs-on: ubuntu-latest
		    steps:
		      - uses: actions/checkout@v7
		        with:
		          fetch-depth: 0
		      - run: |
		          curl -fsSL -m 10 --retry 3 'https://raw.githubusercontent.com/olankens/subduing/HEAD/source/subduing.sh' -o "$RUNNER_TEMP/subduing.sh"
		      - env:
		          BASESHA: ${{ github.event.pull_request.base.sha }}
		          HEADSHA: ${{ github.event.pull_request.head.sha }}
		        run: |
		          while IFS= read -r message; do
		            printf '%s\n' "$message" > "$RUNNER_TEMP/commit-msg"
		            sh "$RUNNER_TEMP/subduing.sh" "$RUNNER_TEMP/commit-msg"
		          done < <(git log --format='%s' "$BASESHA..$HEADSHA")
	EOF

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
	local ymlfile=".github/workflows/update-license.yml"
	mkdir -p "$(dirname "$ymlfile")" && cat >"$ymlfile" <<-'EOF'
		name: 'Update License'
		on:
		  schedule:
		    - cron: '0 0 1 1 *'
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
		            const fs = require('node:fs');
		            const year = new Date().getFullYear();
		            let content = fs.readFileSync('LICENSE.md', 'utf8');
		            const pattern = /(Copyright\\s+\\(c\\)\\s+)(\\d{4})(-\\d{4})?/;
		            content = content.replace(pattern, (_, prefix, start, end) => {
		              const startYear = Number(start);
		              const endYear = end ? Number(end) : null;
		              const alreadyUpToDate = startYear === year || endYear === year;
		              return alreadyUpToDate ? `${prefix}${start}${end ? `-${end}` : ''}` : `${prefix}${startYear}-${year}`;
		            });
		            fs.writeFileSync('LICENSE.md', content);
		      - run: |
		          git config user.name 'github-actions[bot]'
		          git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
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
	magick -size 10x400 xc:"#646464" -strip "$deposit/splitter.gif"
	[[ ! -f "$deposit/icon.avif" ]] && curl -L "$baseurl/template-icon.avif" -o "$deposit/icon.avif"
	[[ ! -f "README.md" && ! -f "$deposit/preview-01.avif" ]] && magick -size 10x10 xc:none -strip "$deposit/spacer.gif"
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
		    <a href="#">WEBSITE</a>
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
			  "extends": ["config:recommended", ":semanticCommitScopeDisabled"],
			  "commitMessageLowerCase": "auto",
			  "platformCommit": "enabled",
			  "packageRules": [
			    {
			      "matchUpdateTypes": ["patch", "minor"],
			      "automerge": true
			    }
			  ]
			}
		EOF
	fi

}

invoke_wrapper() {

	# Handle parameters
	local heading="$1"
	local maximum="$2"
	local version="$3"
	local website="$4"
	local members=("${@:5}")
	local bigness=${#members[@]}

	# Change headline
	printf "\033[22;0t" && clear && printf "\033]0;%s\007" "$heading"

	# Handle colors
	local subdued_ansi=$'\033[2m'
	local website_ansi=$'\033[34;4m'
	local loading_ansi=$'\033[93m'
	local success_ansi=$'\033[92m'
	local failure_ansi=$'\033[91m'
	local refresh_ansi=$'\033[0m'

	# Handle widths
	local heading_width=$((maximum - 23))
	local version_width=16
	local logfile_width=$(((maximum - 19) / 2))
	local website_width=$(((maximum - 19) - logfile_width))

	# Handle borders
	printf -v spacing '%*s' "$maximum" ''
	local heading_line=${spacing:0:heading_width+2}
	local version_line=${spacing:0:version_width+2}
	local counter_line=${spacing:0:7}
	local runtime_line=${spacing:0:10}
	local caption_line=${spacing:0:5}
	local logfile_line=${spacing:0:logfile_width+2}
	local website_line=${spacing:0:website_width+2}
	for outline in heading_line version_line counter_line runtime_line caption_line logfile_line website_line; do printf -v "$outline" '%s' "${!outline// /─}"; done
	trap 'printf "\033[?25h"' EXIT && printf '\033[?25l'

	# Output heading
	printf '%s╭%s┬%s╮%s\n' "$subdued_ansi" "$heading_line" "$version_line" "$refresh_ansi"
	printf '%s│%*s│%*s│%s\n' "$subdued_ansi" $((heading_width + 2)) '' $((version_width + 2)) '' "$refresh_ansi"
	printf '%s│%s %-*s %s│%s %*s %s│%s\n' "$subdued_ansi" "$refresh_ansi" "$heading_width" "$heading" "$subdued_ansi" "$refresh_ansi" "$version_width" "v$version" "$subdued_ansi" "$refresh_ansi"
	printf '%s│%*s│%*s│%s\n' "$subdued_ansi" $((heading_width + 2)) '' $((version_width + 2)) '' "$refresh_ansi"
	printf '%s╰%s┴%s╯%s\n' "$subdued_ansi" "$heading_line" "$version_line" "$refresh_ansi"

	# Output information
	local logfile="$(mktemp -d /tmp/XXXXXXXXXXX)/${heading}.log"
	local logpath="FILE://${logfile^^}"
	local weblink="${website^^}"
	printf '%s╭%s┬%s┬%s┬%s╮%s\n' "$subdued_ansi" "$caption_line" "$logfile_line" "$caption_line" "$website_line" "$refresh_ansi"
	printf '%s│%s %s %s│%s %s%-*s%s %s│%s %s %s│%s %s%-*s%s %s│%s\n' "$subdued_ansi" "$refresh_ansi" "LOG" "$subdued_ansi" "$refresh_ansi" "$website_ansi" "$logfile_width" "$logpath" "$refresh_ansi" "$subdued_ansi" "$refresh_ansi" "GIT" "$subdued_ansi" "$refresh_ansi" "$website_ansi" "$website_width" "$weblink" "$refresh_ansi" "$subdued_ansi" "$refresh_ansi"
	printf '%s╰%s┴%s┴%s┴%s╯%s\n' "$subdued_ansi" "$caption_line" "$logfile_line" "$caption_line" "$website_line" "$refresh_ansi"

	# Output progress
	local topline="${subdued_ansi}╭${heading_line}┬${counter_line}┬${runtime_line}╮${refresh_ansi}"
	local divider="${subdued_ansi}├${heading_line}┼${counter_line}┼${runtime_line}┤${refresh_ansi}"
	local botline="${subdued_ansi}╰${heading_line}┴${counter_line}┴${runtime_line}╯${refresh_ansi}"
	printf '%s\n' "$topline"
	printf '%s│%s %-*s %s│%s %-5s %s│%s %-8s %s│%s\n' "$subdued_ansi" "$refresh_ansi" "$heading_width" "FUNCTION" "$subdued_ansi" "$refresh_ansi" "ITEMS" "$subdued_ansi" "$refresh_ansi" "DURATION" "$subdued_ansi" "$refresh_ansi"
	printf '%s\n' "$divider"
	local counter=0 && for running in "${members[@]}"; do
		((++counter)) && printf '\n%s\n\033[2A\r' "$botline"
		local started=$SECONDS
		printf '\n%s ' "${running^^}" >>"$logfile"
		printf '%*s\n\n' $((80 - ${#running} - 1)) '' | tr ' ' '-' >>"$logfile" && eval "$running" >>"$logfile" 2>&1 &
		local taskpid=$! && local wrapped=0
		while ((!wrapped)); do
			local context=$loading_ansi
			if ! kill -0 "$taskpid" 2>/dev/null; then wrapped=1 && if wait "$taskpid"; then context=$success_ansi; else context=$failure_ansi; fi; fi
			local elapsed=$((SECONDS - started))
			printf '\r%s│%s %s%-*s%s %s│%s %s%02d/%02d%s %s│%s %s%02d:%02d:%02d%s %s│%s' "$subdued_ansi" "$refresh_ansi" "$context" "$heading_width" "${running^^}" "$refresh_ansi" "$subdued_ansi" "$refresh_ansi" "$context" "$counter" "$bigness" "$refresh_ansi" "$subdued_ansi" "$refresh_ansi" "$context" $((elapsed / 3600)) $((elapsed % 3600 / 60)) $((elapsed % 60)) "$refresh_ansi" "$subdued_ansi" "$refresh_ansi"
			((wrapped)) || sleep 0.1
		done
		if ((counter < bigness)); then printf '\033[1B\r%s\n' "$divider"; else printf '\033[2B\r'; fi
	done
	printf '\033[?25h'

	# Revert headline
	trap 'printf "\033[23;0t"' EXIT

	# Output newline
	printf "\n"

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
	rm -f ".github/workflows/ci-verify-commit-message.yml"
	rm -f ".github/workflows/ci-verify-commits.yml"
	rm -f ".github/workflows/ci-verify-commits.yml"
	rm -f ".github/workflows/ci-verify-pr-heading.yml"
	rm -f ".github/workflows/ci-verify-pr-title.yml"
	rm -f ".github/workflows/op-bump-copyright.yml"
	rm -f ".github/workflows/op-update-copyright.yml"
	rm -f ".github/workflows/update-license.yml"
	rm -f ".github/workflows/verify-commit.yml"
	rm -f ".github/workflows/verify-pull-request.yml"
	rm -f "AGENTS.md"
	rm -f "CLAUDE.md"
	rm -f "LICENSE.md"
	rm -f "UNLICENSE.md"
	rm -f "package-lock.json"
	rm -f "package.json"
	rm -f "pnpm-lock.yaml"
	rm -rf "node_modules"

	# Update resources
	[[ -d ".assets" ]] && for file in ".assets/"*.svg; do [[ -e "$file" && "${file##*/}" != logo-* && "${file##*/}" != store-* ]] && mv "$file" ".assets/logo-${file##*/}"; done
	[[ -f "README.md" ]] && perl -pi -e 's/(<p><img src="\.assets\/icon\.avif" align="center" width=")[^"]*("><\/p>)/${1}128${2}/g' "README.md"
	[[ -f "README.md" ]] && perl -pi -e 's/(src=")\.assets\/(?!logo-)(?!store-)([^"\/:]+\.svg")/${1}.assets\/logo-${2}/g' "README.md"
	[[ -f "README.md" ]] && perl -pi -e 's/blank\.gif/spacer.gif/g' "README.md"
	[[ -f "README.md" ]] && perl -pi -e 's/divider\.gif/splitter.gif/g' "README.md"
	[[ -f ".gitignore" ]] && perl -0pi -e 's/^# Node(?:\.js)?\n.*?(?=\n\n|\z)//ms' .gitignore || true
	[[ -f ".gitignore" ]] && cat -s .gitignore >.gitignore.tmp && mv .gitignore.tmp .gitignore
	mv ".github/workflows/cd-create-release.yml" ".github/workflows/create-release.yml" || true

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

main() {

	# Enable strictness
	set -euo pipefail

	# Handle globals
	local heading="SANITYME"
	local version="1.0.0" # x-release-please-version
	local website="https://github.com/olankens/sanityme"

	# Handle parameters
	local agents=true
	local conventional=true
	local hardening=true
	local license=true
	local readme=true
	local renovate=true
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--agents=*) agents="${1#*=}" ;;
		--agents) agents=true ;;
		--conventional=*) conventional="${1#*=}" ;;
		--conventional) conventional=true ;;
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
		"create_conventional $conventional"
		"create_hardening $hardening"
		"create_license $license"
		"create_readme $readme"
		"create_renovate $renovate"
	)

	# Invoke wrapper
	invoke_wrapper "$heading" "91" "$version" "$website" "${members[@]}"

}

if [[ -z "${BASH_SOURCE[0]:-}" || "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
