# Architecture

## Decision

Air Server adapts Popyachsa AirPlay and its patched UxPlay engine. It does
not reimplement the AirPlay protocol.

```text
iPhone
  | AirPlay / local Wi-Fi
  v
patched UxPlay core (C/C++, GPL)
  | flat C ABI + decoded media
  v
Rust host application
  | native macOS window + tray
  +--> HDMI projector
  +--> OBS Window Capture
```

This is option A from the project brief: use and adapt an existing working open
source application. It keeps protocol, pairing, mDNS, decoding, audio and
reconnection in the upstream engine while the host owns window behavior.

## macOS render path

The Rust host creates a hidden `tao` window and passes its `NSView` to
`uxplay-core.dylib`. The engine decodes through GStreamer and VideoToolbox. A
custom `AVSampleBufferDisplayLayer` sink renders into the supplied view and
preserves aspect ratio while the host retains normal macOS focus and input.

The engine reports connection, teardown and incoming dimensions through its log
callback. The host uses those events to show or hide the mirror and to resize it
when the iPhone rotates.

## Projector mode

macOS displays are enumerated through CoreGraphics. The operator chooses a
display in Settings. Before a stream becomes visible, the hidden mirror window
is moved onto that display and sized there. When fullscreen is enabled, the app
uses `tao::Fullscreen::Borderless`, not exclusive display mode. This keeps the
MacBook display and its Space available to the operator.

The controls deliberately remain independent:

- **Display** selects the target monitor.
- **Fullscreen** fills only that monitor.
- **Borderless** removes window chrome in windowed operation.
- **Always on top** prevents other windows covering the mirror.

## State and recovery

The engine has three operator-visible states: off, ready, and connected. Restart
tears down the current engine worker and creates a fresh listener. A client
disconnect hides the video window without quitting the app. Closing the video
window restarts the receiver, which is a deliberate manual recovery path during
a show.

The selected network adapter can be pinned. If it disappears, the engine logs a
warning and falls back to all adapters instead of failing silently.

## Explicit non-goals for the first MVP

- No AirPlay protocol reimplementation.
- No cloud service or account.
- No remote control of the iPhone.
- No automatic update feed until this fork owns signing and release hosting.
- No claim that AWDL works in this fork yet. Current upstream UxPlay 1.74 has an
  experimental `-p2p` path, but this app pins Popyachsa's validated 1.73.6-based
  integration fork. Wi-Fi is the production path for this MVP.
