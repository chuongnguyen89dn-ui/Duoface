# QA184 — real device Audit14 + Gate0 CarPlay/Preferences: verified field failure (2026-11-07)

## Exact user evidence and uploaded source
User's IMG_0007.jpeg: Sileo INSTALLED com.duoface.jb.embedded = **0.0.184~nativeowner1** (installed package, not the stale QA178/QA182 repository teaser). IMG_0006.jpeg: native Maps on left and large blank dark right; user says no navigation app icon on actual CarPlay Home. User photos remain in chat, NOT copied to public GitHub.

GitHub user upload commit [fe116f3a11953186f3d0bea02185b030f274df55](https://github.com/chuongnguyen89dn-ui/Duoface/commit/fe116f3a11953186f3d0bea02185b030f274df55), Duoface/main, 2026-11-07 04:30:28 UTC (11:30:28 ICT) changes EXACTLY three files:
- sideplay/log/DuoFaceAudit 14.txt — 6,137,180 bytes, Git blob ee81ed2d07f2e2a6c1887b6547ece99215ad27d6; exporter Date 2026-11-07 04:27:35 +0000; 27,347 data lines.
- sideplay/log/DuoFaceMapsGate0-CarPlay.jsonl — 6,292,956 bytes, Git blob 2ada6ed3ea66d4b39014d0fa1d99884d07fd454a; 1,552 JSONL records to 04:29:01 UTC.
- sideplay/log/DuoFaceMapsGate0-Preferences.jsonl — 42,528 bytes, Git blob b7fbdeac7ada76f09f5909d59736d741486adaab; 15 JSONL records to 04:21:41 UTC.

Analysis actually performed in this conversation: GitHub fetch_blob for exact 3 SHA, split Audit14 records by newline and filter build=0.0.184~nativeowner1, extract event=, assignment= and utc=; JSON.parse every CarPlay/Preferences JSONL row; group by full AssignmentID, join post-original presented scene records, compute absolute timestamp and duration. No CI, local vehicle action, new signed DEB or source patch executed as part of this inspection.

## Decisive QA184 result
- 11/11 b1-assignment-created, 11/11 catalog-reconciled PASS, 11/11 launch-issued, 33 native scene-frame requests (3/assignment). The request changes 640x360 into **198.333333x360**, preserving original origin (not visual proof).
- 11/11 corresponding post-original CarPlay Gate0 assigned launchSource=0, controller=DBApplicationSceneViewController, root=DBDashboardRootViewController, sceneClass=FBScene, windowRole=UIWindowSceneSessionRoleCarPlay, windowAttached=1, windowHidden=0. **All 11**: windowFrame={{0,0},{640,360}}, but *inner viewFrame={{0,0},{414,736}}*. Native scene exists, but final rendered pixels and orientation adaptation remain UNVERIFIED.
- **11/11 b1-present-member-rejected**. All eleven are rejected at the post-original stage BEFORE member PRESENTED confirmation. **0 b1-present-member accepted, 0 b1-scene-seen, 0 b1-frame-placed, 0 b1-pane-member-committed, 0 qa184-native-map-member-committed**. QA184 did NOT achieve a committed native map pane even once.
- **11/11 b1-assignment-revoked** with reason Chrome-Home-or-disconnect, after **1.80 to 2.99 seconds** from assignment (median 2.33). 10 separate watchdog-detach records, reporting active=1, session-match=1, pulse age 0.16–0.85s, so loss is NOT just absent/stale heartbeat. CarPlay native-owner-state becomes active=0, unique-duoface=0 as Maps transitions to native scene, but the new Maps PRESENTED receipt was never saved. SpringBoard then fails closed. 11 QA125 background-boundary logs initially report old native-owner=1; not proof of sustained Maps membership.
- QA184 11 summary records: catalog=PASS, launch/scene/frame/lifecycle/native-pixels/touch=UNVERIFIED, reason=assignment-released. This is a real physical failure, even though signed compilation/CI previously passed.

## Chronological crosswalk: every QA184 assignment (no skipped IDs)
| Assignment ID | Audit14 create -> reject -> revoke line | Gate0 scene line | Lifetime |
|---|---|---|---|
| BD99D0AF-E335-4768-8006-F5840D6991A0 | 25585 -> 25622 -> 25645 | 1313 | 2.33s |
| 19CD3E8D-631C-4EA1-8BFA-CE7DDF886752 | 25691 -> 25732 -> 25751 | 1319 | 2.99s |
| 1F8938F4-5FA1-4D3D-AD36-F6CC3ACCB2A8 | 25884 -> 25920 -> 25934 | 1354 | 1.83s |
| 39512709-9601-4CEF-9A09-28529184DE24 | 25975 -> 26015 -> 26046 | 1359 | 2.43s |
| 19E25FDD-4CA0-4494-92A5-C63D33ABC8AA | 26081 -> 26119 -> 26143 | 1363 | 1.92s |
| ED2455E1-FB17-4EB9-9C92-819A1253EFC5 | 26245 -> 26283 -> 26304 | 1381 | 2.32s |
| 080FCAB7-425A-4470-9B2C-6E00E7EBADF2 | 26361 -> 26407 -> 26420 | 1393 | 2.32s |
| 497F589D-E29D-40C7-A89F-8D84A6233017 | 26565 -> 26609 -> 26646 | 1423 | 2.34s |
| A7212901-85B6-4FE6-B300-FBB40ADE53B0 | 26688 -> 26732 -> 26793 | 1430 | 2.34s |
| 0F16C946-2757-4795-8201-201A778D172A | 26829 -> 26873 -> 26895 | 1435 | 2.34s |
| 0E939FD4-B106-482F-9E1C-4E16DA7ABAAE | 26934 -> 26972 -> 27001 | 1440 | 1.80s |

Example first transaction: Audit14 line 25585 create 04:21:00.969Z; line 25604 catalog PASS; line 25605 sceneFrame 640x360 -> 198.33x360; line 25606 launch; Gate0 line 1313 at 04:21:01.648Z shows actual FBScene with 414x736 inner view; Audit14 line 25622 post-original PRESENTED rejected; line 25638 old owner background; line 25640 CarPlay owner active=0; line 25642 watchdog-detach active=1 session-match=1 age 0.70; line 25645 assignment revoked (2.33s after create). Same lifecycle pattern across all 11.

## Separate Gate0 source measurements and OFF limitation
- CarPlay Gate0 totals: 1552 records in 3 probe runs, 27 presentBase.original-returned (20 assignment source=0, seven stock/unassigned source=3), 1162 periodic native.scene.snapshot (202 native Maps scene-positive), 119 discovery+ABI+runtime-class rounds. New QA184 batch is the 11 post-original assigned events listed above.
- All **1552** CarPlay records and all **15** Preferences records say stockSettings=UNKNOWN; stockReaderVerified true count **0**, stockProfileMatch true count **0**. Candidate discovery finds 29 POSSIBLE preference files (28 have a Maps string). This is NOT a verified per-vehicle ON/OFF signal, nor proof the active setting is ON. Do not contradict user's previously reported OFF observation.
- Apple CarPlay Home Maps/Waze icons are an independent not-yet-implemented milestone: DFHomePublisher136Core.m consciously preserves existing native CarPlay declarations and logs NATIVE_DECLARATION_EXISTS_OS_HOME_ICON_NOT_MANAGED_BY_DUOFACE. DF182DashboardBridge.m merely sends DBWorkspace activation for com.google.Maps. Neither sends a verified Apple Home icon-model refresh plus tap-to-app action. No Home icons are proved by these logs.

## Verified source gate and independent remaining defect
- Actual source from signed QA184 7df7b1039a8d4ef9d895b8c3ecdb6664ac64cb38: sideplay/native-carplay-scene-v1/DF182NativeMaps.m — after original present, DF182Present admits the real CarPlay class/scene and calls [owner publishMembershipStage:@"PRESENTED" controller:vc]. The repeated reject log is inside that member function; it returns NO on multiple checks but exposes only generic 'native-scene-or-physical-pane-proof-rejected-post-original'. The exact failed INNER predicate (native host/view, root/alpha, fresh SpringBoard physical pane record, coordinate or session timestamp) is **not uniquely identifiable** from this version. Do not claim a single unlogged predicate is already proven.
- Additional definite SOURCE inconsistency, separate from the initial 11 reject events: DFNativeHostAppDelegate.m renewTouchOwnerHeartbeat: allows (DFOwnerNativeEvidence || DFOwnerNativeMapsEvidence), but sceneDidEnterBackground: only checks DFOwnerNativeEvidence. Even after fixing presenter membership, native Maps ownership can still be dropped at the background boundary. Fix/cover both checks with the same session/revoke/Home predicates, without bypassing watchdog or inventing leases.
- Source resizing only changes CGRect.size in DF182Frame and re-parents/clips UIKit view; the 414x736 vs 640x360 native render mismatch remains physically unaccepted. No evidence that simply setting UIView.frame changes Apple FBScene remote render backing.

## Decision, resumption and authorization
- **QA184 SIGNED DEB PASS (integrity), QA184 DEVICE FAIL (11/11 presenter rejected and revoked)**. No new fix signed/build/Sileo update in this inspection turn. The QA184 package remains the installed field test; public Sileo still QA182, per user instruction.
- Next implementation path: instrument per-predicate read-only rejection labels and exact current pane/session/scene dimensions at publishMembershipStage:PRESENTED; fix verified predicate, reconcile Host background membership, keep original-first CarPlay ownership and atomic rollback; then validate actual map pixels/touch/peer pane. Independently map the REAL system CarPlay Home owner, native roster visibility, icon click-to-activate path and per-app selected Home setting, using previous QA136 real ABI audits. No uncontrolled entitlement spoof, native maps forced ON or vendor license copy. Do not make user repeat identical ON/OFF trials.
- Main handoff file: sideplay/tiep tuc du an.md on spec-main. QA184 branch stays source-only until an explicitly authorized new integrated signed QA test package.
