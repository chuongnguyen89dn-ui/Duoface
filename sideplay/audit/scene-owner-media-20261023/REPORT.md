# Scene ownership / split players — 2026-10-23
Repo: chuongnguyen89dn-ui/Duoface. Branch: feature/duoface-jb-embedded-appbridge-20261020.
Base: f626fcca8f010075fb171ef826d6fbae724231c3. Preserve previous menu patch and all source-owned features.

## Evidence and limitations
Read central SKILL_INDEX; relevant ZIPs01/02/05 had been fetched/extracted and read earlier in this same session. Read current handoff, native12-media-player-split-20261022/REPORT.md and native12-continuation-4888299/gallery-media-imp/REPORT.md, full current DFSceneHost.m and exact playable-user-reported .37 source a8cdec6252b0e772faa726e92b84ee66246590ed.
Actual diff shows .37 already used content-reference setters and updateSettingsWithBlock; restoring its dimensions cannot by itself prove crash recovery.
Historical handoff records SIGABRT in SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings: +440. Raw .ips was not in GitHub tree and two Library filename searches yielded no result. This turn did not re-parse original crash, retrieve exception reason, or prove caller causality. No blame assigned to AppData/GhostBoard. New/current crash report still needed for definitive attribution.

## Concrete source defects corrected
1. pollScene kept first nonnil self.scene forever, even when sceneHandle.sceneIfExists changed. A geometry timer could therefore mutate a stale scene.
2. Geometry mutations now re-resolve current scene/hosting/attachment before private setters. Loss of hosting suspends geometry, cancels pending timer, and invalidates generation; resumption/replacement resynchronizes the same independent host without opening another app or replacing source features.
3. Settings block checks generation, stopped/suspended state and current handle before touching settings. Stop revokes generation before teardown. This prevents stale queued work from applying after close/replacement.
4. Poll timeout counter now measures consecutive misses, resetting on each valid observation. Previously intermittent misses accumulated throughout the entire session and could eventually close a valid app.
5. Chrome no longer sets external window/root/child frames when CGRect is unchanged. Waking controls/menu refresh should not submit redundant viewport frame changes to every player.
6. Reject nonfinite pending sizes in private commit; keep existing exception guard and reentry guard.

## Player appearance
Shared host covers all installed apps, not a YouTube-specific patch. Retain .37 logical 2x dimensions and current orientation=Portrait1 because original Native12 updateSceneSettingsFrame evidence explicitly uses1; do not force Landscape solely because a pane is wide. No claim that rotated video, fullscreen controls, aspect, audio focus, or every app is now equivalent. No new synchronous layoutIfNeeded, private foreground flags, fake transitions, hooks into vendor license or unrelated tweaks.

## Tests actually run
Workspace /workspace/scratch/253b9f8336e2/Duoface.
python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p test_scenehost_safety.py -q
58 tests PASS, no existing expectations changed. These are source contracts, not a UIKit/device reproduction of stale-scene transitions.
GitHub source-only iOS SDK CI pending on commit creation. No signed DEB or deployment.

## Next
Inspect CI for this exact source, especially Objective-C block/ABI checks. Then version and package integrated candidate using existing workflow, inspect immutable package/provenance; do not label source compile as crash acceptance. On device: record installed version; app launch -> playback -> enter/exit video fullscreen -> drag divider -> focus/restore -> close/relaunch -> CarPlay reconnect for YouTube plus other failing apps. Correlate geometry-deferred-owner-changed, scene-geometry-suspended, scene-geometry-owner-resynchronized with new .ips/exception reason if crash persists. Confirm no stale scene frame mutation and no unsolicited app termination; capture player per pane before judging visual parity.
