# Roblox Alpha One MVP

A compact Roblox MVP using a filesystem-first workflow (Rojo + Wally + mise-en-place).

## What this project does
- Spawns players into a stylized starter world with a baseplate, hills, paths, Creator Store tree assets ("Realistic Trees", asset `3256343670`), flower bush assets ("Realistic bush flowers mesh", asset `9187138703`), and an `Age of Beads` rock/grass decor cluster using Creator Store assets (`4038061999`, `2846635652`, `9217425479`, `4453595550`, `13785580624`, `1925262929`, `16170402764`) plus deterministic path/hill/rock props built from decor specs.
- Creates visible glowing circular scoring zones across 12 progression ages, while each age's floating name stays hidden until that age is unlocked by score and shows each zone's score multiplier.
- Spawns players at an `Age of Beads`-side spawn pad instead of the world center.
- Plays looping background music from `assets/Ascension.mp3` (`rbxasset://assets/Ascension.mp3`).
- Shows `Score: 0` UI on join/spawn.
- Uses compact score/rebirth display suffixes for huge values (for example `Qi`, `Sx`, `Sp`, `Dc`).
- Shows `Rebirths: 0` UI under score on join/spawn.
- Shows a live next-unlock tracker (for example `Next: Age of Brass at 600 (595 to go)`) so players can clearly see the score needed for the next age.
- Adds a 96-rank secondary progression track spanning 12 historical ages (8 ranks per age), with themed rank names configured in shared constants.
- Shows a rank UI panel with current rank name, a per-rank progress bar, and compact progress text toward the next rank including current and next rank score multipliers.
- Displays each player's current rank title above their character's head so other players can see progression at a glance.
- Grants every rank a unique aura style that ramps up in spectacle with stronger glow, denser particles, animated pulsing light, and scale growth as players climb toward max rank.
- Shows floating score-gain popups in random screen positions whenever score increases (for example `+1.6k`).
- Shows an owner-only admin panel with buttons to multiply current score (`2x`, `10x`), skip the Lucky Chest cooldown timer, and a guarded reset button that requires a second confirmation click before wiping your own score/rebirths.
- Extends the owner-only admin panel with an **Add Reward** modal to add Lucky Chest hat/vehicle rewards from Roblox Creator Store asset links or raw asset IDs, persisted in a global server-side reward catalog.
- Adds a server-authoritative Rewards inventory panel where players can view unlocked hats/mounts, equip one hat, equip one vehicle mount, and unequip either slot.
- Equips Lucky Chest hats by loading Creator Store assets server-side (with script descendants removed) and attaching safe visuals to the avatar; current temporary forced hat asset is `Classic Cowboy hat` (`17075928250`) for all hat rewards.
- Equips Lucky Chest vehicle mounts as sanitized server-spawned visual models welded to the player, with a modest server-controlled movement speed boost while mounted; current temporary forced mount asset is `Drift Car mobile` (`15244136642`) for all mount rewards.
- Increments score while inside age zones, with each age granting a higher score-per-second multiplier and rank multiplier layering on top.
- Unlock requirements and score gains scale so each age takes roughly the same active time to complete while totals grow exponentially.
- Increments score while inside age zones, with generated non-linear rank/age requirements and per-age score-per-second values derived from a shared progression curve.
- A fresh no-rebirth run targets rank transition times of `30s, 40s, 50s, ...` while players stay in their highest unlocked age zone.
- Entering the glowing `Rebirth` zone now uses a visible score cost, grants rebirths based on how much score you banked (with diminishing returns), resets current score to `0`, preserves highest achieved milestones, and applies temporary catch-up acceleration until players return to their prior best score.
- During deterministic hourly bonus windows, rebirthing from the final age zone grants extra rebirths for high-risk/high-reward timing.
- Entering a locked age zone before meeting its score requirement now flings the player away, kills them, plays a global death SFX, and bursts a cloud of `Nope!` text particles.
- Stops score gain immediately when leaving each zone.
- Adds a server-authoritative Lucky Chest system: once every 5 minutes players can open a chest that spins category then reward item with green/blue/purple/orange/gold rarity odds and can grant score, rebirths, hats, pets, vehicle mounts, or a 1-minute 10x score boost.
- Shows a timed Lucky Chest UI panel and a full-screen animated spin reveal for category and reward rarity each time the chest is opened.
- Keeps score server-authoritative and persistent across death/rejoin with Roblox DataStore.
- Adds a huge floating sky screen near the rebirth zone that shows the all-time top player name and their highest score, sourced from a global server-side DataStore record.

## Project structure
- `src/Shared` shared modules/constants/pure logic/remotes.
- `src/Server` server-only world setup and scoring service.
- `src/Client` UI binding.
- `tests` deterministic unit tests for pure scoring and zone progression logic.

