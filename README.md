# Godot Free Game Studio

A zero-cost toolkit for building **Godot 4.7+** games with an AI agent on a
**CPU-only machine** — plus **Turbo Rush**, a complete 3D arcade racing game
built with it.

## What's here

| Path | What it is |
|---|---|
| `game/` | **Turbo Rush** — a full 3D level-based racing game (1000+ levels, 120 cars, 120 paints, 72 wheels, garage, economy, ads). |
| `tools/asset_scout.py` | Fetches **CC0-only** assets (no attribution) into your project. |
| `tools/model_router.py` | Reasoning-first router across free LLM providers, with fallback. |
| `config/models.json` | Model registry with reasoning flags and quotas. |
| `docs/TURBO_RUSH.md` | The game's design, economy and ad-placement strategy. |
| `docs/FREE-TIER-QUOTAS.md` | Verified free LLM quotas. |
| `docs/ASSET-LICENSING.md` | The CC0-only asset policy. |
| `.github/workflows/build.yml` | Exports the game to **APK + WebGL** on free CPU runners. |

## Turbo Rush in one paragraph

A 3D arcade racer for **Android + WebGL**. Six cars per race, position-based
rewards (1st = 250 coins down to 6th = 50), a garage where you spend **coins and
diamonds** to unlock cars, paints and wheels, a five-level upgrade path, daily
tasks that are the main source of rare **diamonds**, and **rewarded ads** before
a race (booster) and after (double coins). **There are no in-app purchases.**
Full details in [`docs/TURBO_RUSH.md`](docs/TURBO_RUSH.md).

## Quick start

```bash
git clone https://github.com/pocketagent98-ai/godot-free-game-studio.git
cd godot-free-game-studio

# run the game (Godot 4.7.2)
godot --path game            # or open game/ in the Godot editor

# free models for your agent
export GEMINI_API_KEY=...
python tools/model_router.py ask --task deep --prompt "Design a new track theme"

# CC0 assets
python tools/asset_scout.py sources
python tools/asset_scout.py fetch --source polyhaven --query mountain --type hdris --res 2k --limit 3 --project ./game
```

## Build the game

Push to `main` and GitHub Actions builds **`turbo_rush.apk`** and the **WebGL**
bundle as artifacts. Locally:

```bash
godot --headless --path game --export-release "Web" build/web/index.html
godot --headless --path game --export-release "Android" build/turbo_rush.apk
```

## Licence

MIT — see [`LICENSE`](LICENSE).
