# Third-party notices

## Turbo Rush

Turbo Rush ships **no third-party art, audio or model assets**. Everything in
the game is generated at runtime:

- Cars, paints, wheels, levels and AI profiles — procedural, in
  `game/src/autoload/GameData.gd`.
- Track geometry, barriers and scenery — procedural, in
  `game/src/race/TrackBuilder.gd`.
- Sound effects — synthesised tones, in `game/src/autoload/Audio.gd`.

Because nothing third-party ships, there is nothing to attribute and no licence
obligation for the game content itself.

### When you add real assets

If you drop in the CC0 asset packs (Kenney, Poly Haven, ambientCG, Quaternius,
Poly Pizza), fetch them with `tools/asset_scout.py`. It is **CC0-only by
default** — no attribution required. If you ever include a CC-BY asset, the
script records the required credit in `CREDITS.md`; keep that, and surface the
credits in-game (a Credits screen). Do not conceal a required credit.

### Engine and plugins

- **Godot Engine** — MIT. https://godotengine.org
- **Godot AdMob Plugin (Poing Studios)** — optional, MIT. If you install it for
  Android ads, its licence and Google's Google Mobile Ads SDK terms apply.

## Tooling in this repository

- `tools/asset_scout.py`, `tools/model_router.py`, the CI workflow and the docs
  are MIT (see `LICENSE`).
- Poly Haven API usage requires noting that assets came from Poly Haven.
