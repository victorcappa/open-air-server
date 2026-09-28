# Architecture

## Decision

Air Server adapts Popyachsa AirPlay and its patched UxPlay engine. It does
not reimplement the AirPlay protocol.

```text
iPhone
  | AirPlay / AWDL direct or local Wi-Fi
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
preserves aspect ratio while the host retains normal macOS focus and input. The
macOS path requests 1080p60 from the sender, retains at most one decoded frame,
reuses a `CVPixelBufferPool`, and flushes stale display work under backpressure.
This keeps delay bounded instead of allowing a queue to grow during a slow frame.

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

On macOS the receiver starts in peer-to-peer mode. Bonjour publishes the RAOP
and AirPlay services with Apple's P2P/AWDL flags, while `SO_RECV_ANYIF` lets the
listening sockets accept traffic from the peer interface. The host deliberately
does not apply a saved LAN adapter pin on this path because AWDL is selected
dynamically by macOS. First contact uses UxPlay legacy pairing and the engine's
four-digit PIN is forwarded into the native waiting window.

## Explicit non-goals for the first MVP

- No AirPlay protocol reimplementation.
- No cloud service or account.
- No remote control of the iPhone.
- No automatic update feed until this fork owns signing and release hosting.
- No attempt to work with the Wi-Fi radio disabled. AWDL is router-free, not
  radio-free; Wi-Fi must remain enabled on both devices.
