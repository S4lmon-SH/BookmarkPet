#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$project_dir/.build/manual"
arch="$(uname -m)"
target="$arch-apple-macos13.0"
mkdir -p "$build_dir"
swiftc -parse-as-library -swift-version 6 -target "$target" \
  -emit-module -emit-object -enable-testing -module-name BookmarkPetCore \
  "$project_dir/Sources/BookmarkPetCore/MemoSession.swift" \
  -emit-module-path "$build_dir/BookmarkPetCore.swiftmodule" \
  -o "$build_dir/MemoSession.o"
swiftc -parse-as-library -swift-version 6 -target "$target" \
  -I "$build_dir" "$project_dir/Tests/ManualRunner.swift" \
  "$build_dir/MemoSession.o" -o "$build_dir/BookmarkPetTests"
"$build_dir/BookmarkPetTests"
