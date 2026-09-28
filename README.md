# Air Server

Air Server is a local, open-source AirPlay receiver focused on live
performance on macOS. An iPhone mirror appears as an ordinary independent Mac
window: the operator can keep using the MacBook, move the mirror to an HDMI
projector, capture it in OBS, or put only that window into borderless fullscreen.

The application is a GPL-3.0-or-later adaptation of
[Popyachsa AirPlay](https://github.com/Recluse/Popyachsa-AirPlay), using its
patched [UxPlay](https://github.com/FDH2/UxPlay) engine instead of implementing
AirPlay from scratch.

## Download and install

The ready-to-use Apple Silicon build is on the
[latest GitHub release](https://github.com/victorcappa/open-air-server/releases/latest).

1. Download `Air-Server-0.2.20.dmg`.
2. Open the DMG and drag **Air Server** to **Applications**.
3. On the first launch, Control-click **Air Server**, choose **Open**, then
   confirm. The current community build is ad-hoc signed and not Apple-notarized.
4. On the iPhone, open Control Center → Screen Mirroring → **AIR SERVER**.

The application bundle contains its media runtime. End users do not need Rust,
Homebrew, GStreamer, Terminal commands, an account, or an internet connection.
The published macOS build currently requires Apple Silicon and macOS 11 or newer.

## Current MVP

- AirPlay screen mirroring and audio over direct peer-to-peer AirPlay or a
  shared local network.
- Independent, resizable macOS window with correct aspect ratio and black
  background supplied by the video layer.
- VideoToolbox hardware decoding, H.264/H.265 selection and live portrait /
  landscape rotation.
- Selectable 720p, 1080p, 1440p and 4K sender resolution, plus maximum frame
  rate and decoder controls. 1080p remains the balanced default.
- Low-latency macOS path: 1080p60 sender request, one-frame decoded queue and
  reusable IOSurface-backed display buffers.
- Tray states for off, ready and connected, plus start, stop, restart and logs.
- Always-on-top, borderless chrome and borderless fullscreen.
- macOS display discovery and a preferred-display selector. Selecting the HDMI
  projector and enabling fullscreen creates the performance mode without taking
  over the MacBook display.
- Direct AWDL mode on macOS, with first-connection PIN shown in the Air Server
  window. No router or shared Wi-Fi network is required.
- The receiver window has a stable title for OBS Window Capture; capture on the
  target OBS/macOS installation is still a rehearsal gate.
- Local config and logs under `~/Library/Application Support/OpenAirServer`.
- No account, cloud dependency, telemetry or automatic updater.

The app opens a clear waiting window, then uses that same independent window for
the iPhone video. Closing it drops the current session while the receiver keeps
running from the menu bar.

## Network requirements

Internet access, a router and a shared Wi-Fi network are not required. Air Server
0.2.20 advertises through macOS AWDL so a nearby iPhone can connect directly.
Keep Wi-Fi enabled on both devices even if neither is joined to a network, and
enable **AirPlay Receiver** under System Settings → General → AirDrop & Handoff.
The first direct connection asks for the four-digit PIN shown by Air Server.

A shared LAN remains a useful rehearsed fallback. See
[Show operation](docs/OPERATIONS.md) for both paths.

## Build on Apple Silicon

The repository pins the exact UxPlay integration fork as a Git submodule.

```bash
git clone --recurse-submodules https://github.com/victorcappa/open-air-server.git
cd open-air-server
./scripts/doctor-macos.sh
./scripts/build-macos-arm64.sh
```

The build requires Xcode Command Line Tools, Rust, CMake, Ninja, pkg-config,
OpenSSL, libplist, and the official universal macOS GStreamer runtime +
development framework. Detailed setup is in [docs/BUILD_MACOS.md](docs/BUILD_MACOS.md).

The output is:

```text
build/macos/dist/Air Server.app
```

The local build is ad-hoc signed. On first launch, use Finder's **Open** command
if Gatekeeper asks. A public release should use Developer ID signing and
notarization.

## Performance setup

1. Keep Wi-Fi enabled on the Mac and iPhone. They may be disconnected from all
   Wi-Fi networks; for direct mode, enable the Mac's native **AirPlay Receiver**
   setting once.
2. Connect the projector by HDMI and use macOS extended-desktop mode.
3. Open Settings, select the projector under **Display**, enable **Fullscreen**
   and **Borderless**, then restart the receiver.
4. On the iPhone, open Control Center, choose Screen Mirroring, and select
   **AIR SERVER**.
5. Keep the MacBook display for the operator. The mirror window is placed on the
   selected display and uses borderless fullscreen there.

Always rehearse the exact iPhone, macOS version, router, projector, audio route
and OBS setup before a show. A successful build is not physical-device
acceptance.

See [docs/OPERATIONS.md](docs/OPERATIONS.md) for recovery and fallback steps.

## Documentation

- [Architecture and design decisions](docs/ARCHITECTURE.md)
- [AirPlay receiver audit](AIRPLAY_RECEIVER_AUDIT.md)
- [Detailed upstream research](docs/RESEARCH.md)
- [macOS build](docs/BUILD_MACOS.md)
- [Show operation](docs/OPERATIONS.md)
- [GPL and third-party obligations](docs/LICENSING.md)
- [Original upstream README](docs/upstream/POPYACHSA_README.md)

## License

Air Server is licensed under **GPL-3.0-or-later**. UxPlay, the Rust host
application and modifications distributed together must remain available under
compatible GPL terms. See [LICENSE](LICENSE), [NOTICE](NOTICE), and
[docs/LICENSING.md](docs/LICENSING.md).
