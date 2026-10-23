# Historical route repair — 2026-10-23

Sources actually read:
- main tiep tuc du an.md (3187 lines), especially October 14 device-observed fullscreen entry and runtime/fullscreen/DFDashboardChrome.xm (blob 2abbaa946f770d0faa9b74e8ca2b45e4a35c5220).
- main ban giao du an duoface moi.md downloaded directly after connector returned empty content; lines 2394 onward record Native9 user confirmation. Native9 DEB SHA e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e, artifact commit 328d123ae4ae13a56bb75a9916d22be1e2c85f3f.
- feature/duoface-exact-payload-migration src/DFDividerLogoGrip.inc blob 0b14c99ab8ed9283fbb8c98839eb5d0ebc70ad52 and docs/divider-logo-press-gesture-analysis-20261015.md blob 409fe7b4fdbaff06552a8497fa14676ebca42ec4.
- user logs and DEVICE_LOG_FINDINGS.md beside this report.

Crosswalk:
| Feature | Historical working route | .56 discrepancy | Current source repair |
|---|---|---|---|
| Whole-host Zoom | SpringBoard picker -> cross-process receiver -> DBStatusBarWindow/CARStatusBarWindow hidden; host geometry snapshot/restore | Receiver only AppDock candidates; tests prohibited DBStatusBarWindow despite same historical adapter using it | Keep existing session/ACK/geometry, add exact historical class fallback only if zero AppDock matches, unique visible owner; preserve snapshot/restore |
| Hidden-window lifecycle | Dedicated chrome window is intentionally hidden | Existing receiver assumes hidden owner window means disconnection | Allow hidden owner only when dock target IS that window; still restore on session loss |
| Logo hold | Native9 UILongPress on logo -> Began latch -> Changed relativePos/updateGripLayout; no native divider-pan replacement | Custom UIButton timer cancelled at 7pt before 3s | One native UILongPress recognizer, no competing timer; controls track start/ratio; recognizer owns hold state; preserve post-hold no-swap latch |
| Hold duration | Native9 0.30s, original Native6 0.4s | Later user explicitly requests 3 seconds | 3.0 seconds retained; NOT claiming Native9 itself used 3s |
| Ratio | Native9 leaves native handlePan untouched | .55 removed logo ratio path; .56 restored it | Keep current .56 quick cross-axis ratio and divider pan, no fail-dependency on 3s hold |

No vendor license/binary code copied. Current independent app remains the owner. Historical fullscreen entry was device-reported but original installed commit not proven by that screenshot; do not overstate exact binary attribution.

Local validation: python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p test_scenehost_safety.py: 73 PASS. git diff --check PASS. Tests are source contracts, NOT UIKit device tests. CI iOS16 syntax pending at source checkpoint. No DEB or Sileo change yet.

Device risks/gates: correct historical chrome class must actually be present; no arbitrary generic window fallback. UIKit long-press default motion allowance still applies; do not promise that moving before 3 seconds qualifies. Verify full Zoom in/out, Home/disconnect restore, ratio drag on track/logo, 3s hold->vertical move with no swap, no video regression. New logs identify historic-ios16-chrome-candidate and logo-3s-hold-began-native-recognizer; prehold motion includes uptime elapsed/deltas.
