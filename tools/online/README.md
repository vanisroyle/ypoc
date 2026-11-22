# Power of Chaos — online relay

Tiny room-code relay for internet multiplayer. Both players connect outbound to
this server, so no port forwarding or VPN is needed: the host gets a 6-char
room code, the guest joins by code, and the relay pipes the game's LAN packets
between them (it never sees game content — only opaque binary frames).

## Run it yourself (any machine with a public address)

```sh
pip install -r requirements.txt
python3 relay_server.py --host 0.0.0.0 --port 8765
```

Point the game at it in `PoC Data/system.json`:

```json
{ "online": { "relay": "ws://YOUR_SERVER:8765" } }
```

## Free hosting option A — Cloudflare Workers (`worker/`)

Serverless, zero idle cost, free TLS and global edge. SQLite-backed Durable
Objects are on the Workers **Free** plan (100k requests/day) — a duel room is
one object that only counts compute while packets flow.

```sh
cd worker
npx wrangler login          # free Cloudflare account
npx wrangler deploy
# relay URL: wss://poc-online-relay.<your-account>.workers.dev
```

Test it before deploying — `wrangler dev` runs the Worker and Durable
Objects locally, no account needed:

```sh
cd worker
npx wrangler dev --port 8787
# game config: { "online": { "relay": "ws://localhost:8787" } }
# verified: two game instances link, exchange packets, close cleanly
```

The game client sends `?op=host` / `?op=join&code=…` in the URL so the Worker
can route to the room object before the WebSocket upgrade; the text control
frames (`HOST` / `JOIN` / `ROOM` / `GO` / `ERR`) are the same as the Python
relay, so the game works against either backend unchanged.

## Free hosting option B — Fly.io with the Go relay (`go/`, recommended)

`go/relay.go` is the same relay as a single static binary — ~15 MB distroless
image, a few MB RAM, smallest attack surface. Easiest way to run it free:

```sh
cd go
fly launch --no-deploy          # picks up the Dockerfile
# fly.toml: services.internal_port = 8765
fly deploy
# relay URL: wss://<your-app>.fly.dev
```

A `shared-cpu-1x · 256MB` machine is plenty (hundreds of concurrent duels).

## Free hosting option C — run `relay_server.py` anywhere

Any always-on free tier works — the script needs only Python + websockets.

**Render** free web service: new Web Service → this directory →
`pip install -r requirements.txt` / `python3 relay_server.py --port $PORT`.
Render gives you `wss://<app>.onrender.com` (free tier idles; first duel of the
day takes ~30 s to wake).

**Oracle Cloud Always Free VM**: copy `relay_server.py`, `pip install
websockets`, open TCP 8765, run under tmux/systemd. URL: `ws://<ip>:8765`.

## In the game

LAN Duel → name → click **MODE** to switch to ONLINE → Host shows a room code
to share; Guest types it and presses Enter. Everything after (deck sync, duel,
disconnect handling) is the same as LAN play.
