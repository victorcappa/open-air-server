#!/usr/bin/env bash
# Build the pinned Syphon.framework used by the optional Resolume output.
# Air Server publishes directly into Syphon's IOSurface base API, so the
# framework's optional Metal renderer shader is excluded. This avoids requiring
# Apple's separately downloaded Metal Toolchain on a source build.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
src="${SYPHON_SOURCE:-$repo_dir/third_party/syphon}"
derived="${SYPHON_DERIVED_DATA:-$repo_dir/target/syphon/macos-arm64}"
framework="$derived/Build/Products/Release/Syphon.framework"

[ -f "$src/Syphon.xcodeproj/project.pbxproj" ] || {
  echo "missing pinned Syphon source at $src" >&2
  echo "run: git submodule update --init --recursive" >&2
  exit 1
}

echo "==> building pinned Syphon.framework (arm64, IOSurface path)"
xcodebuild \
  -project "$src/Syphon.xcodeproj" \
  -scheme Syphon \
  -configuration Release \
  -derivedDataPath "$derived" \
  -quiet \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  MACOSX_DEPLOYMENT_TARGET=11.0 \
  CODE_SIGNING_ALLOWED=NO \
  EXCLUDED_SOURCE_FILE_NAMES=SyphonMetalShaders.metal \
  build

[ -f "$framework/Syphon" ] || {
  echo "Syphon build succeeded without producing $framework" >&2
  exit 1
}
echo "=== built Syphon ==="
echo "$framework"
lipo -archs "$framework/Syphon"
