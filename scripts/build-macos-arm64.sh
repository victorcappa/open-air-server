#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
uxplay_src="$repo_dir/third_party/uxplay"
core_build="$repo_dir/target/uxplay-core/arm64"
core_dylib="$core_build/uxplay-core.dylib"
gst_framework="${GSTREAMER_FRAMEWORK:-/Library/Frameworks/GStreamer.framework}"

GSTREAMER_FRAMEWORK="$gst_framework" "$repo_dir/scripts/doctor-macos.sh"

echo "==> building pinned UxPlay core (arm64)"
SRC="$uxplay_src" BUILD="$core_build" ARCH=arm64 FRAMEWORK="$gst_framework" \
bash "$repo_dir/build/macos/build-core-arm64.sh"

echo "==> assembling Air Server.app (arm64)"
DYLIB="$core_dylib" \
X86_DYLIB="$repo_dir/.build-input-not-present/uxplay-core-x86_64.dylib" \
X86_BIN="$repo_dir/.build-input-not-present/open-air-server-x86_64" \
TARGET=aarch64-apple-darwin \
FRAMEWORK="$gst_framework" \
bash "$repo_dir/build/macos/make-app.sh"

echo "Built: $repo_dir/build/macos/dist/Air Server.app"
