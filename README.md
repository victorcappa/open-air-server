# Open Air Server

Open Air Server is a local, open-source AirPlay receiver focused on live
performance on macOS. An iPhone mirror appears as an ordinary independent Mac
window: the operator can keep using the MacBook, move the mirror to an HDMI
projector, capture it in OBS, or put only that window into borderless fullscreen.

The application is a GPL-3.0-or-later adaptation of
[Popyachsa AirPlay](https://github.com/Recluse/Popyachsa-AirPlay), using its
patched [UxPlay](https://github.com/FDH2/UxPlay) engine instead of implementing
AirPlay from scratch.

## Current MVP

- AirPlay screen mirroring and audio over the local network.
- Independent, resizable macOS window with correct aspect ratio and black
  background supplied by the video layer.
- VideoToolbox hardware decoding, H.264/H.265 selection and live portrait /
  landscape rotation.
- Tray states for off, ready and connected, plus start, stop, restart and logs.
- Always-on-top, borderless chrome and borderless fullscreen.
- macOS display discovery and a preferred-display selector. Selecting the HDMI
  projector and enabling fullscreen creates the performance mode without taking
  over the MacBook display.
- Network-interface pinning for predictable theater Wi-Fi operation.
- The receiver window has a stable title for OBS Window Capture; capture on the
  target OBS/macOS installation is still a rehearsal gate.
- Local config and logs under `~/Library/Application Support/OpenAirServer`.
- No account, cloud dependency, telemetry or automatic updater.

The app stays hidden until a device connects. Closing the mirror window drops
the current session and immediately returns the receiver to its ready state.

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
build/macos/dist/Open Air Server.app
```

The local build is ad-hoc signed. On first launch, use Finder's **Open** command
if Gatekeeper asks. A public release should use Developer ID signing and
notarization.

## Performance setup

1. Connect the Mac and iPhone to the same local Wi-Fi.
2. Connect the projector by HDMI and use macOS extended-desktop mode.
3. Open Settings, select the projector under **Display**, enable **Fullscreen**
   and **Borderless**, then restart the receiver.
4. On the iPhone, open Control Center, choose Screen Mirroring, and select
   **CAIXA PRETA**.
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

Open Air Server is licensed under **GPL-3.0-or-later**. UxPlay, the Rust host
application and modifications distributed together must remain available under
compatible GPL terms. See [LICENSE](LICENSE), [NOTICE](NOTICE), and
[docs/LICENSING.md](docs/LICENSING.md).
