# AirPlay Receiver Audit

Audit date: 2026-09-28.

## 1. Options evaluated

- **UxPlay** (`2b5ff5ad59a232c9ab45205d3562c78c45ad4740`): current protocol
  upstream, with macOS/Apple Silicon support and experimental AWDL `-p2p`.
- **Popyachsa AirPlay** (`c24d4a4c68ea913b4456da67b45d49359d03ffa0`,
  0.2.15): UxPlay-based application with its own native macOS window.
- **RPiPlay**: useful protocol ancestry, but not an appropriate modern macOS
  application base.

The source-level findings and repository links are recorded in
[docs/RESEARCH.md](docs/RESEARCH.md).

## 2. Compatibility

Popyachsa already supplies the strongest implementation path for the required
MVP: AirPlay mirroring over LAN, a resizable independent macOS window,
VideoToolbox decoding, audio, runtime orientation changes, reconnect handling,
and a self-contained application bundle. Air Server adds the missing macOS
display enumeration and projector selection behavior.

Source inspection and local arm64 builds do not prove the complete target flow.
M4, iPhone 16 Pro/current iOS, HDMI projector, OBS Window Capture, audio routing,
latency and reconnect behavior remain physical rehearsal gates.

## 3. License

UxPlay and Popyachsa are GPL. Air Server therefore remains
GPL-3.0-or-later, preserves notices, publishes the corresponding source and
ships the GPL text in the app. Details are in
[docs/LICENSING.md](docs/LICENSING.md).

## 4. Architecture decision

Use option A: adapt Popyachsa and pin its UxPlay integration fork. Do not
reimplement AirPlay. The Rust host owns the tray and `NSView`; the patched
UxPlay core owns discovery, protocol handling and media delivery. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## 5. Current implementation

- Default advertised receiver name: `AIR SERVER`.
- Predictable mirror-window title: `Air Server — iPhone`.
- Windowed startup on macOS; no automatic fullscreen.
- Resizable independent window with preserved aspect ratio.
- VideoToolbox H.264/H.265 path and bundled GStreamer runtime.
- Runtime orientation handling, audio, status and manual restart inherited from
  the audited base.
- Native macOS monitor enumeration and configurable target display.
- Borderless, always-on-top and display-local borderless fullscreen options.
- Per-user LaunchAgent support, disabled by default.
- Automatic upstream updates disabled until this fork owns a signed release
  channel.

## 6. Risks and limitations

- AWDL is intentionally not advertised as working. It exists in current UxPlay
  but not yet in the pinned, validated Popyachsa integration fork.
- The generated development app is arm64-only and ad-hoc signed. Public release
  requires Developer ID signing/notarization and, if Intel support is desired, a
  universal build.
- Pairing/PIN behavior must be rehearsed on the target iPhone before relying on
  it as audience protection.
- OBS capture behavior depends on the installed macOS/OBS permissions and must
  be verified in the real setup.
- Blackout, freeze and global performance shortcuts are later-stage controls;
  they are not part of the phase-1 acceptance gate.

## 7. Dependencies

Development requires Rust, CMake, Ninja, pkg-config, OpenSSL, libplist and
GStreamer. The produced `.app` includes the runtime media libraries, so normal
show operation does not require Terminal commands or a separately installed
GStreamer framework.

## 8. Recommendation

Use the current LAN implementation for phase-1 device acceptance. Do not add
AWDL or more show controls until the fundamental wireless iPhone-to-window flow
is proven on the target hardware.

## 9. Physical acceptance gate

Follow [docs/OPERATIONS.md](docs/OPERATIONS.md) with the actual MacBook M4,
iPhone 16 Pro, HDMI projector and OBS installation. Success requires the stream
to remain visible while the operator continues using the MacBook display,
keyboard, pointer and other applications normally.
