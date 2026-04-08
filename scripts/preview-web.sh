#!/usr/bin/env bash
# Export Web preset headlessly, then serve export/web on port 8765 (for Codespaces / Linux).
set -euxo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
GODOT="${ROOT}/_godot_bin/godot"
if [[ ! -x "$GODOT" ]]; then
  echo "Missing $GODOT — run Codespace post-create or: bash .devcontainer/setup.sh" >&2
  exit 1
fi
mkdir -p export/web
OUT="${ROOT}/export/web/index.html"
"$GODOT" --headless --verbose --path "$ROOT" --export-release "Web" "$OUT"
test -f "$OUT"
exec python3 -m http.server 8765 --directory "${ROOT}/export/web"
