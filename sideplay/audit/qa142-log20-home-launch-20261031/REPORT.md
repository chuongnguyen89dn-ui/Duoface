# Log20: selected Home icons now visible; opening remains incomplete

User explicitly confirms selected app icons appeared on real CarPlay Home after
QA141. Tapping them does not open the app. This is a real admission milestone,
not a launch success. Do not revert the working declaration completion merely
because launch is still missing.

Input main upload441d7cd22de9def2b5de980f00c32d61d156cd90, blob
e87e85b47e9cfa2a85262ddc049278a4d1a02226; manual export04:48:01Z.
LOG20_FINDINGS.json records exact SHA and bounded current evidence.

## What the new device evidence proves

CarPlay PID92302 installed all three QA141 hooks. All six selected ordinary apps
had their actual DB declaration attached with getterReadback=1, followed by
newRecords=6. All six reached CRCarPlayAppPolicy evaluation; TikTok and Facebook
were evaluated again later, for eight callbacks total. The log does NOT record
actual icon-tap handler entry or a launch request's completion/error.

The line `launch=0 capable=1 display=1 phone=1` must be interpreted against the
source: those integers are success of calling ABI-checked setters, not the flags'
readback. launch=0 means setLaunchAsCarApplication: was unavailable/incompatible;
it does NOT prove a policy getter returned false and does NOT establish the root
cause. phone=1 means setLaunchUsingTemplateUI:NO was invoked. The other two
setters were invoked. No missing executable/URL scheme/path error is exported.

QA141's source changes the FBS record and CR policy. It has no Home-icon-to-
DFSceneHost/DFNative12Chrome launch routing, no generic ordinary-app CarPlay
scene receiver, and no LS scene manifest/launch-mode adapter for those apps.
SpringBoard's older first-party admission receiver only covers the DuoFace host
bundle, not these selected third-party bundles. Admission and rendering are
separate layers. Log20 cannot identify which native broker substep refused the
ordinary app; a policy callback alone is not a successful activation.

## Newly inspected original binary: a distinct launch bridge exists

Extracted the original `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` again.
DuoNaviDashboard.dylib SHA verified exactly
44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15.
Independent read-only extraction across original VM310a50..311b50 finds:
- shouldInterceptLaunchForApp: at3110f4/3112ac/311464 and further variants.
- original iconManager launchIcon/launchIconForIconView and overload diagnostics.
- startBridging: at311144/3112fc/3114b0 and further variants.
- pending/activated outcomes and stopBridging references after each route.
These are semantic selector/callsite observations, not copied vendor code or a
claim that those old class names exist on the current device. The new device
ABI still says _CARDashboardHomeViewController is absent. Older native-owner
snapshots in the export contain DBDashboardHomeViewController; those historical
snapshots do not establish the current selector signature. Any first-party tap
adapter must verify the actual class and ABI and preserve native app forwarding.

Reproduce selector extraction with the provided script and the exact verified
original dylib (requires lief/capstone). No vendor binary is newly redistributed.

## GOFA current measurements

Nine direct resize141 ACKs from the same GOFA PID92309, plus duplicate copies in consolidated trace. Count
nine, not eighteen. At every current sample the GOFA wrapper, Mapbox MapView and
Metal view agree with the accepted window: widths793,1190,793,595,397,397,703,703,
519; height685. Zero current stale-child mismatches. Explicit frame changes are
zero at these samples: the wrapper's temporary flexible autoresizing is installed
(eligible=1) and subsequent window changes already propagate before the next ACK.
Mapbox child is Auto Layout-owned and fails the manual frame-write gate; the measurements are consistent with normal
wrapper layout resizing it (an inference, not a direct callback trace). This is improvement over Log19's six stale samples,
but user has not yet confirmed the visual GOFA outcome. Do not claim blanket fix.

## Remaining implementation boundary

Retain the working QA141 roster, consent and geometry. Complete the selected-only
Home tap -> real first-party scene activation path, scoped to an actual current
CarPlay dashboard owner and a fresh explicit tap; forward native/unselected apps
exactly once. Confirm actual scene readiness before declaring launch success and
preserve Home/back/lock lifecycle. Do not invent filesystem paths, redirect every
icon, spoof native map declarations, or change GOFA geometry to address this.
No new runtime patch or QA142 DEB is included in this log-analysis checkpoint.
