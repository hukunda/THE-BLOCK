#!/usr/bin/env bash
# One-time setup for Codespaces / VS Code Dev Containers: Linux Godot + Web templates (matches CI).
set -euxo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if command -v sudo >/dev/null 2>&1 && [[ "$(id -u)" != "0" ]]; then
  SUDO=(sudo)
else
  SUDO=()
fi

"${SUDO[@]}" apt-get update
"${SUDO[@]}" DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl unzip \
  libfontconfig1 libgl1 libx11-6 libxcursor1 libxinerama1 libxi6 libxrandr2

mkdir -p _godot_bin
if [[ ! -x _godot_bin/godot ]]; then
  curl -sL -o /tmp/godot.zip \
    "https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
  unzip -q /tmp/godot.zip -d _godot_bin
  chmod +x _godot_bin/Godot_v4.3-stable_linux.x86_64
  mv _godot_bin/Godot_v4.3-stable_linux.x86_64 _godot_bin/godot
fi

TPL="${HOME}/.local/share/godot/export_templates"
mkdir -p "$TPL"
if [[ ! -f "$TPL/4.3.stable/web_nothreads_release.zip" && ! -f "$TPL/web_nothreads_release.zip" ]]; then
  curl -sL -o /tmp/templates.tpz \
    "https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz"
  unzip -q /tmp/templates.tpz -d /tmp/godot_export_tpl
  mv /tmp/godot_export_tpl/templates/* "$TPL/"
  rm -rf /tmp/godot_export_tpl
fi

mkdir -p "$TPL"
cd "$TPL"
if [[ -f ./web_nothreads_release.zip && ! -f ./4.3.stable/web_nothreads_release.zip ]]; then
  mkdir -p __godot_43__
  for x in *; do
    [[ "$x" == "__godot_43__" ]] && continue
    [[ "$x" == "4.3.stable" ]] && continue
    [[ -e "$x" ]] || continue
    mv "$x" __godot_43__/
  done
  rm -rf 4.3.stable
  mv __godot_43__ 4.3.stable
fi
if [[ ! -f ./4.3.stable/web_nothreads_release.zip ]]; then
  FOUND="$(find . -mindepth 1 -maxdepth 1 -type d -name '4.3*.stable' | head -1 | sed 's|^\./||')"
  if [[ -n "$FOUND" && -f "$FOUND/web_nothreads_release.zip" ]]; then
    rm -rf 4.3.stable
    ln -sfn "$FOUND" 4.3.stable
  fi
fi
test -f ./4.3.stable/web_nothreads_release.zip

cd "$REPO_ROOT"
_godot_bin/godot --version
echo ""
echo "Godot is ready in this container. From repo root:"
echo "  bash scripts/preview-web.sh"
echo "Then open the forwarded URL for port 8765 (simple HTTP preview of export/web)."
