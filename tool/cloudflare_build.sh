#!/usr/bin/env bash
# Cloudflare Pages build for Flutter Web (no Node/package.json).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "==> Installing Flutter ($FLUTTER_VERSION) into $FLUTTER_ROOT"
  if [ ! -d "$FLUTTER_ROOT/.git" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_ROOT"
  fi
  export PATH="$FLUTTER_ROOT/bin:$PATH"
fi

flutter --version
flutter config --no-analytics
flutter config --enable-web
flutter pub get
# Cloudflare Pages serves at site root (not GitHub Pages /vimai_kids/).
flutter build web --release --base-href "/"

echo "==> Output ready: build/web"
ls -la build/web | head -n 30
