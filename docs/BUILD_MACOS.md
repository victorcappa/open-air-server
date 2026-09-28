# Build on macOS

The supported first target is Apple Silicon. Universal Apple Silicon + Intel
packaging is inherited from upstream but is not required for the target M4.

## One-time dependencies

1. Install Xcode Command Line Tools.
2. Install Rust, CMake, Ninja, pkg-config, OpenSSL 3 and libplist.
3. Install the runtime package of the official universal GStreamer macOS
   framework under `/Library/Frameworks/GStreamer.framework`. Homebrew's
   `gstreamer` formula supplies the development metadata used by CMake.

The exact GStreamer download must come from the official
[GStreamer macOS directory](https://gstreamer.freedesktop.org/data/pkg/osx/).
Verify the published checksum before installing it. The repository currently
requires the official runtime version to match the Homebrew development version;
the currently validated pair is 1.28.7.

Homebrew prerequisites other than GStreamer:

```bash
brew install rustup cmake ninja pkg-config openssl@3 libplist gstreamer
rustup default stable
rustup target add aarch64-apple-darwin
```

## Diagnose

```bash
./scripts/doctor-macos.sh
```

The doctor is read-only. It fails if required tools, the pinned UxPlay submodule,
or the GStreamer framework are missing.

For a non-system framework extracted elsewhere, pass its path explicitly:

```bash
GSTREAMER_FRAMEWORK=/path/to/GStreamer.framework ./scripts/doctor-macos.sh
GSTREAMER_FRAMEWORK=/path/to/GStreamer.framework ./scripts/build-macos-arm64.sh
```

## Build the Apple Silicon app

```bash
./scripts/build-macos-arm64.sh
```

The script builds `uxplay-core.dylib` directly from the pinned submodule and then
assembles an ad-hoc-signed, self-contained application:

```text
build/macos/dist/Open Air Server.app
```

## Verification boundaries

The packaging script verifies code-signing structure, bundled dependencies and
architectures. It cannot verify discovery, mirroring, audio, live orientation,
latency, HDMI placement or OBS capture. Follow `OPERATIONS.md` on the physical
show kit before release.
