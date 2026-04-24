#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git -C "${PWD}" rev-parse --show-toplevel)"

usage() {
  cat <<'USAGE'
Usage: scripts/setup_env.sh [--with-checks]

Bootstraps the RobloxAlphaOne local environment using mise.

Options:
  --with-checks   Run formatter/lint/tests/build validation after install.
  -h, --help      Show this help text.
USAGE
}

run() {
  echo "+ $*"
  "$@"
}

WITH_CHECKS=false
for arg in "$@"; do
  case "$arg" in
    --with-checks)
      WITH_CHECKS=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$REPO_ROOT"

run mise trust "$REPO_ROOT/mise.toml"
run mise install
run mise exec -- wally install

if [[ "$WITH_CHECKS" == true ]]; then
  run mise exec -- stylua --check .
  run mise exec -- selene src tests
  run mise exec -- lune run tests/run_tests.luau
  run mise exec -- rojo build default.project.json --output build.rbxlx
fi

echo "Environment setup complete."
