# AGENTS.md — instructions for your coding agent

You are working inside **Godot Free Game Studio**. Follow these rules.

## Project shape
- `game/` — the Godot 4.7+ project. Renderer is **Compatibility** (works on CPU / software rendering / web).
- `tools/asset_scout.py` — fetch **CC0** assets. Never introduce non-CC0 assets without explicit approval.
- `tools/model_router.py` — route LLM calls. Prefer reasoning-capable models for design/architecture.
- `config/models.json` — the model registry (reasoning flags, quotas).
- `docs/` — quotas and licensing policy.

## Rules
1. **Reasoning first.** For planning, architecture, debugging and design, use a `reasoning: true` model via `model_router.py --task deep`. Only drop to standard/fast models for mechanical edits.
2. **CC0 only.** Get art through `asset_scout.py`. Do not add assets whose licence requires attribution unless the user explicitly approves, and if approved, append the credit to `game/assets/cc0/CREDITS.md` and to `THIRD-PARTY-NOTICES.md`.
3. **Never conceal required attribution.** If an asset's licence requires credit, it goes in a discoverable place (CREDITS / in-game Credits screen). Do not hide it in a place users cannot find.
4. **CPU-only.** Assume no GPU. Do not add steps that require local 3D generation; use CC0 assets or a free cloud GPU notebook.
5. **Compatibility renderer.** Keep the project runnable with `gl_compatibility`.
6. **Quality gates.** After each feature: parse-check scripts (`godot --headless --check-only`), run the scene, fix errors, then commit.
7. **Small diffs.** Keep code minimal and readable (think senior dev). No dead code, no unused nodes.
8. **Commits.** One logical change per commit; clear messages.

## Godot conventions
- GDScript, typed where practical, `snake_case` files, `PascalCase` nodes.
- Scenes under `game/scenes/`, scripts under `game/src/`, assets under `game/assets/`.
- Prefer signals over direct node paths across scenes.

## Definition of done
- Project opens in Godot 4.7+ with no errors.
- The main scene runs and is playable.
- All new assets are CC0 (or approved + credited).
- CI (`build.yml`) passes and produces a Windows + Web build artifact.
