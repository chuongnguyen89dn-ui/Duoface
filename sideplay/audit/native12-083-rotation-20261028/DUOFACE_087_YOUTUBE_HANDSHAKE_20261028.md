# DuoFace .87: YouTube host/app orientation handshake

Baseline: 9f0ba04370c99b1c6c0fce8d044595fcc0fce760, after user handoff 57b5cf77.
Branch: feature/duoface-jb-embedded-appbridge-20261020.
Target: rootless arm64 iOS16; integrated com.duoface.jb.embedded 0.0.87~ythandshake1.
NativeHost internal package: 0.1.96~ythandshake1. Build: existing macos-15 Actions pipeline.

## Evidence and implementation
Original Native12 report in this directory proves host payload orientation=1,
app-process listener and local UIWindow rotation/reflow. .86 shipped no app-side
receiver. This closes that demonstrated gap; it does not prove the sole device cause.
The new first-party DFYouTubeOrientationRelay is filtered ONLY to YouTube and
bundled in the existing integrated DEB. The obsolete broad DFAppViewportRelay
remains excluded. No copied vendor binary/code/license.

DFSceneHost publishes only its current, attached, visible, hosting scene after
stable geometry commits. Payload: exact FBScene identifier, UUID owner tied to
scene lifetime, generation, 3-second timestamp lease, render dimensions and
portrait=1. Cold app startup requests state; host polling renews leases without
repeated layout; resize commits publish immediately. Stop/owner loss revokes.
App receiver requires exact UIScene._sceneIdentifier equality (including the
hosted phone-main scene), checks all private selector argument/return encodings,
rotates only normal-level app windows, sets frame/bounds and requests layout.
No global swizzle, device rotation, fake foreground/activation or player hook.
ACK reports measured scene/window sizes and orientation, not a success flag.
Stale/replayed/invalid state or old-owner revokes cannot alter a newer session.
Expiry restores only saved windows still belonging to the same connected scene.

UIScene._sceneIdentifier is also used by WebKit PageClientImpl::sceneID:
https://chromium.googlesource.com/external/github.com/WebKit/webkit/+/e97a970f4f182a0dd7f31c946bddd96c02ad2b5f/Source/WebKit/UIProcess/ios/PageClientImplIOS.mm
This corroborates the getter, NOT runtime availability on the user's iOS16.
Getter ABI and exact identifier are checked on device; absent/mismatched getter
fails closed and emits scene-id-unmatched rather than guessing a window.

## Verification
Local Python source/geometry regressions: 123 native-host tests + 7 packaging tests PASS.
Shell syntax and git diff whitespace PASS. Executable Foundation tests added for
expiry, malformed payload, replay, wrong-owner revoke, int/NSInteger rotation ABI
and rejected incompatible ABI. Actual execution and iOS compile require macOS CI.
DFSceneLifecycle.m, DFSceneOrientationPolicy.m, DFHostedMapRenderSize.h,
DFNative12Chrome.m and Maps/Dock implementation remain byte-identical to baseline.

## Device acceptance still required
On parked CarPlay: YouTube split -> first pane Zoom WITHOUT YouTube fullscreen ->
restore -> repeat; then YouTube fullscreen -> restore, close, reconnect and phone
mode. Playback must remain stable. Look for youtube-app-handshake-ack in
DuoFaceSceneHost.log; windowsApplied and measured orientation/size distinguish
app delivery from host-only geometry. A successful build is not device proof.
No Sileo publication in this change. Preserve .83/.84 recovery artifacts.
