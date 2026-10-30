# DuoNavi original 1.0.4: standalone NON-INTRUSIVE iOS16 live-log probe design decision

Date: 2026-10-30 ICT. User asks: **“Vậy giờ sử dụng bộ quét log nào để test duonavi gốc? Tạo tw mới riêng hay sao?”**

## Decision: YES, new isolated standalone diagnostic rootless tweak, not DuoFaceAudit or existing MapOwnerExport

Goal: measure the **working original** DuoNavi scene/CarPlay timeline **on the same jailbroken iPhone X iOS16.7.16** to distinguish native iPhone display locking from an actual user action taking CarPlay to Home, and compare its scene and foreground outcomes with QA124. The **existing** phone DuoFace `DFNativeDiagnostics.m` only exports DuoFace-owned files, and `sideplay/native-map-owner-export-v6` exports a **specific DuoFaceCarPlayOwnerSnapshot.log** recorded by a different DuoFace probe; neither can instrument DuoNavi faithfully when the independent DuoFace hooks are disabled. No DuoNavi runtime log currently exists under `Duoface/main:sideplay/log/`.

A diagnostic standalone package is safer than patching original proprietary DuoNavi DEB or injecting DuoFace QA124 in parallel. **Do not repack the original package, attach vendor license logic or ship its binary.**

Proposed distinct package:
- `com.duoface.qa.duonaviobserver` — display name **DuoNavi Observer (read-only)**, rootless `iphoneos-arm64`, iOS >=16.0, independent lifecycle, not a replacement for original, no `Depends: com.duoface.jb.embedded`.
- SB module filter **SpringBoard only**; collector observes `UIScreenDidConnect/Disconnect`, system log signposts / allowed notifications, timestamps, presence and *exact runtime encoding* for `SBSuspendedUnderLockManager` `interceptUpdateForScene:withNewSettings:`, `_shouldBeBackgroundUnderLockForScene:withSettings:`, `shouldBeUnderLockForScene:`. Do NOT assume selectors/classes/encoding without runtime query. Only emit class/selector, existence, `method_getNumberOfArguments`, `method_getTypeEncoding`, getter if ABI safe, no hooks that change policy or action, no `MSHookMessageEx`, no setForeground / updateSettings.
- Optional CP module filter verified **CarPlayApp process** only (correct actual bundle from existing .plist filters) for CarPlay-connected externally active screen scene/window and public UIKit `UISceneActivationState`; log sampled **timestamps+counts+state only**, no app content, personal identifiers or tapping YouTube. It may be omitted if presence cannot be confirmed without mutating system processes.
- Dedicated isolated on-phone export UI, leveraging previous independent `native-map-owner-export-v6/main.m` copy/share pattern, reading **only own** `/var/mobile/Library/Logs/DuoNaviObserver*.jsonl`, bounded size/rotation, user-triggered Share as a text/JSONL file. Exporter does not require DuoFace NativeHost, Filza, PC, remote server, or internet.
- **Distinguish observation vs intervention:** collecting available OS notification/method encoding is passive; **existing built-in syslog often will not contain every original private method invocation**. Without active safe instrumentation we cannot truthfully claim `performAutoResume` or under-lock hook was actually called. Phase 2 detailed method probes must be reviewed for coexistence/hook-chain conflicts with original; default phase 1 does NOT hook these methods.

## Why build an independent diagnostic

QA124 user uploaded actual `main:sideplay/log/DuoFaceAudit 10.txt` (blob `81b6ae1aa699ec383af85112f8eddf524c409e9f`): unique QA124 is loaded, app background kills host in ~5ms and causes immediate scene invalidation. Separate app issue: SpringBoard fresh PIDs emit `qa123-underlock os-underlock-methods-abi-incompatible`, so **neither first-party underlock hook installed**. Original DuoNavi has 3 verified MSHookMessageEx registration callsites and extra hosted-scene identity predicate, via CI 40991513805 / 40991737734 / 40991974285. Existing original binary archive `main:dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` SHA `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`. We need new **runtime** timeline, not more guessing from original strings.

## Physical test protocol (once an independent signed probe has been built)

- Keep car stationary. Do **NOT** run DuoFace's SpringBoard/CarPlay injected dylibs together with original DuoNavi: original and independent share private scene hooks. Before test, back up preferences if necessary, use Sileo to temporarily remove/disable DuoFace QA124 runtime; then install original **legally available** DuoNavi 1.0.4 and **only** the separate passive observer; regular respring at installation. Run **one original at a time**.
- Stage A: connect CarPlay, open DuoNavi with YouTube, wait for stable video; note time.
- Stage B: press physical iPhone lock, wait, verify original panes + native Dock, tap YouTube Play, note timestamp and whether video plays. Unlock.
- Stage C: **separately** press real CarPlay Home button (phone stays awake), verify whether original hides, reenter original. This is the crucial discriminant versus stage B.
- Stage D: unplug physically/replug, verify teardown/resume. Do not conflate with Home.
- Export JSONL from standalone iPhone application and upload to `Duoface/main:sideplay/log/` distinct `DuoNaviObserver-<session>.jsonl` or attach in project. Align by stage labels/timestamps and actual scene-owner events; never compare wall times from unrelated runs as if same trigger.

## Acceptance criteria for building, NOT YET EXECUTED

1. **No original vendor binary or license packaged**, no original package contents touched. DEB package name unique, no `Conflicts/Replaces`, no `Depends: DuoFace`, no installation side effects beyond user-guided respring. No Filza.
2. Read-only static review: no hooks into `SBSuspendedUnderLockManager`/passcode/scene-setting methods, no `MSHookMessageEx`, no `SBMainWorkspace` modifications or force-display-brightness, no app kill or programmatic Home behavior.
3. Source unit check + MAC iOS16 SDK build of dylib and exporter, ldid sign, dpkg-deb manifest, SHA256. CI unique version and immutable archive; separate Sileo package only after CI and publisher Pages integrity PASS. Existing QA124 Sileo unchanged.
4. Device: no crash SpringBoard/CarPlay, collector emits time-stamped external display/ABI shapes before and after real lock and Home; app shares a real log. This is **not** proof every original selector was invoked.

**Status at this checkpoint:** user asked whether new separate tweak is appropriate; design/reuse decision recorded. **NO standalone probe runtime code built, no signed DEB or new Sileo package and no original runtime capture yet.** Existing QA124 remains latest published, user device fails locked Play.
