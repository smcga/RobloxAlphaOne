# Roblox Alpha One MVP

A compact Roblox MVP using a filesystem-first workflow (Rojo + Wally + mise-en-place).

## What this project does
- Spawns players into a minimal world with a baseplate.
- Creates visible glowing circular scoring zones (blue + red).
- Shows `Score: 0` UI on join/spawn.
- Shows `Rebirths: 0` UI under score on join/spawn.
- Increments score by exactly `+1` per second while inside the blue zone (based on horizontal position in the circle).
- Applies a rebirth multiplier to score gain (`max(Rebirths, 1)`), so `2` rebirths means `2x` score/sec.
- Unlocks a red high-score zone at `100` points that grants `+50` per second while inside it.
- Entering the red zone before `100` score launches the player away and then kills them.
- Entering the glowing `Rebirth` zone converts score into rebirths (`+1` per `10` score) and resets score to `0`.
- Stops score gain immediately when leaving each zone.
- Keeps score server-authoritative and session-only (no DataStore).

## Project structure
- `src/Shared` shared modules/constants/pure logic/remotes.
- `src/Server` server-only world setup and scoring service.
- `src/Client` UI binding.
- `tests` deterministic unit tests for pure scoring and zone progression logic.

## Prerequisites
- [mise-en-place (mise)](https://mise.jdx.dev/)
- Roblox Studio

## Getting started (beginner step-by-step)

Follow these steps in order from a fresh clone.

### 1) Clone the repository
```bash
git clone <your-repo-url>
cd RobloxAlphaOne
```

### 2) Install mise-en-place (tool version manager)
Install mise first so this project can use pinned versions of Rojo, Wally, Selene, StyLua, and Lune.

- mise install instructions: https://mise.jdx.dev/getting-started.html
- After installing mise globally, run:

```bash
mise trust
mise install
```

This reads `mise.toml` and installs the exact tool versions expected by this repo.

### 3) Install project dependencies
```bash
mise exec -- wally install
```

This creates/updates package files used by the project.

### 4) Verify your environment with local quality checks
Run these commands from the repository root:

```bash
# Check formatting
mise exec -- stylua --check .

# Lint source + tests
mise exec -- selene src tests

# Run deterministic unit tests (pure logic only)
mise exec -- lune run tests/run_tests.luau

# Confirm Rojo can build the place file
mise exec -- rojo build default.project.json --output build.rbxlx
```

If all commands pass, your local setup is working.

### 5) Start live sync with Roblox Studio
```bash
mise exec -- rojo serve default.project.json
```

Keep this terminal running while you work.

### 6) Open the project in Roblox Studio
1. Open Roblox Studio.
2. Install/enable the Rojo Studio plugin (if you have not already).
3. Connect the plugin to the running Rojo server from Step 5.
4. Start Play mode.
5. Verify expected MVP behavior:
   - A `Baseplate`, blue `ScoreZone`, red `HighScoreZone`, and magenta `RebirthZone` appear in `Workspace`.
   - You see `Score: 0` and `Rebirths: 0` in the UI.
   - Standing inside the blue zone adds exactly `+1` score per second.
   - Score gain scales with rebirths (example: `2` rebirths => `+2`/sec in blue zone).
   - At `100+` score, standing in the red zone adds exactly `+50` score per second.
   - Entering the red zone below `100` score launches and kills the player.
   - Entering the `Rebirth` zone resets score to `0` and grants `floor(score / 10)` rebirths.
   - Leaving zones stops score gain immediately.

### 7) Daily workflow (recommended)
For normal development sessions:
1. `mise exec -- rojo serve default.project.json`
2. Connect in Studio and make changes.
3. Run:
   - `mise exec -- stylua .`
   - `mise exec -- selene src tests`
   - `mise exec -- lune run tests/run_tests.luau`
   - `mise exec -- rojo build default.project.json --output build.rbxlx`
4. Commit once all checks pass.

## Local commands
```bash
# Format all Luau files
mise exec -- stylua .

# Check formatting
mise exec -- stylua --check .

# Lint
mise exec -- selene src tests

# Unit tests (pure logic)
mise exec -- lune run tests/run_tests.luau

# Validate Rojo build
mise exec -- rojo build default.project.json --output build.rbxlx

# Start live sync server for Studio
mise exec -- rojo serve default.project.json
```

## Tooling choices
- **Tests:** Uses a lightweight deterministic `lune`-run unit test script for pure logic (`src/Shared/ScoreLogic.luau`, `src/Shared/ZoneProgressionLogic.luau`). This avoids brittle engine simulation while still providing CI coverage for scoring rules.
- **Validation:** Luau type annotations are used in source modules. Selene provides practical static linting. Full engine-level typecheck in CI is intentionally not over-engineered here.

## CI
GitHub Actions workflow `.github/workflows/ci.yml` runs on push and pull request:
1. checkout
2. install mise-en-place and pinned tools
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
