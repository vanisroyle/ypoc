#!/usr/bin/env bash
# Exporta la version web/PWA del juego (game/dist/web/):
#   - mete "PoC Data/resources" dentro del pck como res://webdata (ver paths.gd)
#   - genera los iconos PWA desde assets/icons/launcher.svg
#   - deja _headers (COOP/COEP, requerido por SharedArrayBuffer) en la salida
# Requiere: Godot 4.7.2 con plantillas de exportacion web, ImageMagick.
set -euo pipefail

GODOT="${GODOT:-/tmp/Godot_v4.7.2-stable_linux.x86_64}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="$ROOT/PoC Data/resources"
OUT="$ROOT/dist/web"

[ -d "$DATA" ] || { echo "falta $DATA" >&2; exit 1; }

# 1. Iconos PWA (rasteriza el SVG del launcher).
mkdir -p "$ROOT/game/web_icons"
"$GODOT" --headless --path "$ROOT/game" --script res://_svg2png.gd -- \
	--src=res://assets/icons/launcher.svg \
	--out="$ROOT/game/web_icons/icon" --sizes=144,180,512 >/dev/null 2>&1 || {
	echo "aviso: no se generaron iconos; comprueba _svg2png.gd" >&2; }

# 2. Recursos dentro del arbol del proyecto (solo para exportar).
rm -rf "$ROOT/game/webdata"
cp -al "$DATA" "$ROOT/game/webdata" 2>/dev/null || cp -r "$DATA" "$ROOT/game/webdata"

cleanup() { rm -rf "$ROOT/game/webdata"; }
trap cleanup EXIT

# 3. Exportacion web.
mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT/game" --export-release "Web" "$OUT/index.html"

# 4. Cabeceras para Cloudflare Pages / Netlify (aislamiento cross-origin).
cat > "$OUT/_headers" <<'HDR'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Service-Worker-Allowed: /
HDR

echo "web build en $OUT"
