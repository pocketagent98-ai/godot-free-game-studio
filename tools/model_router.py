#!/usr/bin/env python3
"""
model-router  ·  reasoning-first router across free LLM providers
=================================================================
One interface over Gemini, z.ai GLM Flash, NVIDIA NIM, NaraRouter and
OmniRoute. It prefers reasoning-capable models for deep tasks and falls back
automatically when a provider is missing, rate-limited or errors.

Stdlib only. Keys come from environment variables — never hardcode them.

  python model_router.py list
  python model_router.py ask --task deep --prompt "Design a survival loop"
  python model_router.py ask --task fast --prompt "classify: rock|tree|snow"
  python model_router.py ask --provider zai --model glm-4.7-flash --prompt "hi"
"""

import argparse
import json
import os
import sys
import urllib.request
from pathlib import Path

CONFIG = Path(__file__).resolve().parent.parent / "config" / "models.json"


def load():
    return json.loads(CONFIG.read_text(encoding="utf-8"))


def available(cfg):
    """Providers whose API key env var is set (omniroute needs a local key too)."""
    out = []
    for p in cfg["providers"]:
        if os.environ.get(p["api_key_env"]):
            out.append(p)
    return out


def candidates(cfg, task, provider=None, model=None):
    """Return an ordered list of (provider, model) to try, reasoning-first."""
    order = {"deep": ["deep", "standard", "fast"],
             "standard": ["standard", "fast"],
             "fast": ["fast"]}[task]
    picks = []
    for p in cfg["providers"]:
        if provider and p["id"] != provider:
            continue
        if not os.environ.get(p["api_key_env"]):
            continue
        models = p["models"]
        if model:
            models = [m for m in models if m["id"] == model] or models
        # reasoning models first within a tier
        for tier in order:
            tier_models = [m for m in models if m.get("tier") == tier]
            tier_models.sort(key=lambda m: not m.get("reasoning", False))
            for m in tier_models:
                picks.append((p, m))
    return picks


def call(provider, model, prompt, system=None, max_tokens=2048):
    url = provider["base_url"].rstrip("/") + "/chat/completions"
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})
    body = {"model": model["id"], "messages": messages, "max_tokens": max_tokens}
    # reasoning effort where the model advertises support
    if model.get("reasoning") and model.get("thinking_param") == "reasoning_effort":
        body["reasoning_effort"] = "high"
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json",
                 "Authorization": f"Bearer {os.environ[provider['api_key_env']]}"})
    with urllib.request.urlopen(req, timeout=180) as r:
        data = json.loads(r.read().decode("utf-8", "replace"))
    return data["choices"][0]["message"]["content"]


def cmd_list(_args):
    cfg = load()
    live = {p["id"] for p in available(cfg)}
    for p in cfg["providers"]:
        mark = "KEY SET" if p["id"] in live else "no key"
        print(f"\n{p['id']}  [{mark}]  {p['base_url']}")
        print(f"   {p['notes']}")
        for m in p["models"]:
            r = "reasoning" if m.get("reasoning") else "-"
            print(f"     {m['id']:<46} tier={m['tier']:<8} {r}")


def cmd_ask(args):
    cfg = load()
    picks = candidates(cfg, args.task, args.provider, args.model)
    if not picks:
        sys.exit("No provider key found. Set one of: GEMINI_API_KEY, ZAI_API_KEY, "
                 "NVIDIA_API_KEY, NARA_API_KEY, OMNIROUTE_KEY")
    last = None
    for provider, model in picks:
        tag = "reasoning" if model.get("reasoning") else "standard"
        try:
            print(f"[try] {provider['id']}/{model['id']} ({tag})", file=sys.stderr)
            print(call(provider, model, args.prompt, args.system, args.max_tokens))
            return
        except Exception as e:  # noqa: BLE001
            last = f"{provider['id']}/{model['id']}: {e}"
            print(f"[fail] {last}", file=sys.stderr)
    sys.exit(f"All candidates failed. Last: {last}")


def main():
    p = argparse.ArgumentParser(prog="model-router",
                                description="Reasoning-first router across free LLM providers.")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("list").set_defaults(func=cmd_list)

    a = sub.add_parser("ask")
    a.add_argument("--task", choices=["deep", "standard", "fast"], default="deep")
    a.add_argument("--prompt", required=True)
    a.add_argument("--system", default=None)
    a.add_argument("--provider", default=None)
    a.add_argument("--model", default=None)
    a.add_argument("--max-tokens", type=int, default=2048, dest="max_tokens")
    a.set_defaults(func=cmd_ask)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
