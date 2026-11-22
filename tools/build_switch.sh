#!/usr/bin/env bash
# Builds the Nintendo Switch homebrew package (.nro) for Power of Chaos.
#
# Uses the godot-switch-nro fork (Godot 4.7.2 + Switch platform, OpenGL ES /
# gl_compatibility backend) which produces an Atmosphere .nro + .pck.
#
# Requirements: Linux, Docker (running), Python 3 + Pillow, git, ~25 GB free.
# A Godot 4.7.2 editor binary is only needed to export the .pck.
#
# Usage:
#   tools/build_switch.sh [out-dir] [godot-editor-path]
#     out-dir            output dir, receives switch/power-of-chaos/ (default: dist/switch)
#     godot-editor-path  Godot 4.7.2 editor binary (default: $GODOT or `godot` on PATH)
#
# Output layout (copy `switch/` to the SD card root):
#   sdmc:/switch/power-of-chaos/power-of-chaos.nro
#   sdmc:/switch/power-of-chaos/power-of-chaos.pck
#   sdmc:/switch/power-of-chaos/PoC Data/   <- NOT included: copy it yourself
set -euo pipefail
cd "$(dirname "$0")/.."

GSN_COMMIT="3f7bb1ac4e987b359faafed23ddaed0fd244bb2e"
GSN_URL="https://github.com/calosguilherme/godot-switch-nro.git"
GSN_DIR="${GSN_DIR:-$HOME/godot-switch-nro}"

OUT="${1:-dist/switch}"
GODOT="${2:-${GODOT:-godot}}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

command -v docker >/dev/null || { echo "need docker"; exit 1; }
python3 -c 'import PIL' 2>/dev/null || { echo "need pillow: pip install pillow"; exit 1; }

if [ ! -d "$GSN_DIR/.git" ]; then
    git clone "$GSN_URL" "$GSN_DIR"
fi
git -C "$GSN_DIR" fetch -q "$GSN_URL" "$GSN_COMMIT" || true
git -C "$GSN_DIR" checkout -q "$GSN_COMMIT"

# One-time prep: Godot 4.7.2 source + patches (+ NVK image if Vulkan wanted).
python3 "$GSN_DIR/gsn.py" preparar --sem-vulkan

# Game package: engine build (incremental), pck export, elf2nro, SD layout.
python3 "$GSN_DIR/gsn.py" gerar "$PWD/game" \
    --godot "$GODOT" --sem-vulkan --saida "$OUT"

cat <<EOF

Done. Copy $OUT/switch/power-of-chaos/ to the SD card root
(-> sdmc:/switch/power-of-chaos/) and copy the "PoC Data/" folder
into it. Launch from hbmenu in title mode (hold R on a game).
EOF
