# Free-tier quotas — verified 2 Oct 2026

Numbers change without notice. Your provider console is the only authority.
Treat these as planning figures.

## Gemini (Google AI Studio) — free tier, no card
| Model | RPM | RPD | Notes |
|---|---|---|---|
| Gemini Flash-Lite (3.x) | ~15 | ~500–1,000 | most generous on requests |
| Gemini Flash (3.x) | ~10–15 | ~20–1,500 (varies) | reasoning + thinking levels |
| Gemma 4 (26B / 31B) | ~15 | ~1,500 | open-weight; **no TPM cap** |

- Pro models are **paid-only** on the free tier.
- Free tier: input and output tokens are $0 on eligible models.
- Limits are **per project**, not per key. RPD resets at midnight Pacific.
- Splitting work across Flash-Lite + Gemma gives you separate daily buckets.

## z.ai (Zhipu GLM) — permanently $0 models
| Model | Cost | Notes |
|---|---|---|
| GLM-4.7-Flash | $0 in/out | 30B-A3B MoE, 200K context, MIT open weights |
| GLM-4.5-Flash | $0 in/out | fast general chat |
| GLM-4.6V-Flash | $0 in/out | vision-language (reads images) |

- **Not** RPM/TPM limited — limited by **concurrency** (in-flight requests).
- Third-party trackers report ~1 req/sec, ~1,000 req/day, but z.ai publishes no number.
- Requests with **>8K context** are throttled to ~1% of concurrency during platform stress.
- Endpoint is OpenAI-compatible: `https://api.z.ai/api/paas/v4`.

## NVIDIA NIM (build.nvidia.com) — free developer tier
- **~40 RPM, account-wide** — shared across *every* model on your one `nvapi-` key (community-observed; NVIDIA publishes no table).
- Historical 1,000–5,000 signup credits; now a per-account rate limit.
- Exceeding it returns **429 with `Retry-After`**.
- Reasoning models available (Nemotron family). Best used for a *burst*, not a load-bearing loop.

## NaraRouter (router.bynara.id) — free plan
- **~5,000,000 tokens/day, ~10 RPM**, no credit card (Google sign-in, 18+).
- Free models include: Agnes 2.5/3 Flash, Jev, Laguna S 2.1, Ling 3.0 Flash (Free), LongCat 2.5, **Nemotron 3 Super / Ultra / Lightning Free**, Space Bunny Alpha, MiMo Free.
- OpenAI-compatible; supports **combos** (model fallback chains) and a **reasoning flag**.
- Free quota resets daily ~00:00 UTC.

## OmniRoute — MIT self-hosted gateway (optional)
- One local endpoint `http://localhost:20128/v1` fronting 352 providers (150+ free), with auto-fallback and token compression.
- Its API key is generated in **its own dashboard** — not obtainable from outside.
- **You do not need it.** With Gemini + z.ai + NVIDIA + NaraRouter you already have a large free budget. Include it only if you want one local endpoint for everything.

## Recommended routing (reasoning-first)
| Task | Preferred | Fallback |
|---|---|---|
| Deep (design, architecture, debugging) | Gemini Flash (thinking) / Nemotron Ultra (NIM/Nara) | GLM-4.7-Flash, Gemma 4 |
| Standard (code, content) | GLM-4.7-Flash, Gemma 4 31B | Gemini Flash-Lite |
| Fast (classify, extract, route) | GLM-4.5-Flash, Nemotron Lightning Free | Gemini Flash-Lite |

`tools/model_router.py --task deep` implements exactly this, with automatic fallback.
