# Roblox Alpha One MVP

A compact Roblox MVP using a filesystem-first workflow (Rojo + Wally + Aftman).

## What this project does
- Spawns players into a minimal world with a baseplate.
- Creates a visible glowing circular scoring zone.
- Shows `Score: 0` UI on join/spawn.
- Increments score by exactly `+1` per second while inside the zone.
- Stops score gain immediately when leaving the zone.
- Keeps score server-authoritative and session-only (no DataStore).

## Project structure
- `src/Shared` shared modules/constants/pure logic/remotes.
- `src/Server` server-only world setup and scoring service.
- `src/Client` UI binding.
- `tests` deterministic unit tests for pure score logic.

## Prerequisites
- [Aftman](https://github.com/LPGhatguy/aftman)
- Roblox Studio

## Setup
```bash
aftman install
wally install
```

## Local commands
```bash
# Format all Luau files
stylua .

# Check formatting
stylua --check .

# Lint
selene src tests

# Unit tests (pure logic)
lune run tests/run_tests.luau

# Validate Rojo build
rojo build default.project.json --output build.rbxlx

# Start live sync server for Studio
rojo serve default.project.json
```

## Open in Roblox Studio
1. Start sync server: `rojo serve default.project.json`.
2. Open Roblox Studio and connect using the Rojo plugin.
3. Play-test; the server scripts create `Baseplate` and `ScoreZone` in `Workspace`.

## Tooling choices
- **Tests:** Uses a lightweight deterministic `lune`-run unit test script for pure logic (`src/Shared/ScoreLogic.luau`). This avoids brittle engine simulation while still providing CI coverage for the scoring rules.
- **Validation:** Luau type annotations are used in source modules. Selene provides practical static linting. Full engine-level typecheck in CI is intentionally not over-engineered here.

## CI
GitHub Actions workflow `.github/workflows/ci.yml` runs on push and pull request:
1. checkout
2. install Aftman and pinned tools
3. install Wally dependencies
4. format check
5. lint
6. tests
7. Rojo build validation

## CD scaffold (manual/safe by default)
`.github/workflows/deploy.yml` is a `workflow_dispatch` placeholder scaffold.

Before enabling real upload, set GitHub Secrets:
- `ROBLOX_UNIVERSE_ID`
- `ROBLOX_PLACE_ID`
- `ROBLOX_OPEN_CLOUD_API_KEY`

Then replace placeholder upload step with your trusted upload mechanism/tool that targets your universe/place IDs.
