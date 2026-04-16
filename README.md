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

## Getting started (beginner step-by-step)

Follow these steps in order from a fresh clone.

### 1) Clone the repository
```bash
git clone <your-repo-url>
cd RobloxAlphaOne
```

### 2) Install Aftman (tool version manager)
Install Aftman first so this project can use pinned versions of Rojo, Wally, Selene, StyLua, and Lune.

- Aftman install instructions: https://github.com/LPGhatguy/aftman
- After installing Aftman globally, run:

```bash
aftman install
```

This reads `aftman.toml` and installs the exact tool versions expected by this repo.

### 3) Install project dependencies
```bash
wally install
```

This creates/updates package files used by the project.

### 4) Verify your environment with local quality checks
Run these commands from the repository root:

```bash
# Check formatting
stylua --check .

# Lint source + tests
selene src tests

# Run deterministic unit tests (pure logic only)
lune run tests/run_tests.luau

# Confirm Rojo can build the place file
rojo build default.project.json --output build.rbxlx
```

If all commands pass, your local setup is working.

### 5) Start live sync with Roblox Studio
```bash
rojo serve default.project.json
```

Keep this terminal running while you work.

### 6) Open the project in Roblox Studio
1. Open Roblox Studio.
2. Install/enable the Rojo Studio plugin (if you have not already).
3. Connect the plugin to the running Rojo server from Step 5.
4. Start Play mode.
5. Verify expected MVP behavior:
   - A `Baseplate` and glowing circular `ScoreZone` appear in `Workspace`.
   - You see `Score: 0` in the UI.
   - Standing inside the zone adds exactly `+1` score per second.
   - Leaving the zone stops score gain immediately.

### 7) Daily workflow (recommended)
For normal development sessions:
1. `rojo serve default.project.json`
2. Connect in Studio and make changes.
3. Run:
   - `stylua .`
   - `selene src tests`
   - `lune run tests/run_tests.luau`
   - `rojo build default.project.json --output build.rbxlx`
4. Commit once all checks pass.

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
