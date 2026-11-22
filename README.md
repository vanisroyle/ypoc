<p align="center">
  <img src="game/assets/icons/launcher.svg" width="112" height="112" alt="Power of Chaos icon">
</p>

# Yu-Gi-Oh! Power of Chaos — Remake

A Godot reimplementation of **Yugi the Destiny, Kaiba the Revenge and Joey the Passion** combined into **one game**: a single menu, one card collection (1,113 obtainable cards) and a campaign that runs through all three rivals in order.

**Play it on the web:** https://power-of-chaos.pages.dev — works as an installable PWA on iOS 16+ (Safari → Share → Add to Home Screen) and in any modern desktop browser.

## Contents

- [What the game is](#what-the-game-is)
- [Platforms](#platforms)
- [Game data](#game-data)
- [Playing](#playing)
- [Multiplayer](#multiplayer)
- [Building](#building)
- [Project status and notices](#project-status-and-notices)

## What the game is

The original trilogy shipped as three separate Windows programs, each with its own
card pool, its own save and its own menus. This remake reimplements the three duel
engines in Godot and unifies the shell around them:

- **One menu** (styled after Joey's): Duel · Deck Construction · Card List · Options · Exit.
- **One campaign**: beat Yugi to unlock Kaiba, beat Kaiba to unlock Joey. Defeated
  rivals stay open for rematches, and Joey keeps his seven AI levels.
- **One collection**: all 1,113 cards obtainable across the three games feed a
  single shared collection and the deck-building trunk.
- **Three decks**: each rival is dueled with the deck of *their* game — every
  engine only runs the card pool it actually supports. Deck Construction opens
  the real editor directly (trunk, drag & drop, filters, sort, import/export)
  with YUGI/KAIBA/JOEY tabs to switch decks.

"Remake" means the engine is rebuilt; card art, voices and music come from your
own copy of the games.

## Platforms

| Platform | How | Notes |
| --- | --- | --- |
| **Windows** | `PowerOfChaos.exe` + `PoC Data/` folder | Keep the two together — saves and resources are portable. |
| **Web / PWA** | https://power-of-chaos.pages.dev | Static Cloudflare Pages deploy; card packs download once (~320 MB) and are cached offline by the service worker. |
| **TrimUI Brick / ARM64 handhelds** | `tools/build_handheld.sh` | muOS / Knulli / ROCKNIX package with gamepad-driven cursor. |
| **Nintendo Switch** | `switch` branch | `.nro` homebrew + installable NSP forwarder, built with the godot-switch-nro port. |

The engine runs the OpenGL compatibility renderer; the Switch build ships both
GL and Vulkan backends.

## Game data

No original game data is in this repository or in any distributed build — you
supply your own copy. The launcher/import flow converts the original `Data.dat`,
`Voice.dat` and `Region.dat` into WebP images, OGG audio and engine tables under
**`PoC Data/resources/`**. One imported game is enough to play; import all three
for the full collection.

| Files | Location |
| --- | --- |
| Converted resources and engine data | `PoC Data/resources/` |
| Saves, decks, collection, settings | `PoC Data/saves/`, `PoC Data/system.json` |
| Bundled conversion tools | `PoC Data/tools/` |

## Playing

- **Duel** — pick an unlocked rival; toggle **Match mode** for best-of-3 sets
  with a side deck, open **LAN / Online Duel**, or watch saved **Replays**.
- **Deck Construction** — full editor (trunk, type filters, sorting, side/fusion
  zones, .ydc import/export). Tabs switch between the three game decks;
  **D** cycles decks on keyboard.
- **Card List** — the whole obtainable collection with per-card details.
- **Options** — volume, card set, forbidden cards, screen mode.
- Keyboard, mouse and gamepad are supported (gamepad drives the hand cursor;
  A = click). Shortcuts inside the editor: **Tab** bag/deck, **S** side deck,
  **F** filter, **O** sort, **W** expand collection, **D** switch deck.

## Multiplayer

Two ways to duel another player:

- **LAN** — direct connection on the local network (replaces the original
  DirectPlay dependency), plus an ONLINE mode for internet play.
- **Online relay** — a tiny room-code WebSocket relay in `tools/online/`: the
  host creates a **public** room (guests see it in a list) or a **private** room
  (join by 6-char code). The relay only pipes opaque game frames.
  - `tools/online/relay_server.py` — Python reference server.
  - `tools/online/go/` — hardened Go server (connection caps, per-IP limits,
    room TTL, optional shared key).
  - `tools/online/worker/` — Cloudflare Worker + Durable Objects version
    (serverless, free tier).

Point the game at your relay in `PoC Data/system.json`:

```json
{ "online": { "relay": "ws://your-server:8765" } }
```

See `tools/online/README.md` for deployment details.

## Building

Requirements: **Godot 4.7.2** and **Python 3.12+**.

```powershell
git clone https://github.com/vanisroyle/ypoc.git
cd ypoc
python -m pip install ./tools
godot --editor --path game
```

| Target | Script |
| --- | --- |
| Windows exe | `tools/build_windows.py` |
| Web/PWA export (`dist/web/`) | `tools/build_web.sh` |
| ARM64 handheld package | `tools/build_handheld.sh` |

The web build splits card data into ~20 MB packs (`packs/*.pck`) downloaded at
boot with an in-game progress screen, and splits `index.wasm` into parts
streamed back together by a fetch shim — every file stays under Cloudflare
Pages' 25 MiB limit, so a deploy is plain static hosting (`dist/cf-deploy`
contains a ready `wrangler.toml`, `deploy.bat` and `_headers` with the required
COOP/COEP isolation).

## Project status and notices

This is an independent, unofficial project — not affiliated with or endorsed by
Konami or the rights holders of the original games. Original assets and
trademarks remain with their owners; they are read only from copies each player
provides.

The source includes work derived through reverse engineering for
interoperability. Third-party components retain their own licenses — see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Release history lives in
[RELEASE_NOTES.md](RELEASE_NOTES.md).