## Prerequisites
- [mise-en-place (mise)](https://mise.jdx.dev/)
- Roblox Studio
- For Studio persistence testing: enable **Game Settings -> Security -> Enable Studio Access to API Services**.

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
4. (Optional, edit-mode preview) Open **View -> Command Bar** and run:

```lua
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local preview = require(ReplicatedStorage.Shared.StudioWorldPreview)
preview.buildInWorkspace()
```

This bakes the world decor, score zones, and rebirth zone into `Workspace` while staying in edit mode so you can see and adjust layout before Play. Generated decor now lives under `Workspace.GeneratedWorld.WorldDecor` and each generated instance is tagged with `Generated=true` and a stable `WorldId` attribute for round-trip export.


5. (Optional, smooth round trip with no copy/paste) After moving decor in Studio, run this in the Command Bar:

```lua
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local preview = require(ReplicatedStorage.Shared.StudioWorldPreview)
preview.syncLayoutModuleFromWorkspace()
```

This captures decor from:
- `Workspace.GeneratedWorld.WorldDecor` (script-built decor)
- `Workspace.ManualWorld` (hand-placed decor you add in Studio)
- legacy `Workspace.WorldDecor` (if present)

and writes the generated module source directly into `ReplicatedStorage.Shared.WorldLayout.Source`, so Rojo can sync the change back to `src/Shared/WorldLayout.luau` without manual paste.

6. (Optional, one-click plugin) A Studio plugin scaffold is included at `studio/WorldLayoutSync.plugin.lua`. Install it as a local plugin for a load/save-style round trip:
   - **World Layout -> Import World** loads from code (`Shared.WorldLayout`) into `Workspace` (load).
   - **World Layout -> Export World** writes current `Workspace` decor back into `Shared.WorldLayout` (save).

   Both actions print explicit success/failure messages in Studio output. Export failures include the underlying error so you can quickly fix missing folders, missing module wiring, or invalid decor setup.

7. Start Play mode.
8. Verify expected MVP behavior:
   - A `Baseplate`, a `GeneratedWorld/WorldDecor` folder for generated decor, an optional `ManualWorld` folder for hand-placed decor you want persisted to layout scripts, twelve glowing age score zones (`Age of Beads` through `Age Beyond Humanity`), and magenta `RebirthZone` appear in `Workspace`.
   - You see `Score: 0` and `Rebirths: 0` in the UI.
   - You see a next-unlock tracker in the UI (example: `Next: Age of Brass at 600 (595 to go)`), which updates as your score increases.
   - You see a rank progression panel (`Pebble Counter` initially) with a filling progress bar and progress text toward the next rank.
   - Whenever score increases, you see a brief floating popup with the compact increase amount (example: `+1.6k`) at a random position.
   - The rank title above each player's head updates automatically as score crosses rank thresholds.
   - Your avatar aura transforms every rank with unique colors, stronger particles/light pulses, and increased size at higher ranks.
   - Standing inside the unlocked age zone increases score each second (later ages grant much larger values).
   - Rebirth grants temporary catch-up acceleration below your previous best score, then progression returns to the baseline timing curve after you catch up.
   - Age zones unlock in sequence as your score passes each requirement threshold.
   - Entering the `Rebirth` zone shows the current rebirth score cost, resets score to `0` only when that cost is met, grants rebirths based on banked score, and preserves highest achieved score/rank/age milestones for catch-up pacing.
   - A giant floating screen above the rebirth area shows the current all-time top scorer name and best-ever score across all players.
   - Entering a still-locked age zone flings you away, then kills you, while preserving your existing score/rebirth totals.
   - Locked-zone deaths play a shared SFX for everyone and spawn flying `Nope!` text particles around the punished player.
   - If you're the game owner, admin panel buttons can multiply your current score by `2x` or `10x`, skip your Lucky Chest cooldown timer, and can reset your own score/rebirths after a two-click confirmation prompt.
   - If you're the game owner, admin panel also includes **Add Reward** for Lucky Chest hats/vehicle mounts (type + asset link/ID + name + rarity); successful submissions persist and become available to all players' Lucky Chest spin pools.
   - The **Rewards** panel (near Lucky Chest) lists unlocked hats/mounts and supports server-validated equip/unequip actions with status messages.
   - Every 5 minutes, opening the Lucky Chest plays a two-stage spin animation and grants one rarity-based reward (score, rebirths, cosmetic unlock, mount unlock, or 10x score for 60 seconds).
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


## Agent-friendly environment bootstrap
To help coding agents (for example, Codex) and humans share the same setup flow, this repo includes:

- Script: `./scripts/setup_env.sh`
- Documentation: `docs/agent-environment-setup.md`

Quick start:

```bash
./scripts/setup_env.sh
```

Or run bootstrap plus validation checks:

```bash
./scripts/setup_env.sh --with-checks
```

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
- **Validation:** Luau type annotations are used in source modules. Selene provides practical static linting; this repo intentionally allows `incorrect_standard_library_use` because filesystem/Lune tests use string-based `require` paths that differ from strict Roblox runtime usage. Full engine-level typecheck in CI is intentionally not over-engineered here.

## CI
GitHub Actions workflow `.github/workflows/ci.yml` runs on push and pull request:
1. checkout
2. bootstrap environment with `./scripts/setup_env.sh` (mise trust/install + Wally install)
3. format check
4. lint
5. tests
6. Rojo build validation

## CD scaffold (manual/safe by default)
`.github/workflows/deploy.yml` is a `workflow_dispatch` placeholder scaffold.

Before enabling real upload, set GitHub Secrets:
- `ROBLOX_UNIVERSE_ID`
- `ROBLOX_PLACE_ID`
- `ROBLOX_OPEN_CLOUD_API_KEY`

Then replace placeholder upload step with your trusted upload mechanism/tool that targets your universe/place IDs.
