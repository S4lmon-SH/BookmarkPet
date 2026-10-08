#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
"$project_dir/scripts/build.sh" --universal
app_dir="$project_dir/build/BookmarkPet.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_dir/Contents/Info.plist")
release_dir="$project_dir/build/release"
archive_name="BookmarkPet-${version}-universal.zip"
mkdir -p "$release_dir"
codesign --verify --deep --strict "$app_dir"
# Exclude extended attributes and Finder metadata from the public archive.
ditto -c -k --keepParent --norsrc --noextattr --noqtn "$app_dir" "$release_dir/$archive_name"
(
  cd "$release_dir"
  shasum -a 256 "$archive_name" > SHA256SUMS.txt
)
echo "$release_dir/$archive_name"
