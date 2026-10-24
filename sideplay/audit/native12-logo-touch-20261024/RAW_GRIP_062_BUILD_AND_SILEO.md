# DuoFace circular grip 3-second interaction — 2026-10-24, real device FAIL

Source repo: chuongnguyen89dn-ui/Duoface
Active branch: feature/duoface-jb-embedded-appbridge-20261020
Original checkpoint: 0ae447782e8779248cf1b811b870da19d4930ae9

## Evidence and confirmed failure
- Device owner reports real round logo button does NOT operate on previously published .61. No real-device .62 acceptance is available.
- Actual earlier .58 touch log proved 3.720475s physical hold; native UILongPress failed at 2.09s, movement 12.33pt, allowableMovement 10pt.
- Static evidence in actual original SHA-pinned Native12 ARM64 dump: CBDividerView owns logo hitbox, native long-press handler, position via CBDividerButtonInfo.relativePos/updateGripLayout; divider ratio pan is separate.
- Independent old DFNative12Chrome.m attached competing UILongPress to UIButton while also using UIKit UIControl tracking; no demonstrated end-to-end grip success in device .61.

## First-party candidate and preserved functions
- Changed sideplay/duoface-native-scene-host/DFNative12Chrome.m commit 69d57f44c11aae871ecd14ab4fa4e8ea7f7ad731:
  one first-party DFNativeDividerGripButton tracks raw UIResponder touchesBegan, touchesMoved, touchesEnded, touchesCancelled with same UITouch identity; excludes competing recognizer, retains 3s timer, parallel normalized LogoFraction move, quick perpendicular Ratio, short tap Swap and native art/hitbox. Zoom and media code unchanged.
- Updated tests and package pins for NativeHost 0.1.71~rawgrip1 / integrated 0.0.62~rawgrip1.
- Python contract + iOS16 arm64 clang source CI 40052911244 completed success.
- macOS rootless DEB archive CI 40052974461 success, first immutable candidate in sideplay/jb-embedded-appbridge/evidence/runs/40052974461/, SHA256 4899757790e10f490c9b42fb0b2fd8a6f32b6631809070352e2ce6a9befa20a9. This first .62 candidate is NOT released and MUST NOT be substituted silently.

## Real Sileo publisher failure, corrected
- carplaydsp publisher commit ccb5b6d5ed1b79a2add07529b9a41d4336bd2c3c, workflow run 40053285947 FAILED at APT-index step, after verifying .62 signed archive and all raw event marker strings.
- Exact missed string: binary build=0.0.62~rawgrip1. GitHub source fetch confirmed DFDeepTrace.h still hardcoded build=0.0.61~touchbackstop1. This is source trace mislabel, not the device issue nor a signature failure.
- Corrected DFDeepTrace.h commit b8cb2289d93bdc7c9f2f1166aea18399ed74d05f to embed build=0.0.62~rawgrip1.
- New package request commit 58f039ddbe4b4979b14d53c84efe6019d91f3ff1; run 40053489952 triggered to build from exact newest source. Must verify run result and distinct archive source SHA/SHA256, then patch carplaydsp URL+SHA to second immutable artifact. Preserve first immutable archive as failed staging evidence; do not overwrite it.

## Next exact actions
1. Read GitHub Actions 40053489952 jobs and logs; check Python, macOS clang, signed rootless DEB, GitHub archive readback. If fails, correct actual error, re-run with new source SHA.
2. Pin only second artifact SHA+run ID in carplaydsp .github/workflows/build.yml and publish; verify Pages Packages single latest .62 and downloaded DEB exact SHA, .61 rollback unchanged.
3. On parked iOS16 rootless CarPlay, verify actual grip source output: raw-began -> logo-3s-hold-began-real-touch-timer -> logo-3s-moved-position -> raw-ended, persisted LogoFraction and quick ratio+Swap. No device test has been performed; any claim real logo fixed is prohibited.
4. Video player size, whole-host Dock Zoom and SpringBoard SIGABRT remain independently unresolved. No vendor binaries or licensing included.

