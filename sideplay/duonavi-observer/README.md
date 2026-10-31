# DuoNavi Observer — original live-session read-only trace

Distinct independent Sileo rootless package: com.duoface.qa.duonaviobserver, version 0.0.1~passive1, iPhone X iOS16.7.16. Not DuoNavi itself and **contains no DuoNavi vendor payload/license**.

One SpringBoard/CarPlay/CarPlayApp-filtered dylib observes UIKit public screen/scene/app lifecycle notifications and samples externally present display geometry, the host process's own scene counts, and iOS protected-data state. On SpringBoard it **reads**, without invoking or replacing, the ObjC type encodings of the three SBSuspendedUnderLockManager methods previously found in the original DEB. Each process logs its own timestamped JSONL, rotate at 2MiB. A standalone on-phone app provides five pre-event marker buttons and a single share/export action, no network or shell/Filza.

**Never install both active DuoFace QA124 scene hooks and original DuoNavi concurrently**. Back up prefs if appropriate; use Sileo to deactivate DuoFace hooks, use original legally obtained DuoNavi and this passive observer, then Respring from jailbreak manager. Park vehicle. Open original with YouTube, mark VIDEO_AWAKE; mark BEFORE_PHONE_LOCK just before locking; use CarPlay while locked, unlock and mark AFTER_PHONE_UNLOCK; mark BEFORE_CARPLAY_HOME then use actual Home separately; mark BEFORE_UNPLUG then physically detach. Open DuoNavi Observer on iPhone and share TXT into GitHub sideplay/log.

Log limitation: this is a passive sampler, not a guaranteed per-selector method-call tracer. Original proprietary method presence does NOT prove call execution. Compare observed state transitions with DuoFaceAudit 10: screen lock and CarPlay Home need separate user timestamps.

Source test: python3 sideplay/duonavi-observer/tests/test_passive.py.
Build: bash sideplay/duonavi-observer/build.sh on macOS with iOS SDK, ldid, dpkg. Do not claim real-device working until user supplies log. Do not alter QA120 measured Dock, .90 YouTube rotation, .92 split divider.

## Native Dock metadata continuation (2026-10-31, source only until CI/device proof)

`NativeDockABI.h` extends this existing passive observer, without changing its injection scope. In CarPlay/CarPlayApp only, the first 24 samples (3s cadence, approximately 71s from process start) enumerate registered Apple DB/CAR/CR class declarations for the 13 selectors in `DNDockSelectors()`, record actual type encodings and method declaring image, and record Dock/history/workspace/Home ivar **declarations**. Public UIWindowScene -> UIWindow -> UIViewController containment is capped at 64 controllers per sample; records include orientation, role, window level, parent class and external-display status. No private selector invocation, KVC, ivar-value dereference, method hook, UI mutation, broad UIKit injection or target app injection.

The sample starts with the existing observer process startup. Connect CarPlay promptly to capture within this bounded window. Loaded method declarations do not prove actual invocation or the receiver stored in an unobserved private ivar. The trace does not capture app-side ACK or first accepted touch. Metadata may be absent because of process/class loading, so absence is not proof of incompatibility.

`python3 sideplay/duonavi-observer/tests/test_native_dock_capture.py` checks missing/corrupt capture, duplicate declaring owners and the distinction between all ABI metadata and a verified runtime fix. Parse an exported TXT with `python3 sideplay/duonavi-observer/analyze_native_dock.py --log /path/to/export.txt --output /path/to/result.json`. `activation_safe_to_implement` intentionally remains false: review actual receiver provenance and activation arguments separately before changing production.

Workflow `.github/workflows/duoface-native-dock-passive-abi-compile.yml` only compiles an object using the iPhoneOS SDK and stores evidence in `sideplay/duonavi-observer/evidence/native-dock-abi/<run>/`. It does not build/sign a DEB or publish/install anything. Existing `0.0.1~passive1` packages remain historical; they do not contain this extension. Before distribution use a new version and inspect the package. Test original and DuoFace separately; do not install active commercial and independent bridge hooks concurrently without an inventory.

Runtime API references: https://developer.apple.com/documentation/objectivec/objc_copyclasslist(_:) , https://developer.apple.com/documentation/objectivec/class_copymethodlist(_:_:) , https://developer.apple.com/documentation/objectivec/class_copyivarlist(_:_:) . Read copied metadata lists and free them; superclass ownership must be distinguished from declared methods.


## Build 0.0.2~dockabi1 — native Dock capture

New distinct version; old passive1 package is preserved. Native Dock sampling now waits for an external display and records 24 samples during approximately 72 seconds of connection. The existing lifecycle observer stays active. Build with `bash sideplay/duonavi-observer/build.sh`; signed workflow `.github/workflows/duoface-duonavi-observer-standalone-signed.yml` saves the exact DEB and per-run inspection receipts. This is a diagnostic observer, not a DuoFace fix.

Install/update **DuoNavi Observer (Read Only)** via Sileo once available. Respring once so the observer loads into CarPlay, then connect CarPlay. During the first 60 seconds: open a selected unsupported app from Home, use Home, reopen using Dock if present, and repeat with another app. On iPhone open **DuoNavi Observer**, press **Xuất log**; preserve the current bridge identity (QA146 or original DuoNavi) with the capture. For a separate original comparison, disable the active DuoFace bridge first using the existing separate-session procedure. The observer does not enable, disable, replace or install any commercial bridge. Do not run both active bridges together. No Filza required.

This step only establishes declaring-class metadata and public scene containment. Native private receiver identity, selector call arguments, app-side ACK and touch latency remain unproven.


Packaging correction: first signed dockabi1 inspection showed mktemp root `0700` and macOS runner ownership. The install candidate is **0.0.2~dockabi2**, built with stage root 0755 and dpkg-deb --root-owner-group; the pipeline explicitly verifies the archive root mode/owner before promotion. dockabi1 is preserved as non-install-candidate evidence, not overwritten.
