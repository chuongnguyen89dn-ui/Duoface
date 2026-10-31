# QA141: Log19 establishes why QA140 did not meet either device goal

Input: main upload commit 341a4dfbd5c10a5e8ca03475741860e983e6e483,
`sideplay/log/DuoFaceAudit 19.txt`, blob e01382c76292b4d806f0be899f5ff3278580a236.
Reproduce: `python3 analyze_log19.py <log19-path> --out findings.json`.

Actual findings: 190 Home admission info observations, six ordinary selected
bundles consistently retain nil `carPlayDeclaration`; native Maps/Waze/GOFA
already have CR declarations. Zero selected factory-created declarations and
zero policy callbacks for the synthetic path. FBS inclusion was not icon proof.
GOFA supplied 11 app-process ACKs. Six show stale map/Metal dimensions while the
window, scene and root agree; five are active. For example 1190x685 window vs
793x685 map, and 397x685 window vs 1190x685 map. QA140's passive receiver only
reported these measurements and could not correct them.

QA141 implementation:
- Complete only selected, installed, admitted DBApplicationInfo objects whose
  verified declaration getter is nil. Create an owned CR declaration with exact
  bundle setter/getter ABI; use a verified setter or typed object ivar, and verify
  getter identity before notifying. Existing native declarations pass through.
- Only declarations marked as created by QA141 may receive the selected launch
  policy. Remove the ineffective global CR declaration factory interception.
- Preserve QA140 thread-local saved-getter forwarding guard and existing Home140
  consent. Tests reproduce old QA138 recursion as a capped negative control and
  exercise bounded forwarding, native pass-through, disabled state, thread and
  exception cleanup, declaration slot/setter, failed getter rollback, idempotence
  and policy identity/native preservation.
- GOFA-only receiver targets exact runtime GOFA.GofaMapView and MapboxMaps.MapView
  classes. Require a fresh exact scene state, active app/scene, identity transforms,
  autoresizing-compatible views and actual parent size equal to the accepted
  window size. Resize to that parent's measured bounds and run normal UIKit
  layout. Never write Metal frame, map camera, screen scale, orientation, root or
  window geometry. Record parent and before/after measurements; restore temporary
  autoresizing masks after lease expiry or inactivity.
- Host scene transport/commit geometry, BKS observer, chrome and YouTube filters
  remain unchanged. Retain all prior source/evidence for rollback.

Local verification: 17 Python package/ABI/receiver tests pass; C dimension gate
replay passes. Apple Foundation runtime and signed arm64 build require macOS CI.
No assertion of visible Home icons, successful app tap, corrected map, or hardware
success is made from source checks. New parent geometry is measured at runtime;
inset or Auto Layout-owned parents deliberately fail closed. Device QA pending.
