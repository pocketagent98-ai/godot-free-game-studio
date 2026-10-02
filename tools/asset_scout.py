#!/usr/bin/env python3
"""
asset-scout  ·  CC0-only free asset fetcher for Godot / Unity / Unreal
=====================================================================
Downloads free, PUBLIC-DOMAIN (CC0) game assets into your project so an AI
agent never has to hand-make every rock, tree and texture.

Policy: CC0-only by default. CC0 means no attribution, no restrictions, usable
in any project including commercial. CC-BY assets are excluded unless you pass
--allow-ccby, and if you do, the required credit is written to CREDITS.md.

Sources (all free):
  polyhaven  · CC0 HDRIs, PBR textures, models   (polyhaven.com)   no key
  ambientcg  · CC0 PBR materials, HDRIs, models  (ambientcg.com)   no key
  polypizza  · CC0 / CC-BY low-poly .glb models  (poly.pizza)      free key

Pure standard library — no pip installs.

Examples
--------
  python asset_scout.py sources
  python asset_scout.py search --source ambientcg --query rock
  python asset_scout.py fetch --source polyhaven --query mountain \
      --type hdris --res 2k --limit 3 --project ./game
"""

import argparse
import io
import json
import os
import sys
import time
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

UA = "asset-scout/1.0 (+CC0 asset fetcher for game projects)"
DEFAULT_OUT = "assets/cc0"

CC0_LIBRARIES = [
    ("Poly Haven",  "https://polyhaven.com",              "CC0", "HDRIs, PBR textures, models (API, no key)"),
    ("ambientCG",   "https://ambientcg.com",              "CC0", "PBR materials, HDRIs, models (API, no key)"),
    ("Kenney",      "https://kenney.nl/assets",           "CC0", "60k+ sprites, 3D models, UI, audio, fonts"),
    ("Quaternius",  "https://quaternius.com",             "CC0", "low-poly characters, nature, kits"),
    ("Poly Pizza",  "https://poly.pizza",                 "CC0/CC-BY", "10k+ low-poly models (free key)"),
    ("OpenGameArt", "https://opengameart.org",            "mixed", "filter to CC0 only"),
    ("Freesound",   "https://freesound.org",              "mixed", "filter to CC0 only"),
]


def http_get(url, headers=None, timeout=90, retries=3):
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, **(headers or {})})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"GET failed: {url} ({last})")


def http_json(url, headers=None):
    return json.loads(http_get(url, headers=headers).decode("utf-8", "replace"))


def human(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f}{unit}" if unit == "B" else f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


def save(url, dest, headers=None):
    dest.parent.mkdir(parents=True, exist_ok=True)
    data = http_get(url, headers=headers)
    dest.write_bytes(data)
    print(f"   saved {dest}  ({human(len(data))})")
    return len(data)


# --- Poly Haven (CC0, no key) --------------------------------------------- #
def polyhaven_search(query, asset_type="hdris", limit=10):
    data = http_json("https://api.polyhaven.com/assets")
    q = query.lower()
    hits = []
    for aid, meta in data.items():
        hay = " ".join([aid, meta.get("name", ""),
                        " ".join(meta.get("tags") or []),
                        " ".join(meta.get("categories") or [])]).lower()
        if q in hay:
            hits.append((aid, meta))
    hits.sort(key=lambda x: -(x[1].get("download_count") or 0))
    return hits[:limit]


def _collect_urls(node, path=()):
    out = []
    if isinstance(node, dict):
        if "url" in node and isinstance(node["url"], str):
            out.append(("/".join(path), node["url"], node.get("size") or 0))
        else:
            for k, v in node.items():
                out.extend(_collect_urls(v, path + (k,)))
    return out


def polyhaven_resolve(aid, res="2k"):
    urls = _collect_urls(http_json(f"https://api.polyhaven.com/files/{aid}"))
    chosen = [u for u in urls if res in u[0].lower()]
    return chosen or urls


# --- ambientCG (CC0, no key) ---------------------------------------------- #
def ambientcg_search(query, asset_type="Material", limit=10):
    params = urllib.parse.urlencode({"type": asset_type, "q": query, "limit": limit,
                                     "sort": "Popular", "include": "downloadData"})
    return http_json(f"https://ambientcg.com/api/v2/full_json?{params}").get("foundAssets", [])


def ambientcg_pick(asset, res="1K"):
    for folder in (asset.get("downloadFolders") or {}).values():
        for fdata in ((folder or {}).get("downloadFiletypeCategories") or {}).values():
            for d in (fdata or {}).get("downloads", []):
                if res.upper() in (d.get("attribute") or "").upper():
                    return d.get("downloadLink"), d.get("fileName")
    for folder in (asset.get("downloadFolders") or {}).values():
        for fdata in ((folder or {}).get("downloadFiletypeCategories") or {}).values():
            for d in (fdata or {}).get("downloads", []):
                return d.get("downloadLink"), d.get("fileName")
    return None, None


# --- Poly Pizza (CC0 / CC-BY, free key) ----------------------------------- #
def polypizza_search(query, limit=5, key=None, allow_ccby=False):
    key = key or os.environ.get("POLY_PIZZA_KEY")
    if not key:
        raise SystemExit("Poly Pizza needs a free API key: https://poly.pizza/settings/api\n"
                         "Pass --key or set POLY_PIZZA_KEY.")
    url = f"https://api.poly.pizza/v1/search/{urllib.parse.quote(query)}?limit={limit}"
    results = http_json(url, headers={"X-Auth-Token": key}).get("results", [])
    if allow_ccby:
        return results
    return [m for m in results if "CC0" in (m.get("Licence") or "")]


