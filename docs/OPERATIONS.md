# Show operation

## Rehearsal checklist

- Use the exact MacBook M4, iPhone 16 Pro, iOS/macOS versions, HDMI adapter,
  projector, router and audio output intended for the show.
- Disable the Mac's built-in AirPlay Receiver if it advertises a confusing
  competing destination name.
- Put Mac and iPhone on the same dedicated local Wi-Fi. Internet is not required.
- In Air Server Settings, pin the show Wi-Fi adapter when practical.
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
- If the receiver is not listed, confirm both devices are on the same Wi-Fi,
  then restart the receiver. Avoid changing router settings during the show.
- If the projector path fails, drag the normal window back to the MacBook and
  continue locally while the operator restores HDMI.

Keep a rehearsed wired or prerecorded fallback for critical dramaturgy. AirPlay,
Wi-Fi and external displays are enhancements; they should not be a single point
of failure for the performance.

## Using it without internet

The supported release needs a local Wi-Fi/LAN but does not need internet. For a
venue, use a dedicated travel router with both devices connected; its WAN cable
can remain disconnected. This keeps discovery local and avoids dependence on the
venue network.

Router-free AirPlay over AWDL is not enabled in Air Server 0.2.16. Upstream
UxPlay 1.74 has an experimental `-p2p` mode, but it still needs integration,
PIN/trusted-device UX and physical rehearsal before it can be a show path here.
