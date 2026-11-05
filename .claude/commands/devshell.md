---
description: Set up a Nix dev shell with direnv for a project
argument-hint: <project path> [go|node|python|rust|default]
---
Set up project tooling for: $ARGUMENTS

1. Inspect the project (go.mod, package.json + lockfile, pyproject.toml/requirements.txt, Cargo.toml, Makefile, .tool-versions, Dockerfile) to find languages and exact versions.
2. If `flake.nix` exists, use it. Otherwise ask whether the flake may be committed to the repo.
   - Yes → `nix flake init -t ~/nixos-devbox#<template>` and edit `packages`.
   - No → `echo 'use flake ~/nixos-devbox#<shell>' > .envrc`, add `.envrc` and `.direnv/` to `.git/info/exclude`.
3. Pin versions that matter (e.g. `nodejs_20`, `go_1_24`, `python312`) when the project specifies them.
4. `git add flake.nix flake.lock .envrc` (flake case), `direnv allow`.
5. Verify: `nix develop -c <each tool> --version`, then run the project's build or test command once.
