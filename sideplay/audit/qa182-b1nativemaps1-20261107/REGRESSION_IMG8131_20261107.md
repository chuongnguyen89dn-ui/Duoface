# QA182 — IMG_8131 visual regression and source transaction defects (2026-11-07)

## User evidence
User: “Sao h nó lỗi hơn rồi?”
Attachment IMG_8131.jpeg, library_file_id libfile_d9e3a2fff2048191bcb46df5717ab07e, original local attachment /workspace/scratch/f9a10e281851/upload/IMG_8131.jpeg.
Photo shows a visible map region on the left, sidebar and a launcher/icon grid visible on the right. This is not evidence of two fully working DuoFace app panes. Do not infer native scene ownership, touch acceptance, installed version, settings OFF/ON or exact event sequence from pixels alone. User reports regression after QA182 release; screenshot itself has no build identifier.
Do not upload the personal original photo into the public source repository without a separate need; keep the attachment reference and this description.

## Baseline checked
Repo chuongnguyen89dn-ui/Duoface.
Signed source bdd1116b5308869210a65b79b92b7d873fe4a04c, sourceCI42314369824. Public QA1820.0.182~b1nativemaps1, SHAa879bc6e617f72b51e2d763b216626f5240495d94a6c1da2abff30b60d0e9860. Publication remains verified, not runtime acceptance.
Current QA182 docs tip at review4f056f08f8ee95e8d8ef258e37f697d363b804b3. Latest main:sideplay/log commit still2406d1f1c7df7fa7419aa2aa15eaca6076176f1c (Audit10 before QA182); no QA182 runtime log found there at this check.

## Confirmed source defects (independent of the photo trigger)
1. Premature destructive pane transition:
DFNative12Chrome.m assignNativeMaps182: creates assignment, releases the target active/pending phone-host views, saves Maps and calls layoutControls.
layoutControls lines1609–1613 derives nativeReserved only from active assignment PhysicalSlot and immediately hides the SB appWindow.
There is no native catalog/scene/frame commit receipt required for hiding. Thus the old pane is removed before native readiness/placement and failure recovery have been proved.

2. Failure does not roll back the cross-process assignment/window transaction:
DF182NativeMaps.m fail:reason: sets a gate FAIL, calls restore:, then summary:.
restore: sets stopped=YES and returns YES immediately when !placed. It does not remove the persisted assignment, restore a prior ordinary-pane owner, or notify Chrome to restore its window visibility.
With heartbeat fresh, DF182Assignment continues returning that Version2 record; Chrome nativeReserved can remain true even while the native engine has stopped. This leaves a half-committed pane transaction. It is a real code defect; it does not establish which gate failed in this photo.

## Additional verified integration boundary; runtime cause not yet established
DFNativeHostAppDelegate.m sceneDidEnterBackground: retains the split session only with DFOwnerNativeEvidence; otherwise stopTouchOwnerWithReason:scene-background.
DFCarPlayOwnerLease.h DFOwnerEvidenceMatches requires Bundle=com.duoface.native.scenehost, exact original host scene/session, Active, HomeHookReady and fresh CarPlay attestation.
B1 asks DBWorkspace to activate Google Maps. If that transition backgrounds DuoFace and its original owner attestation ceases, existing policy can revoke the heartbeat/Chrome. Need qa125-background-boundary / touchowner-stop / assignment-revoked timestamps to determine whether that occurred. Do not say it definitely occurred from this image; do not bypass ownership policy or manufacture a lease to keep an invalid session alive.

## Frame gate limitation
Current placement readback proves local UIKit parent/frame/clipping plus target SB window hidden. It does not by itself prove the global composed display still contains the other live app rather than a launcher, nor actual native hit target. The new photo makes it particularly important not to treat a local frame PASS as overall display acceptance.

## Required corrective transaction, before another release
- Reserve intent without destroying the prior live pane/window prematurely.
- Commit native scene/pane visibility only after catalog/launch/provenance/full-frame ownership are verified for the same assignment and session.
- On failure/revoke/timeout, cancel the assignment and restore the modified native frame/containment and SB pane visibility as one explicit rollback, with readback. Restoring the previous ordinary app is transaction rollback; creating a Maps phone-host fallback remains forbidden.
- Re-evaluate the current prelaunch geometry check that requires a hidden target window: delaying hide must not deadlock native launch. The reserve/placement/visibility proof stages need consistent definitions.
- Preserve actual Home/replace/unassign/disconnect cleanup and all frozen H1 files/channels.
- Resolve the background-owner coupling using real runtime evidence and the user's scoped native design. If the specified mechanism cannot retain proven ownership/frame, STOP and bring evidence; do not add a different hosting/launch workaround.
- Keep native pixels, global layout, other-app survival and touch UNVERIFIED until the user confirms them. The current reported screen is not acceptance.

## Current action boundary
B1 advancement STOPPED pending this regression review and a QA182 runtime trace of the reported state. No new source patch, build, DEB or publisher modification in this review. Do not ask the user to cycle OFF/ON again as a remedy.
QA181 original rollback remains available but server selection alone does not downgrade an installed182; no rollback installation or source republish has been performed.