# --- commands -------------------------------------------------------------- #
def cmd_sources(_args):
    print("Free CC0 asset libraries:\n")
    for name, url, lic, what in CC0_LIBRARIES:
        print(f"  {name:<12} {lic:<9} {url}")
        print(f"  {'':12} {what}")
    print("\nDefault policy: CC0 only (no attribution, no restrictions).")


def cmd_search(args):
    if args.source == "polyhaven":
        for aid, meta in polyhaven_search(args.query, args.type, args.limit):
            print(f"  {aid:<28} {meta.get('name','')}")
    elif args.source == "ambientcg":
        t = "Material" if args.type == "hdris" else args.type
        for a in ambientcg_search(args.query, t, args.limit):
            print(f"  {a.get('assetId',''):<24} {a.get('displayName','')}")
    elif args.source == "polypizza":
        for m in polypizza_search(args.query, args.limit, args.key, args.allow_ccby):
            print(f"  {m.get('Title',''):<28} {m.get('Licence',''):<8} {m.get('Download','')[:60]}")


def cmd_fetch(args):
    out = Path(args.project or ".") / (args.out or DEFAULT_OUT)
    out.mkdir(parents=True, exist_ok=True)
    credits = []

    if args.source == "polyhaven":
        hits = polyhaven_search(args.query, args.type, args.limit)
        for aid, meta in hits:
            print(f"- {aid}")
            for label, url, _ in polyhaven_resolve(aid, args.res):
                if args.res.lower() not in label.lower() and len(hits) > 1:
                    continue
                ext = Path(urllib.parse.urlparse(url).path).suffix or ".bin"
                save(url, out / f"{aid}{ext}")
                credits.append((aid, "Poly Haven", "CC0", "https://polyhaven.com/a/" + aid))
                break

    elif args.source == "ambientcg":
        t = "Material" if args.type == "hdris" else args.type
        for a in ambientcg_search(args.query, t, args.limit):
            aid = a.get("assetId", "asset")
            link, fname = ambientcg_pick(a, args.res)
            if not link:
                continue
            print(f"- {aid}")
            blob = http_get(link)
            zpath = out / (fname or f"{aid}.zip")
            zpath.write_bytes(blob)
            print(f"   saved {zpath}  ({human(len(blob))})")
            try:
                with zipfile.ZipFile(io.BytesIO(blob)) as z:
                    z.extractall(out / aid)
                print(f"   extracted -> {out / aid}")
            except zipfile.BadZipFile:
                pass
            credits.append((aid, "ambientCG", "CC0", "https://ambientcg.com/a/" + aid))

    elif args.source == "polypizza":
        for m in polypizza_search(args.query, args.limit, args.key, args.allow_ccby):
            title = (m.get("Title") or "model").replace(" ", "_")
            dl = m.get("Download")
            if not dl:
                continue
            print(f"- {title}  [{m.get('Licence','')}]")
            save(dl, out / f"{title}.glb")
            creator = m.get("Creator") or {}
            lic = m.get("Licence") or "CC0"
            if "CC0" in lic:
                credits.append((title, "Poly Pizza", "CC0", m.get("Purl") or "https://poly.pizza"))
            else:
                credits.append((title, "Poly Pizza",
                                f'{lic} - credit "{m.get("Title")}" by {creator.get("Username","")} (poly.pizza)',
                                m.get("Purl") or "https://poly.pizza"))

    if credits:
        cred = out / "CREDITS.md"
        with cred.open("a", encoding="utf-8") as f:
            f.write(f"\n## Fetched {time.strftime('%Y-%m-%d %H:%M')} - {args.source} q='{args.query}'\n")
            for name, src, lic, url in credits:
                f.write(f"- **{name}** - {src} - {lic} - {url}\n")
        print(f"\nCredits written to {cred}")
    print(f"\nDone. {len(credits)} asset(s) into {out}")


def build_parser():
    p = argparse.ArgumentParser(prog="asset-scout",
                                description="Fetch free CC0 game assets into your project.")
    sub = p.add_subparsers(dest="cmd", required=True)

    s0 = sub.add_parser("sources", help="list free CC0 libraries")
    s0.set_defaults(func=cmd_sources)

    def common(sp):
        sp.add_argument("--source", required=True, choices=["polyhaven", "ambientcg", "polypizza"])
        sp.add_argument("--query", required=True)
        sp.add_argument("--limit", type=int, default=5)
        sp.add_argument("--type", default="hdris",
                        help="polyhaven: hdris|textures|models · ambientcg: Material|HDRI|3DModel")
        sp.add_argument("--key", default=None, help="Poly Pizza key (or POLY_PIZZA_KEY)")
        sp.add_argument("--allow-ccby", action="store_true",
                        help="also include CC-BY assets (attribution required, written to CREDITS.md)")

    s = sub.add_parser("search", help="list matching assets")
    common(s); s.set_defaults(func=cmd_search)

    f = sub.add_parser("fetch", help="download matching assets")
    common(f)
    f.add_argument("--res", default="2k", help="1k/2k/4k or 1K/2K/4K")
    f.add_argument("--project", default=".", help="your project root")
    f.add_argument("--out", default=DEFAULT_OUT)
    f.set_defaults(func=cmd_fetch)
    return p


if __name__ == "__main__":
    args = build_parser().parse_args()
    args.func(args)
