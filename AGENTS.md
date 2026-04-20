# Repository instructions for Codex agents

## Architecture and scope
- Preserve the Roblox filesystem-first layout (`src/Shared`, `src/Server`, `src/Client`, `tests`).
- Keep modules small and focused; avoid giant scripts.
- Keep scoring and other core rules in pure/shared modules where possible.
- Do not add features outside the current MVP without explicit request.

## Server authority and networking
- Treat the server as authoritative for gameplay state.
- Never trust client-reported score values.
- Use remotes only for UI replication or user intent, never as score truth.
- Flag any change that moves scoring decisions to client-side.

## Pure logic and tests
- Prefer pure logic modules with no direct Roblox service calls.
- Avoid direct `game:GetService` calls in pure modules.
- Add or update deterministic unit tests for every logic change.
- Keep tests focused on pure logic; avoid engine-heavy simulation unless necessary.

## Tooling and quality
- Keep `aftman.toml`, `wally.toml`, Selene, StyLua, and workflows in sync with code changes.
- Run format, lint, tests, and Rojo build validation when practical.
- Update README whenever setup or commands change.

## World placement guardrails
- For `Cylinder` decor parts, explicitly set rotation so their intended axis is correct (for example, `z=90` to stand trunks upright or lay circular pads flat).
- Position parts using center-based math (`position.y >= floorY + halfHeight`) so props do not clip severely through the baseplate.
- When adjusting world props, add/update deterministic tests that verify orientation-critical pieces and floor clipping constraints.


## Creator Store asset handling
- Treat user phrases like **store assets**, **creator assets**, **free assets**, **Creator Store assets**, or misspellings like **creatore store assets** as requests about Roblox Creator Store assets.
- When a user gives an asset name but not an ID, determine the asset ID before implementation (check this repo first, then perform Creator Store lookup if needed).
- Prefer explicit asset IDs in code/config to avoid ambiguity.
- Keep `docs/creator-store-assets.md` synchronized whenever Creator Store assets are added, removed, renamed, or replaced.
