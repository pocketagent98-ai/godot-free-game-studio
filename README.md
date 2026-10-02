# Godot Free Game Studio

An opinionated, **₹0 / $0** toolkit for building studio-grade **Godot 4.7+** games with an AI agent — on a **CPU-only machine**, using free model tiers and **CC0 (public-domain) assets**.

It gives you four things:

1. **`tools/asset_scout.py`** — a working agent that downloads **CC0-only** assets (no attribution ever required) straight into your Godot project.
2. **`tools/model_router.py`** — a **reasoning-first** router across the free LLM providers (Gemini, z.ai GLM Flash, NVIDIA NIM, NaraRouter, OmniRoute), with automatic fallback.
3. **`.github/workflows/build.yml`** — exports your game on **free GitHub CPU runners** (no GPU).
4. **`docs/`** — verified free-tier quotas and the asset-licensing policy.

> Reality check: no free stack autonomously ships a true AAA game. This produces real, polished, **indie-to-commercial quality** Godot projects. You direct it like a studio head.

---

## Quick start

```bash
git clone https://github.com/pocketagent98-ai/godot-free-game-studio.git
cd godot-free-game-studio

# 1. see what free models are wired up
python tools/model_router.py list

# 2. ask the deep-reasoning model a question (set ONE provider key first)
export GEMINI_API_KEY=...        # or ZAI_API_KEY / NVIDIA_API_KEY / NARA_API_KEY
python tools/model_router.py ask --task deep --prompt "Design the core loop for a Kedarnath survival game"

# 3. pull CC0 assets into the game project
python tools/asset_scout.py sources
python tools/asset_scout.py fetch --source polyhaven --query mountain --type hdris --res 2k --limit 3 --project ./game
python tools/asset_scout.py fetch --source ambientcg --query snow --res 2K --limit 5 --project ./game
```

## The stack

| Layer | Tool | Cost |
|---|---|---|
| Agent | Claude Code / Codex / OpenCode | free |
| Model | Gemini Flash / Gemma, GLM-4.7-Flash, NVIDIA NIM, NaraRouter, OmniRoute | free tiers |
| Engine | Godot 4.7+ (Compatibility renderer) | free |
| Assets | asset_scout.py (Poly Haven, ambientCG, Poly Pizza CC0) | CC0 |
| CI / export | GitHub Actions (CPU runners) | free |

## Model routing — reasoning first

`config/models.json` tags every model with `reasoning: true|false`. The router always prefers a reasoning-capable model for `--task deep`, and degrades gracefully to a standard or fast model when the deep one is unavailable or rate-limited. See `docs/FREE-TIER-QUOTAS.md` for the verified numbers.

## Asset licensing — read this

The asset agent is **CC0-only by default**: no credit, no restrictions, usable in any project, commercial included. CC-BY assets are **excluded unless you pass `--allow-ccby`**, and if you do, the script writes the required attribution into `CREDITS.md`. See `docs/ASSET-LICENSING.md`.

## Export

One project exports to Windows, Linux, macOS, Web/HTML5, Android (APK + AAB) and iOS. Install Godot export templates first; push to trigger the CI build. See `docs/` and the workflow.

## License

MIT — see `LICENSE`.
