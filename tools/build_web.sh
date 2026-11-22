#!/usr/bin/env bash
# Exporta la version web/PWA del juego (game/dist/web/):
#   - trocea "PoC Data/resources" en packs/*.pck de ~20 MB que el juego descarga
#     al arrancar (ver boot.gd); el pck principal queda pequeno
#   - trocea index.wasm en wasm/*.part de ~20 MB (limite de 25 MB de Cloudflare
#     Pages); un shim en index.html lo reensambla en streaming via fetch()
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

# 2. Exportacion web (sin webdata: viaja en packs/ aparte).
mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT/game" --export-release "Web" "$OUT/index.html"

# 3. Packs descargables de ~20 MB (limite de Cloudflare Pages).
rm -rf "$OUT/packs"
"$GODOT" --headless --path "$ROOT/game" --script res://_mkpacks.gd -- \
	--src="$DATA" --out="$OUT/packs"

# 4. Cabeceras para Cloudflare Pages / Netlify (aislamiento cross-origin).
cat > "$OUT/_headers" <<'HDR'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Service-Worker-Allowed: /
HDR

# 5. index.wasm troceado: no cabe en ningun estatico de Pages ni en un
#    upload de wrangler (300 MB si, 25 MB por fichero no). El shim inyectado
#    intercepta fetch("index.wasm") y devuelve un Response en streaming con
#    las partes concatenadas; el motor no nota la diferencia.
python3 - "$OUT" <<'PYEOF'
import json, os, sys

out = sys.argv[1]
wasm_path = os.path.join(out, "index.wasm")
parts_dir = os.path.join(out, "wasm")
os.makedirs(parts_dir, exist_ok=True)

data = open(wasm_path, "rb").read()
chunk = 20 * 1024 * 1024
names = []
for off in range(0, len(data), chunk):
    name = "index.wasm.part%d" % len(names)
    with open(os.path.join(parts_dir, name), "wb") as f:
        f.write(data[off:off + chunk])
    names.append(name)
with open(os.path.join(parts_dir, "parts.json"), "w") as f:
    json.dump({"parts": names, "bytes": len(data)}, f)
os.remove(wasm_path)

shim = """<script>
// index.wasm viaja en wasm/*.part (limite de 25 MB por fichero en Cloudflare
// Pages). Este shim reensambla las partes en streaming cuando el motor hace
// fetch("index.wasm"); el compila WebAssembly.instantiateStreaming igual.
(function () {
\tconst real = window.fetch.bind(window);
\twindow.fetch = function (input, init) {
\t\tconst url = String(input && input.url ? input.url : input).split("?")[0];
\t\tif (!url.endsWith("/index.wasm") && url !== "index.wasm") {
\t\t\treturn real(input, init);
\t\t}
\t\treturn real("wasm/parts.json").then(function (r) { return r.json(); }).then(function (m) {
\t\t\tlet i = 0;
\t\t\tconst stream = new ReadableStream({
\t\t\t\tpull: function (ctrl) {
\t\t\t\t\tif (i >= m.parts.length) { ctrl.close(); return; }
\t\t\t\t\treturn real("wasm/" + m.parts[i++]).then(function (r) {
\t\t\t\t\t\treturn r.arrayBuffer();
\t\t\t\t\t}).then(function (buf) {
\t\t\t\t\t\tctrl.enqueue(new Uint8Array(buf));
\t\t\t\t\t});
\t\t\t\t}
\t\t\t});
\t\t\treturn new Response(stream, {
\t\t\t\theaders: { "Content-Type": "application/wasm", "Content-Length": String(m.bytes) }
\t\t\t});
\t\t});
\t};
})();
</script>
"""
html_path = os.path.join(out, "index.html")
html = open(html_path, encoding="utf-8").read()
assert "</head>" in html, "index.html sin </head>"
html = html.replace("</head>", shim + "\t</head>", 1)
open(html_path, "w", encoding="utf-8").write(html)
print("wasm troceado: %d partes, %d bytes" % (len(names), len(data)))
PYEOF

echo "web build en $OUT"
