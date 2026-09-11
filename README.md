<div align="center">
  <p><img src=".assets/icon.avif" align="center" width="112"></p>
  <h1><code>SANITYME</code></h1>
</div>

<table>
  <tbody><tr><td align="center" width="99999"><div>
    <a href="https://olankens.com">WEBSITE</a> ·
    <a href="https://ko-fi.com/olankens">FUNDING</a>
  </div></td></tr></tbody>
  <tbody><tr><td align="center" width="99999">&nbsp;<div>
    Prepare each repository with a single Bash script, setting Commitlint, CSpell, Git hooks, codeowners, Renovate, README, and licensing, so every project stays clean and conventional from the first commit.
  </div>&nbsp;</td></tr></tbody>
  <tbody><tr><td align="center" width="99999">
    <a href="https://github.com"><img src=".assets/github.svg" align="center" width="56"></a>
    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
    <a href="https://docs.renovatebot.com"><img src=".assets/renovate.svg" align="center" width="56"></a>
    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
    <a href="https://wikipedia.org/wiki/Bash_(Unix_shell)"><img src=".assets/bash.svg" align="center" width="56"></a>
    <picture><img src=".assets/divider.gif" align="center" height="40" width="1"/></picture>
    <a href="https://commitlint.js.org"><img src=".assets/commitlint.svg" align="center" width="56"></a>
  </td></tr></tbody>
</table>

## PREVIEWS

<table><tbody><tr><td width="99999">
  <img src=".assets/preview-01.avif" align="center" width="49.21875%"><picture><img src=".assets/spacer.gif" align="center" width="1.5625%"></picture><img src=".assets/preview-02.avif" align="center" width="49.21875%">
</td></tr></tbody></table>

## FEATURES

<table>
  <tbody><tr><td width="99999">Set GitHub CLI dependency</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set Commitlint conventional rules</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set CSpell commit spelling checks</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set Claude commit-message review</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set GitHub repository hardening</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set LICENSE with bump workflow</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set README for your repository</td><td>✅</td></tr></tbody>
  <tbody><tr><td>Set Renovate configuration</td><td>✅</td></tr></tbody>
</table>

## LEARNING

### RUN WITH DEFAULT FLAGS

```sh
curl -fsSL https://raw.githubusercontent.com/olankens/sanityme/HEAD/scripts/sanityme.sh | bash
```

### RUN WITH CUSTOM FLAGS

```sh
curl -fsSL https://raw.githubusercontent.com/olankens/sanityme/HEAD/scripts/sanityme.sh | bash -s -- \
  --commitlint=true \
  --hardening=true \
  --license=true \
  --readme=true \
  --renovate=true
```
