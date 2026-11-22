#!/usr/bin/env bash
# Builds the Linux ARM64 handheld port (TrimUI Brick / muOS / Knulli / ROCKNIX /
# PortMaster). Packages the project pck + the official arm64 Godot runtime; no
# engine changes — the game already has native gamepad->mouse support.
# Usage: tools/build_handheld.sh [out_dir]
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT_VER=4.7
GODOT_REL=4.7.2
mkdir -p "${1:-dist/arm64-handheld}"
OUT="$(cd "${1:-dist/arm64-handheld}" && pwd)"
BIN_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VER}-stable/Godot_v${GODOT_VER}-stable_linux.arm64.zip"
# No upstream checksum file exists for editor zips: pinned digest of the
# verified 4.7-stable arm64 runtime (godot-builds release).
RUNTIME_SHA256="db5aa126353a18fd664818e4f1b9cfffaa77e32d4c9af0ea87e8f028a395a1ed"

command -v godot >/dev/null || { echo "need godot ${GODOT_REL} on PATH for --export-pack"; exit 1; }

mkdir -p "$OUT/PoC-Brick/poc"
godot --headless --path game --export-pack "Windows Launcher" "$OUT/PoC-Brick/poc/poc.pck"

tmp=$(mktemp -d)
curl -fsSL "$BIN_URL" -o "$tmp/godot_arm64.zip"
echo "$RUNTIME_SHA256  $tmp/godot_arm64.zip" | sha256sum -c -
unzip -o -q "$tmp/godot_arm64.zip" -d "$tmp"
cp "$tmp/Godot_v${GODOT_VER}-stable_linux.arm64" "$OUT/PoC-Brick/poc/Godot.arm64"
rm -rf "$tmp"

cat > "$OUT/PoC-Brick/PowerOfChaos.sh" <<'SH'
#!/bin/bash
cd "$(dirname "$0")/poc" || exit 1
export XDG_DATA_HOME="$PWD"
chmod +x ./Godot.arm64
exec ./Godot.arm64 --main-pack poc.pck --fullscreen "$@"
SH
chmod +x "$OUT/PoC-Brick/PowerOfChaos.sh"

# Game data is NOT included: copy 'PoC Data/' into poc/ (the zip from the
# ISO import) — Konami assets never enter the repo or releases.
echo "Done: $OUT/PoC-Brick — drop PoC Data/ into poc/ before copying to the device"
