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
    <a href="https://github.com"><img src=".assets/logo-github.svg" align="center" width="56"></a>
    <picture><img src=".assets/splitter.gif" align="center" height="40" width="1"/></picture>
    <a href="https://github.com/renovatebot/renovate"><img src=".assets/logo-renovate.svg" align="center" width="56"></a>
    <picture><img src=".assets/splitter.gif" align="center" height="40" width="1"/></picture>
    <a href="https://commitlint.js.org"><img src=".assets/logo-commitlint.svg" align="center" width="56"></a>
    <picture><img src=".assets/splitter.gif" align="center" height="40" width="1"/></picture>
    <a href="https://wikipedia.org/wiki/Bash_(Unix_shell)"><img src=".assets/logo-bash.svg" align="center" width="56"></a>
  </td></tr></tbody>
</table>

## PREVIEWS

<table><tbody><tr><td width="99999">
  <img src=".assets/preview-01.avif" align="center" width="49.21875%"><picture><img src=".assets/spacer.gif" align="center" width="1.5625%"></picture><img src=".assets/preview-02.avif" align="center" width="49.21875%">
</td></tr></tbody></table>

## FEATURES

<table>
  <tbody><tr><td width="99999">Install the GitHub CLI automatically on macOS and Linux systems by detecting the operating system and invoking Homebrew or the native package manager for a seamless initial setup experience.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Generate the AGENTS.md conventions file from scratch when it is absent or rewrite the opening heading so every agent follows a single source of truth across the entire project workspace.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Configure Commitlint together with CSpell and Simple Git Hooks so that each commit message is validated for proper style, accurate spelling and thorough diff review before pushing changes.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Apply the Renovate bot configuration with curated presets that automatically merge patch and minor dependency updates while requiring manual approval for major version releases across all branches.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Secure the GitHub repository by disabling discussions, issues, projects and the wiki while enforcing rebase merges and allowing branch deletion by default for all team contributors worldwide.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Create an MIT license file populated with the GitHub account name and schedule an annual Actions workflow that updates the copyright year each January without any manual intervention required.</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Build a complete README document complete with icon, banner and preview images, then assemble the feature table and learning sections for new projects ready for immediate public distribution.</td><td>✅</td></tr></tbody>
</table>

## LEARNING

### INVOKE WITHOUT FLAGS

```sh
curl -fsSL https://github.com/olankens/sanityme/releases/latest/download/sanityme.sh | bash
```

### INVOKE WITH FLAGS

```sh
curl -fsSL https://github.com/olankens/sanityme/releases/latest/download/sanityme.sh | bash -s -- \
  --agents=true \
  --commitlint=true \
  --hardening=true \
  --license=true \
  --readme=true \
  --renovate=true
```

### PREPARE NODE TOOLING

```shell
command -v pnpm >/dev/null && pnpm install || npm install
```
