# DuoFace SpeedHUD — evidence for GOFA drag-to-dismiss and 0.2.3 source transport

**16 October 2026 | read-only reference audit, no DEB or Sileo change**

## GOFAHUD 0.3.1 rootless: verified directly in user-supplied binary

- User DEB: `GOFAHUD-0.3.1-rootless.deb`, SHA256 `62d6d818384844591217d74ab446404637127752e1b23bc1f9754ef1da297ad5`.
- Payload path: `var/jb/Library/MobileSubstrate/DynamicLibraries/GofaCarplayGlobal.dylib`.
- `GOFACarHUD.pan:` ARM64 `__TEXT,__text` at `0x9bd4`; gesture state check, translation, new coordinates and persistence. Key calls observed by `llvm-objdump`:
  - `0x9c18` selector `state`; `0x9c38` `setDragging:`; `0x9c88` `translationInView:`; `0x9cf8` `locationInView:`.
  - `0x9d1c` `dismissTarget` getter; `0x9d74` `setDismissTarget:` setter; `0xa380` `setCenter:`; `0xa150` `setHidden:`.
  - `0xa464` and `0xa590` calls `notify_set_state`; `0xa470` and `0xa59c` `notify_post`.
  - `0xa5a8` `NSUserDefaults`; `0xa600` `setObject:forKey:`. The binary also contains `local.gofahud.carplay.position`.
- `GOFACarGlobalWindow.hitTest:withEvent:` ARM64 `0x4000`: obtains HUD via `viewWithTag:`, checks `isHidden`, invokes `pointInside:withEvent:` and returns `nil` outside the HUD. Prevents touch interception over the rest of CarPlay.
- Screenshot `GofaHUDPrefs.bundle/full-map-top-right.png` supports appearance only. **Do not claim that static code proves the exact runtime threshold/dismiss persistence**; the user independently reports the GOFA bubble is freely movable and dismissible.

Static repro (local folder contains extracted DEB; do not edit/repack it):

```bash
sha256sum GOFAHUD-0.3.1-rootless.deb
dpkg-deb -x GOFAHUD-0.3.1-rootless.deb /tmp/gofa-extracted
llvm-objdump --macho --arch=arm64 --disassemble \
  /tmp/gofa-extracted/var/jb/Library/MobileSubstrate/DynamicLibraries/GofaCarplayGlobal.dylib \
  > /tmp/gofa-carhud-disasm.txt
sed -n '/^\-\[GOFACarHUD pan:\]:/,/^-[A-Za-z]/p' /tmp/gofa-carhud-disasm.txt
```

## Data integration: GMapHUD 0.2.3 upstream MIT

- Input pin: `com.chou.googlemaps.vietmap_0.2.3_iphoneos-arm64.deb` SHA256 `bc5a34cf2b6a8faa017beab725a3cb8adf4804a5b19275a9d7f95ed5732c1f64`.
- Source contract: `bechou0410/gmaphud` tag `v0.2.3`, `common/source-output.h`, `common/source-transport.m`, `common/speed-state.m`.
- `com.chou.gmaphud.source.selection` carries epoch + selected source ID: **1=VietMap, 2=Waze, 3=GOFA**. **No Google Maps speed-limit producer in this version.**
- Per-source namespaces `com.chou.gmaphud.output.v1.<id>.commit`, `.selection`, `.speed`, `.limit`. Revision in commit must be even and nonzero; low 8 bits = 1. Reader must check selection twice, revision twice, frame-selection equality. Each speed or limit is independently timestamped and expires after **5 seconds**, not after each redraw.
- The original publishers **send only for selected source**, so installation of the four source dylibs alone does not prove all live readings. DuoFace's `DFSpeedGMapReader.mm` bridges the wire into exactly one `DFSpeedNativeHUD`. It first requests a source based on currently bridged map (if determinable); when no map is identified and data is missing it probes the next of three at least 4s apart. The fourth source, Google Maps, still has GPS-only via `DFSpeedAppObserver.mm`, **no verified speed-limit feed**. This is candidate source code until tested on an actual jailbroken iPhone.
- Only GMapHUD **app-source** binary modules and MIT notices may be staged; exclude `GMapHUDOverspeedScreen` and `GMapHUDPlacementRelay` to avoid dual renderers.

## DuoFace candidate UX, not yet device-verified

- `runtime/speedbubble/DFSpeedBubbleBridge.mm` is the **single GOFA-style pill**, with `UIPanGestureRecognizer`, clamped safe-area drag, normalized position in NSUserDefaults suite `com.duoface.speedhud`, and temporary **×** dismissal target during drag.
- Dropping near **×** hides **for the current CarPlay session**; disconnect/recreate resets the hidden state so the user can recover without a separate settings screen.
- Touches outside the bubble are handled by the original DuoFace/CarPlay hierarchy (no full-screen interactive overlay).
- Source-only macOS arm64 compilation checks and regression tests are **not equivalent to on-device GUI + speed telemetry validation**.
