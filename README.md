<div align="center">
  <p><img src=".assets/icon.avif" align="center" width="128"></p>
  <h1><code>SANITYME</code></h1>
</div>

<table>
  <tbody><tr><td align="center" width="99999"><div>
    <a href="https://olankens.com">WEBSITE</a> ·
    <a href="https://ko-fi.com/olankens">FUNDING</a>
  </div></td></tr></tbody>
  <tbody><tr><td align="center" width="99999">&nbsp;<div>
    Bash script automating GitHub CLI, AGENTS.md, Commitlint, Renovate, repository hardening, README, and MIT license setup, giving projects clean, conventional foundations from the first commit and day one.
  </div>&nbsp;</td></tr></tbody>
  <tbody><tr><td align="center" width="99999">
    <a href="https://github.com"><img src=".assets/github.svg" align="center" width="56"></a>
    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
    <a href="https://github.com/renovatebot/renovate"><img src=".assets/renovate.svg" align="center" width="56"></a>
    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
    <a href="https://commitlint.js.org"><img src=".assets/commitlint.svg" align="center" width="56"></a>
    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
    <a href="https://wikipedia.org/wiki/Bash_(Unix_shell)"><img src=".assets/bash.svg" align="center" width="56"></a>
  </td></tr></tbody>
</table>

## PREVIEWS

<table><tbody><tr><td width="99999">
  <img src=".assets/preview-01.avif" align="center" width="49.21875%"><picture><img src=".assets/spacer.gif" align="center" width="1.5625%"></picture><img src=".assets/preview-02.avif" align="center" width="49.21875%">
</td></tr></tbody></table>

## FEATURES

<table>
  <tbody><tr><td width="99999">Set the GitHub CLI as a required dependency, installing it automatically on macOS and Linux through Homebrew or the package manager.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set the AGENTS.md conventions file, creating it when missing or rewriting its first heading to CONVENTIONS so agents share one source of the truth.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set Commitlint alongside CSpell and Simple Git Hooks, wiring a commit hook that lints conventions, checks spelling, and asks Claude to review diffs.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set the Renovate configuration with recommended presets, automatic merging for patch and minor updates, and dashboard approval for major updates.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set GitHub repository hardening, disabling discussions, issues, projects, wiki, merge and squash merging, enforcing rebase merges and deletion.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set the MIT LICENSE with the account name from GitHub and an annual workflow that bumps the copyright year on the first of January through Actions.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set the README with icon, banner, and preview assets, generating the initial layout with feature table and learning sections when it is missing.</td><td>✅</td></tr></tbody>
</table>

## LEARNING

### RUN WITH DEFAULT FLAGS

```sh
curl -fsSL https://github.com/olankens/sanityme/releases/latest/download/sanityme.sh | bash
```

### RUN WITH CUSTOM FLAGS

```sh
curl -fsSL https://github.com/olankens/sanityme/releases/latest/download/sanityme.sh | bash -s -- \
  --agents=true \
  --commitlint=true \
  --hardening=true \
  --license=true \
  --readme=true \
  --renovate=true
```
