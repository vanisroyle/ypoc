#!/usr/bin/env python3
"""Power of Chaos online relay — room-code WebSocket pipe.

Both duel players connect OUTBOUND to this server (works through NAT and
firewalls with no port forwarding). The host gets a 6-char room code, the
guest joins by code, and every binary WebSocket frame is forwarded verbatim
to the other side — the game's LAN packets pass through untouched.

Protocol (text control frames, before linking):
    client -> "HOST"            server -> "ROOM ABCDEF"
    client -> "JOIN ABCDEF"     server -> "GO" (sent to BOTH sides)
                                server -> "ERR <reason>"  (bad code / room full)
After "GO" binary frames are piped both ways until either side disconnects,
which closes the room.

Usage:  python3 relay_server.py [--host 0.0.0.0] [--port 8765]
Needs:  pip install websockets
"""

from __future__ import annotations

import argparse
import asyncio
import secrets
import sys

import websockets

ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"  # no 0/O/1/I/L ambiguity
HELLO_TIMEOUT = 15.0
MAX_FRAME = 1 << 20  # game packets are tiny; cap stray frames at 1 MiB
MAX_ROOMS = 5000

# code -> {"host": ws, "guest": ws | None}
rooms: dict[str, dict] = {}


def new_code() -> str:
    while True:
        code = "".join(secrets.choice(ALPHABET) for _ in range(6))
        if code not in rooms:
            return code


async def close(ws) -> None:
    try:
        await ws.close()
    except Exception:
        pass


async def forward_host(room: dict, code: str, host) -> None:
    """HOST side: emit the room code, then pipe host->guest frames."""
    await host.send("ROOM " + code)
    try:
        async for frame in host:
            guest = room.get("guest")
            if guest is not None and isinstance(frame, bytes):
                await guest.send(frame)
    except websockets.ConnectionClosed:
        pass
    finally:
        rooms.pop(code, None)
        await close(room.get("guest"))


async def forward_guest(code: str, ws) -> None:
    """JOIN side: link the room, then pipe guest->host frames."""
    room = rooms.get(code)
    if room is None:
        await ws.send("ERR no such room")
        return
    if room.get("guest") is not None:
        await ws.send("ERR room full")
        return
    host = room["host"]
    room["guest"] = ws
    try:
        await asyncio.gather(host.send("GO"), ws.send("GO"))
    except websockets.ConnectionClosed:
        rooms.pop(code, None)
        await close(host)
        return
    try:
        async for frame in ws:
            if isinstance(frame, bytes):
                await host.send(frame)
    except websockets.ConnectionClosed:
        pass
    finally:
        rooms.pop(code, None)
        await close(host)


async def handle(ws) -> None:
    try:
        hello = await asyncio.wait_for(ws.recv(), HELLO_TIMEOUT)
    except (asyncio.TimeoutError, websockets.ConnectionClosed):
        return
    if not isinstance(hello, str):
        await ws.send("ERR text hello expected")
        return
    hello = hello.strip()
    if hello == "HOST":
        if len(rooms) >= MAX_ROOMS:
            await ws.send("ERR server full")
            return
        code = new_code()
        rooms[code] = {"host": ws, "guest": None}
        print(f"[relay] room {code} opened", flush=True)
        await forward_host(rooms[code], code, ws)
        print(f"[relay] room {code} closed", flush=True)
    elif hello.upper().startswith("JOIN "):
        code = hello[5:].strip().upper()
        await forward_guest(code, ws)
    else:
        await ws.send("ERR expected HOST or JOIN <code>")


def main() -> int:
    parser = argparse.ArgumentParser(description="Power of Chaos online relay")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()

    async def serve() -> None:
        async with websockets.serve(
            handle, args.host, args.port, max_size=MAX_FRAME, ping_interval=20
        ):
            print(f"[relay] listening on ws://{args.host}:{args.port}", flush=True)
            await asyncio.Future()  # run forever

    try:
        asyncio.run(serve())
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
