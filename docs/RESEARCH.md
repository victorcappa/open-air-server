# Upstream audit

Audit date: 2026-09-28.

## UxPlay

Audited repository: [FDH2/UxPlay](https://github.com/FDH2/UxPlay), commit
`2b5ff5ad59a232c9ab45205d3562c78c45ad4740`.

- Active GPL-3 project supporting AirPlay mirroring, audio and limited HLS.
- Supports macOS and Apple Silicon through GStreamer.
- Current upstream identifies itself as experimental 1.74.
- macOS peer-to-peer/AWDL is present behind the `-p2p` option and requires the
  Apple Bonjour backend plus the system AirPlay Receiver setting.
- UxPlay creates a normal renderer window, but its stock macOS sink has less
  control over embedding, rotation, teardown and projector placement than the
  Popyachsa integration fork.
- It can forward RTP to an external renderer such as OBS, but this adds a second
  media path and is unnecessary for normal Window Capture.

Conclusion: correct engine and upstream protocol source, but not the best direct
operator application for this project.

## Popyachsa AirPlay

Audited repository:
[Recluse/Popyachsa-AirPlay](https://github.com/Recluse/Popyachsa-AirPlay), commit
`c24d4a4c68ea913b4456da67b45d49359d03ffa0`, version 0.2.15.

- Uses a patched UxPlay core through a flat C ABI.
- Owns a native, resizable macOS window and renders into its `NSView`.
- Uses VideoToolbox and an `AVSampleBufferDisplayLayer` sink.
- Tracks orientation changes from AirPlay metadata and refits the window.
- Provides audio, reconnection, status, restart, always-on-top, borderless and
  borderless fullscreen behavior.
- Builds a self-contained `.app` with a trimmed GStreamer runtime.
- Supports macOS Apple Silicon and Intel builds, although universal packaging
  requires additional x86_64 dependency work.
- Its macOS display selector was incomplete: monitor enumeration only existed on
  Windows. Open Air Server implements the missing CoreGraphics backend and
  applies the selection before fullscreen.

Conclusion: best available base. It already solves the risky AirPlay/window
integration and lets this project concentrate on theater operation.

## RPiPlay

[RPiPlay](https://github.com/FD-/RPiPlay) remains architecturally important as an
ancestor of UxPlay. Its Raspberry Pi/OpenMAX focus makes it a poorer base for a
modern Apple Silicon macOS windowed application.

## Compatibility claims

Source inspection supports the architecture and build claims above. It does not
prove acceptance on the target MacBook M4, iPhone 16 Pro, current iOS, projector,
speaker route or OBS installation. Those remain physical-device rehearsal gates.
