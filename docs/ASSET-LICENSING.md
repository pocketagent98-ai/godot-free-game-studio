# Asset licensing policy

## Default: CC0 only

The asset agent (`tools/asset_scout.py`) is **CC0-only by default**.

**CC0** (Creative Commons Zero) = public domain dedication. You can use the
asset in any project, including commercial, **with no attribution and no
restrictions**. This is what "completely free, no credit" means in practice.

CC0 libraries used:
- **Poly Haven** — HDRIs, PBR textures, models (API, no key)
- **ambientCG** — PBR materials, HDRIs, models (API, no key)
- **Kenney** — 60k+ sprites, 3D models, UI, audio, fonts
- **Quaternius** — low-poly characters, nature, kits
- **Poly Pizza** — low-poly models (filtered to CC0 by the agent)
- **OpenGameArt / Freesound** — filter to CC0 only

## CC-BY and other licences

Some assets (e.g. a few Poly Pizza models) are **CC-BY**: free to use, but the
licence **requires you to credit the creator**. The agent excludes these unless
you pass `--allow-ccby`, and when you do it writes the required line into
`assets/cc0/CREDITS.md`.

**We do not conceal required attribution.** Hiding a credit where users cannot
find it violates the licence and is not something this project will do. The
correct, industry-standard approach is:

1. Keep a `THIRD-PARTY-NOTICES.md` (or the auto-written `CREDITS.md`) in the repo, and
2. show the credits in-game — a **Credits** screen reachable from the main menu.

That satisfies the licence and is normal practice for shipped games.

## Rule of thumb

- Want zero obligations? Use **CC0 only**. The default already does this.
- Used a CC-BY asset? Credit it, visibly. The agent records it for you.

## Attribution for the tooling itself

- Poly Haven API: when you *use the live API*, make it clear assets came from Poly Haven.
- Everything else in this repo is MIT (see `LICENSE`).
