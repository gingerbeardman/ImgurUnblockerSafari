#!/usr/bin/env bash
# Regenerate every PNG icon for the app + extension from a single SVG source.
# Usage: ./regen-icons.sh [path/to/source.svg]
# Defaults to /Users/matt/Projects/ImgurUnblocker/Imgur_Icon_2018.svg
set -euo pipefail

SRC="${1:-/Users/matt/Projects/ImgurUnblocker/Imgur_Icon_2018.svg}"
ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$SRC" ]]; then
    echo "Source SVG not found: $SRC" >&2
    exit 1
fi
if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick (magick) not found in PATH" >&2
    exit 1
fi

render() {
    # render <output_path> <size_in_px>
    magick -background none -density 600 "$SRC" -resize "${2}x${2}" "$1"
    echo "  $(basename "$1") (${2}x${2})"
}

EXT_IMG="$ROOT/ImgurUnblocker Extension/Resources/images"
APPICON="$ROOT/ImgurUnblocker/Assets.xcassets/AppIcon.appiconset"
CONTAINER_ICON="$ROOT/ImgurUnblocker/Resources/Icon.png"

echo "Source: $SRC"
echo "=== Extension toolbar PNGs ==="
for s in 48 64 96 128 256 512; do
    render "$EXT_IMG/icon-${s}.png" "$s"
done

echo "=== AppIcon set ==="
for spec in \
    "16:icon_16x16.png" \
    "32:icon_16x16@2x.png" \
    "32:icon_32x32.png" \
    "64:icon_32x32@2x.png" \
    "128:icon_128x128.png" \
    "256:icon_128x128@2x.png" \
    "256:icon_256x256.png" \
    "512:icon_256x256@2x.png" \
    "512:icon_512x512.png" \
    "1024:icon_512x512@2x.png"
do
    size="${spec%%:*}"
    name="${spec#*:}"
    render "$APPICON/$name" "$size"
done

echo "=== Container app Icon.png ==="
render "$CONTAINER_ICON" 128

echo "Done."
