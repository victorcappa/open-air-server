#!/usr/bin/env bash
set -euo pipefail

if [ -d /opt/homebrew/opt/rustup/bin ]; then
  PATH="/opt/homebrew/opt/rustup/bin:$PATH"
fi
export PATH

gst_framework="${GSTREAMER_FRAMEWORK:-/Library/Frameworks/GStreamer.framework}"

pkg_paths=(
  "$gst_framework/Versions/1.0/lib/pkgconfig"
  /opt/homebrew/opt/openssl@3/lib/pkgconfig
  /opt/homebrew/lib/pkgconfig
)
joined_pkg_path="$(IFS=:; echo "${pkg_paths[*]}")"
PKG_CONFIG_PATH="$joined_pkg_path${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Air Server macOS doctor must run on macOS." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "ok   $1: $(command -v "$1")"
  else
    echo "MISS $1" >&2
    failed=1
  fi
}

for tool in clang cargo rustc cmake ninja pkg-config; do
  check_command "$tool"
done

if [ -f "$repo_dir/third_party/uxplay/lib/airplay_core.cpp" ]; then
  echo "ok   UxPlay integration submodule"
else
  echo "MISS third_party/uxplay (run: git submodule update --init --recursive)" >&2
  failed=1
fi

gst_runtime="$gst_framework/Versions/1.0/lib/libgstreamer-1.0.0.dylib"
if [ -f "$gst_runtime" ]; then
  echo "ok   GStreamer runtime: $(lipo -archs "$gst_runtime")"
else
  echo "MISS $gst_framework (official runtime framework required)" >&2
  failed=1
fi

if pkg-config --exists gstreamer-1.0 gstreamer-video-1.0 gstreamer-app-1.0 2>/dev/null; then
  echo "ok   GStreamer development metadata: $(pkg-config --modversion gstreamer-1.0)"
else
  echo "MISS GStreamer development metadata (brew install gstreamer)" >&2
  failed=1
fi

if pkg-config --exists openssl libplist-2.0 2>/dev/null; then
  echo "ok   openssl + libplist pkg-config metadata"
else
  echo "MISS openssl/libplist pkg-config metadata" >&2
  failed=1
fi

if [ "$failed" -ne 0 ]; then
  echo "Doctor found missing build prerequisites." >&2
  exit 1
fi

echo "Air Server build prerequisites look ready."
