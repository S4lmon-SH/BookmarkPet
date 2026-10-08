#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$project_dir/.build/manual"
app_dir="$project_dir/build/BookmarkPet.app"
architectures=("$(uname -m)")

case "${1:-}" in
  "") ;;
  --universal) architectures=(arm64 x86_64) ;;
  -h|--help)
    echo "Usage: $0 [--universal]"
    echo "Build for this Mac, or for both Apple Silicon and Intel."
    exit 0
    ;;
  *) echo "Unknown option: $1" >&2; exit 64 ;;
esac

mkdir -p "$build_dir" "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
executables=()
for architecture in "${architectures[@]}"; do
  target="$architecture-apple-macos13.0"
  architecture_dir="$build_dir/$architecture"
  mkdir -p "$architecture_dir"
  xcrun swiftc -parse-as-library -swift-version 6 -target "$target" -O \
    -emit-module -emit-object -module-name BookmarkPetCore \
    "$project_dir/Sources/BookmarkPetCore/MemoSession.swift" \
    -emit-module-path "$architecture_dir/BookmarkPetCore.swiftmodule" \
    -o "$architecture_dir/MemoSession.o"
  xcrun swiftc -parse-as-library -swift-version 6 -target "$target" -O \
    -I "$architecture_dir" "$project_dir/Sources/BookmarkPet/BookmarkPetApp.swift" \
    "$architecture_dir/MemoSession.o" -o "$architecture_dir/BookmarkPet"
  executables+=("$architecture_dir/BookmarkPet")
done
if [ "${#executables[@]}" -eq 1 ]; then
  cp "${executables[0]}" "$app_dir/Contents/MacOS/BookmarkPet"
else
  xcrun lipo -create "${executables[@]}" -output "$app_dir/Contents/MacOS/BookmarkPet"
fi

cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>ko</string>
  <key>CFBundleExecutable</key><string>BookmarkPet</string>
  <key>CFBundleIdentifier</key><string>com.bookmarkpet.app</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>BookmarkPet</string>
  <key>CFBundleDisplayName</key><string>BookmarkPet</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleIconFile</key><string>BookmarkPet.icns</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

xcrun swiftc "$project_dir/scripts/make_icon.swift" -o "$build_dir/make_icon"
"$build_dir/make_icon" "$build_dir/icon_1024.png"
iconset="$build_dir/BookmarkPet.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
  sips -s format png -z "$size" "$size" "$build_dir/icon_1024.png" \
    --out "$iconset/icon_${size}x${size}.png" >/dev/null
  double_size=$((size * 2))
  sips -s format png -z "$double_size" "$double_size" "$build_dir/icon_1024.png" \
    --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app_dir/Contents/Resources/BookmarkPet.icns"
codesign --force --sign - --timestamp=none "$app_dir"
echo "$app_dir"
