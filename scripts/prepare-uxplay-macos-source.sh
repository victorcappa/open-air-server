#!/usr/bin/env bash
# Create the reproducible macOS UxPlay source tree used by local/release builds.
# The public submodule stays pinned and clean; Air Server's small macOS-only
# renderer overlay is applied to a disposable copy under target/.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vendor_src="${UXPLAY_VENDOR_SOURCE:-$repo_dir/third_party/uxplay}"
prepared_src="${UXPLAY_PREPARED_SOURCE:-$repo_dir/target/uxplay-source/macos}"

[ -f "$vendor_src/uxplay.cpp" ] || {
  echo "missing pinned UxPlay source at $vendor_src" >&2
  exit 1
}

mkdir -p "$prepared_src"
rsync -a --delete --exclude .git/ "$vendor_src/" "$prepared_src/"
cp "$repo_dir/uxplay-patches/avsample_sink.m" "$prepared_src/renderers/avsample_sink.m"
patch --silent --forward -d "$prepared_src" -p1 \
  < "$repo_dir/uxplay-patches/low-latency-macos.diff"

echo "$prepared_src"
