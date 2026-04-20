# Agent-focused environment setup

This repository includes a setup script intended for coding agents (for example, Codex) and humans who want a one-command bootstrap.

## One-time bootstrap

From the repository root:

```bash
./scripts/setup_env.sh
```

This runs:
- `mise trust`
- `mise install`
- `mise exec -- wally install`

## Bootstrap + full validation (recommended before opening a PR)

```bash
./scripts/setup_env.sh --with-checks
```

In addition to bootstrap, this runs:
- `mise exec -- stylua --check .`
- `mise exec -- selene src tests`
- `mise exec -- lune run tests/run_tests.luau`
- `mise exec -- rojo build default.project.json --output build.rbxlx`

## Why this helps coding agents

- Keeps setup steps deterministic and pinned through `mise.toml`.
- Reduces command drift between local development and GitHub Actions.
- Provides a single entry point agents can run before making edits.
