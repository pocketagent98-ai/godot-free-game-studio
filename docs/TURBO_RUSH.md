# Turbo Rush — design, economy and monetization

A 3D **level-based** arcade racing game for Android and WebGL. Not an endless
runner. Built in Godot 4.7+ with the Compatibility renderer (runs on the widest
hardware, including software rendering and the browser).

## Content (all generated, nothing hand-authored)

| Content | Count | How |
|---|---|---|
| Levels | 1000 | procedural tracks, seeded per level (`GameData.levels`) |
| Cars | 120 | data-driven stats across 5 tiers, 4 rarities |
| Paints | 120 | 6 finishes (gloss, metallic, matte, pearl, chrome, neon) |
| Wheels | 72 | 12 styles × sizes, rim colours |
| AI racers per race | 5 (+ player = 6) | skill profiles, look-ahead, mistakes, recovery |

## Race & rewards

A race has **6 cars**. Finish position pays:

| Position | Coins | Diamonds |
|---|---|---|
| 1st | 250 | 3 |
| 2nd | 200 | 2 |
| 3rd | 150 | 1 |
| 4th | 100 | 0 |
| 5th | 70 | 0 |
| 6th | 50 | 0 |

Milestone levels (every 10th) can add **+2 diamonds** for a win. Diamonds are
**deliberately scarce** — they are the premium currency and the main faucet is
daily tasks, never ordinary wins.

## Currencies & spending

- **Coins** — earned every race. Buy cars, common paints, common wheels, upgrades.
- **Diamonds** — rare. Buy premium paints (pearl/chrome/neon) and premium wheels.
- **Upgrades** — 5 levels per car, +6% speed and acceleration each.
- **No in-app purchases.** There is no store, no real money, no "remove ads"
  purchase. All progression is earned.

## Daily tasks (the diamond faucet)

Three tasks refresh each day from a pool: finish races, win a race, reach the
podium, use nitro, drift. Each pays 1–3 diamonds and some coins. A player can
also watch a rewarded ad for **+1 diamond, capped at 5 per day** so diamonds
stay scarce.

## Ad placements — and why

The game is **ad-supported only**. Every placement is at a natural break; none
interrupts active driving. This is the industry pattern that maximises ARPDAU
without hurting retention.

| # | Format | Where | Why |
|---|---|---|---|
| 1 | **Rewarded** | Pre-race screen → unlock a Nitro booster | Opt-in, high-intent; rewarded video has the highest eCPM of any format and *improves* retention because the player chooses it |
| 2 | **Rewarded** | Results screen → **double the coins** you just won | The single best-performing rewarded placement: the player has just earned something and wants more |
| 3 | **Rewarded** | Daily tasks → +1 diamond (cap 5/day) | Converts the diamond scarcity into an opt-in view without flooding the economy |
| 4 | **Interstitial** | Results screen, but only every **3rd** completed level | Level-complete is a natural break; capping frequency protects D1/D7 retention |
| 5 | **Banner** | Main menu, garage, level select | Low eCPM but passive fill, and never over gameplay |

Guardrails already coded in `Ads.gd`:
- **First-ad delay of 75 seconds** — no ad before the player has engaged.
- **Minimum 2 minutes between interstitials**, and only every 3 levels.
- **No ads during active gameplay**, ever.
- Rewarded rewards are granted only inside the reward callback.

### Why this earns

Rewarded video is the highest-eCPM format in mobile gaming (commonly ~$15–$50
in Tier-1 markets), interstitials next (~$10–$25 Tier-1), banners last. Because
this game is **ad-only** with no IAP, the two rewarded placements above are the
revenue engine: they fire on every race, are opt-in, and stack with the
interstitial. Keeping the frequency caps in place is what lets those placements
keep working session after session instead of burning the player out.

> Guidance, not a guarantee: real earnings depend on your region mix, session
> length, retention and mediation setup. Track ARPDAU and D1/D7 retention
> weekly and tune the caps — never the other way around.

## Wiring real ads

1. Install the **Poing Studios AdMob plugin** (Godot Asset Store → search
   "AdMob", publisher *Poing Studios*), enable it, and download the Android
   library via **Project → Tools → AdMob Manager → Android**.
2. Put your AdMob **App ID** in the AdMob project settings.
3. Replace the test unit IDs in `src/autoload/Ads.gd` with your own rewarded and
   interstitial unit IDs.
4. Export with **Use Gradle Build** for Android.

The current IDs in `Ads.gd` are Google's official **test** IDs, which is exactly
what you want until the app is live (using live ads in testing can get an AdMob
account suspended).

For **WebGL**, `Ads.gd` looks for a `TurboRushAds` JavaScript bridge
(`showRewarded(kind)`) and falls back to a no-op/mock so the web build stays
fully playable without ads.

## Export

- **Android APK**: preset `Android` → `build/turbo_rush.apk`
- **WebGL / HTML5**: preset `Web` → `build/web/index.html`

Both are produced by `.github/workflows/build.yml` on every push.

## Offline-first

Racing, progression, the garage and the economy are fully offline. Only ads and
the optional daily refresh touch the network, and the game never blocks on them.
