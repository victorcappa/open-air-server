# Show operation

## Rehearsal checklist

- Use the exact MacBook M4, iPhone 16 Pro, iOS/macOS versions, HDMI adapter,
  projector, router and audio output intended for the show.
- Enable the Mac's built-in **AirPlay Receiver** under System Settings → General
  → AirDrop & Handoff. Air Server uses the OS setting to unlock AWDL transport.
- Keep Wi-Fi enabled on both devices. They do not need to join the same network,
  or any network, when using the direct path.
- On first contact, enter on the iPhone the PIN shown in the Air Server window.
- Select the projector display. Test both a movable window and borderless
  fullscreen.
- Rotate the phone portrait/landscape during a live mirror.
- Verify audio on the intended speaker path.
- Verify OBS Window Capture if OBS is part of the show.
- Disconnect and reconnect twice, then use Restart once.

## Start of show

1. Connect HDMI and confirm the projector is an extended display.
2. Start Air Server and confirm tray state **Ready**.
3. Start Screen Mirroring on the iPhone and choose **AIR SERVER**.
4. Confirm tray state **Connected** and the mirror on the selected display.
5. Keep the iPhone unlocked and power it from a charger if the performance is
   long.

## Recovery

- If the image freezes, stop mirroring on the iPhone, wait for **Ready**, and
  reconnect.
- If it does not return to Ready, choose **Restart** from the tray.
- Closing the mirror window also drops the current client and re-arms the
  receiver.
- If the receiver is not listed, confirm Wi-Fi remains enabled on both devices
  and **AirPlay Receiver** remains enabled on the Mac, then restart Air Server.
- If direct discovery is unreliable in the venue, join both devices to the same
  dedicated local Wi-Fi and reconnect. Internet is still unnecessary.
- If the projector path fails, drag the normal window back to the MacBook and
  continue locally while the operator restores HDMI.

Keep a rehearsed wired or prerecorded fallback for critical dramaturgy. AirPlay,
Wi-Fi and external displays are enhancements; they should not be a single point
of failure for the performance.

## Using it without a router or internet

Air Server 0.2.18 uses AWDL for a direct nearby-device link. Leave the Wi-Fi
radio on, but disconnecting from the venue network is fine. No hotspot, internet
connection or travel router is required. A trusted iPhone normally remembers
the first PIN pairing; a new device receives a fresh four-digit PIN in the Air
Server waiting window.

Keep a dedicated travel router available as the simple fallback for a critical
show. Both devices can join it while its WAN/internet connection stays unplugged.
