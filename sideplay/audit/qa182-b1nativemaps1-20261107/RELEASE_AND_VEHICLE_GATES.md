# QA182 B1 — release candidate and vehicle gates

## Candidate identity
- Integrated package com.duoface.jb.embedded 0.0.182~b1nativemaps1, iphoneos-arm64.
- Source bdd1116b5308869210a65b79b92b7d873fe4a04c; CI42314369824 PASS, 29tests PASS including real Foundation assignment lifetime and completion-block ABI checks.
- Signed original archive DuoFace5d460f684012a331f3a99fbbb621c4d32132b09a; destination duoface-debs-4a9eef05d9ffa6a6d110ddc6babaf2713a58703c.
- File debs/com.duoface.jb.embedded_0.0.182~b1nativemaps1_iphoneos-arm64.deb, 1274984bytes.
- SHA256 a879bc6e617f72b51e2d763b216626f5240495d94a6c1da2abff30b60d0e9860; Gitblob dd556a6a2b88af80e1d9805fd7b9ac9c8fc25f27.
- Publisher4933f9855d25c11efd5971761b4cda55815c62d2 / run42315405987. Publication success MUST be read from current handoff/public verifiers; this report is not itself evidence of Pages success.
- QA181 original nearest rollback: 0.0.181~b0probe1, SHA25685377a2bba3c572b2b26b783f72af54af6ab774119f6c45f8bf4a3b1f9058714.
- Step0 source report: STEP0_SOURCE_VERIFICATION.md in this directory.

## What this candidate implements
- Existing picker signals route Google Maps to one Version2 assignment with UUID/session/bundle/physicalSlot/visualSlot/time, not to SB phone hosting.
- Current channel supports the existing two-pane, unfocused layout. Other layouts return explicit frame FAIL; do not pretend they passed. Ordinary app paths remain unchanged.
- Assignment-scoped catalog reconciliation of the original live FBS library, original Maps declaration untouched, and captured Dashboard DBWorkspace activateApplication request.
- New ABI-checked sceneFrame/deactivate/background hooks on the current coordinator implementation; no historical port claim. Scene-frame size uses fresh geometry before native creation, actual placement separately converts full rect through native UIWindow/root coordinates.
- Native controller containment saves/restores original parent/superview/frame/order; target SpringBoard pane window is hidden, no custom touch forwarding.
- Native scene provenance uses bundle + real controller tree + scene/host-view/window role/external display/process; sceneID alone is not a classifier.
- Lifecycle swallow requires that same scene pointer, native owner and fresh assignment. Home/replace/unassign/disconnect revoke; native Home restores synchronously when its process-local bridge is available.
- Existing touchowner heartbeat and native-owner background policy remain in place. If native launch is followed by session teardown, read qa125-background-boundary/touchowner-stop/assignment-revoked evidence before claiming iOS denied Maps; no automatic ownership-policy workaround is included.
- QA181 observer now samples both CarPlay/CarPlayApp. Diagnostics exports HomeRoster165 and latest B1 summary. H1 headers/implementation byte-identical to base.

## Two vehicle sessions, with explicit settings evidence
When parked, use two-pane layout and choose Google Maps for exactly one pane. Keep the other app as-is.
1. OFF mandatory session: confirm Maps OFF in iPhone CarPlay settings. Record a screenshot or explicit verdict tied to this test time/session. Select Maps in DuoFace. Observe actual native map surface; drag map, press a visible button, search/start navigation inside the pane. Verify hit position, other app and logo.
2. Export log for that session. Code records stock-settings=unknown until a verified read source exists; external OFF evidence must be associated with the assignment/session. If setting cannot be established, treat data as exploratory.
3. ON comparison session: repeat with Maps ON and export separately. ON success does not replace OFF acceptance.
4. After Home, replacement, clearing pane or unplug, verify original lifecycle/owner restoration and normal other-app behavior.

## Log decision rules
Marker qa182-b1; correlate AssignmentID/Session/physical slot, not every historical line in cumulative logs.
- b1-hook-ABI: all three signatures must match before catalog/launch intervention.
- b1-catalog-reconciled: original live membership + genuine declaration readback. Catalog PASS is not launch PASS.
- b1-launch-issued: request issued; Launch remains UNVERIFIED until scene proof.
- b1-scene-seen: include bundle/controller/scene provenance/settings class/role/window role/process/display/real sceneID. Unknown fields remain literal unknown.
- b1-scene-frame-request: requested native size before placement; not full frame proof.
- b1-frame-placed: actual full rect, source/destination coordinate spaces, clipping and parent/window evidence.
- b1-lifecycle-swallowed / b1-lifecycle-restored: exact owned scene, reason and actual restoration outcome; missing swallow is UNVERIFIED, not implicitly PASS.
- b1-summary and latest result plist: catalog/launch/scene/frame/lifecycle separate. NativePixels and Touch remain UNVERIFIED in software; only vehicle verdict decides.
- Native private ABI mismatch, catalog/launch failure, 10s timeout or unproved full frame stops the assignment. No phone fallback, no alternate launch/hosting workaround.
- A build/archive/publication PASS is never a vehicle B1 PASS.
