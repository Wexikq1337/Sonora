#!/usr/bin/env bash
# Generates the platform folders (windows/linux/android) with YOUR local Flutter
# version, then copies them into the project. Nothing in lib/ is touched.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found in PATH. Install Flutter 3.19+ and retry." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Generating platform scaffolding in $TMP ..."
flutter create --platforms=windows,linux,android --org app.sonora --project-name sonora --no-pub "$TMP"

for p in windows linux android; do
  if [ -d "$TMP/$p" ]; then
    rm -rf "$ROOT/$p"
    cp -R "$TMP/$p" "$ROOT/$p"
    echo "copied $p/"
  fi
done

# audioplayers needs API 24+; Flutter's default minSdk may be lower.
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$ROOT/$f" ] || continue
  sed -i -E \
    -e 's/minSdkVersion[[:space:]]+flutter\.minSdkVersion/minSdkVersion 24/' \
    -e 's/minSdk[[:space:]]*=[[:space:]]*flutter\.minSdkVersion/minSdk = 24/' \
    "$ROOT/$f"
  echo "patched minSdk=24 in $f"
done

echo
echo "Done. Next:"
echo "  flutter pub get"
echo "  flutter run -d linux   # or: bash tool/build.sh linux"
