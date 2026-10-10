# Pipeline: albena-wheels

LGPL PyAV / OpenCV wheels and ffmpeg CLI tarballs. Wheels and tarballs are built manually on build hosts (`scripts/*.sh`, ~1h Linux / ~40 min macOS) and attached to GitHub Releases. CI does not rebuild them.

## `ci.yml` (PR + push main)
- **lint**: `shellcheck -S error scripts/*.sh`, `py_compile scripts/verify.py`, and a format check on `dist/SHA256SUMS` (64-hex, two spaces, no paths, no duplicate names).
  Existing SC2155 warnings in `build-deps.sh` / `build-wheels.sh` are not gating (threshold is `error`).
- **secrets-scan**: gitleaks 8.30.1 over full history.

## `verify-release.yml`
Runs on PRs touching `dist/SHA256SUMS`, when a release is published/edited, and manually (`workflow_dispatch`, optional tag; default latest).
It downloads all release assets and:
1. runs `sha256sum -c dist/SHA256SUMS` against them,
2. diffs the release's own `SHA256SUMS` asset with the repo copy,
3. fails if the release has any asset not listed in `SHA256SUMS`.

Note: on a PR it verifies against the **latest** release, so bump `SHA256SUMS` only after the release assets are uploaded (or run it manually with the new tag).

## Release flow
Build on hosts > upload assets + `SHA256SUMS` to a new release > commit updated `dist/SHA256SUMS` > verify-release passes.

## Setup (Omar)
Optional: Settings > Branches: require `lint`, `secrets-scan` on `main`. No secrets needed (uses `github.token`).
