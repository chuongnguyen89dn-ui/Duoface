# DuoFace .111 — physical reconnect regression: only one remembered app (2026-10-29)

## New user device evidence (supersedes earlier assumed restore success)

- User supplied TWO new photographs from the vehicle head unit after **actual CarPlay reconnect**, and explicitly states: app chooser shows just **one previously selected app**, not both prior app selections. This is a **FAILED device acceptance** for .111 from user report; installation version shown in photos is not independently visible, so verify installed package in logs/Sileo before attributing binary path.
- Photo 1: system CarPlay Dock at left and left-side dark navigation map, right physical pane entirely black. Photo 2: DuoFace App selector lists GOFA, Waze (orange arrow badge), Facebook, YouTube, Wyn and TikTok. This UI shows an active/marked Waze selection but does NOT independently prove the persisted workspace plist has one record, since the chooser marks only a selected/current slot. A black pane could be empty saved slot OR failed scene restore. Do not conflate scene availability with persistence.
- Source checkpoint reviewed: feature branch at `297e9ffead6085d48bc4525b098ac07c96e59d43`, original .111 source `b95ba2a52427cc4c20a6f409a385074c08029d54`.

## Source observations (verified)

- `sideplay/duoface-native-scene-host/DFSlotWorkspacePolicy.h`: four bundle IDs are stored at `/var/mobile/Library/Preferences/com.duoface.nativehost.workspace.v1.plist` field `PhysicalBundles`; persistence rejects duplicate IDs across physical slots and uses an atomic write+readback. Invalid, incomplete or inaccessible record is interpreted as an all-empty default. Default `RestoreOnReconnect` is YES.
- `DFNative12Chrome.m`: `beginSavedWorkspaceRestore` computes `DFRestorablePhysicalBundles` from saved `PhysicalBundles`, preset slot count, installed apps and `DFConfiguredEnabledAppIDs`; it restores *sequentially*, and skips a slot when absent/not enabled/not installed.
- User app pick `appPicker:didSelectBundleID:` writes `DFSavePhysicalBundle(physicalSlot,bundleID)` immediately when no old active view, but when replacing an existing active view it defers persistence until `sceneReady:`. Thus a reconnect before actual host ready may retain the older app choice. The save failure is only logged and does not block showing the newly hosted scene.
- `sceneReady:` writes physical bundle and re-reads workspace; `sceneFailed:` and restore timeout skip an app without intentionally clearing the persisted ID. Without real plist/log evidence these paths cannot be identified as the user-device root cause.
- The .111 change extends host wait to 13.5s and retries once; it does NOT make an explicit physical-disconnect persistence snapshot or verify *both* physical bundle IDs at reconnect. Therefore CI/Home-return validation cannot be used to claim successful physical reconnect restoration.

## Required next investigation — do not blindly increase timers

1. Check exact installed package and capture the **actual** `PhysicalBundles`, `RestoreOnReconnect`, `Order3`, `Order4` keys before disconnect and after reconnect, plus saved preset/slot count, with the owner's permission and **without modifying the plist**. Do not publish private identifiers.
2. Match per-slot `workspace-intent-saved-pending`, `workspace-intent-save-failed`, `workspace-slot-save-failed-no-scene-impact`, `scene-replace-committed-render-unverified`, `workspace-restore-skipped-allowlist-or-install`, `workspace-restore-pending`, `workspace-restore-requeued-after-host-failure`, `real-scene-failed` from `/var/mobile/Library/Logs/DuoFaceTouchOwner.log` and `DuoFaceSceneHost.log`.
3. Distinguish: (A) stored only one selected bundle; (B) two stored but picker badge marks current slot only; (C) two stored, but scene restore fails; (D) actual app disabled/disallowed on iPhone; (E) wrong preset/count on reconnect. Implement smallest independent fix only after identifying which condition occurs, add regression for two slots across true physical disconnect, rebuild rootless DEB and publish to Sileo then device-test.
4. Preserve system Dock, previously working .90 YouTube rotation, movable divider/logo (no 3-second hold), original rollback packages, approved-app filtering and Maps lease; do not copy vendor binaries/licensing.

## Execution / status

- No source/build/package deployment changed in this checkpoint. Real device failure report recorded; cannot claim fixed or on-device test PASS.
- Handoff entrypoint remains `sideplay/tiep tuc du an.md` (existing, large; fetch_file returned empty content for full read on this connection). Preserve it and point subsequent investigators to this report; DO NOT overwrite it with a truncated version.
- Next operator: inspect actual source/log evidence above; start from branch head including this report, avoid restarting from .92 or unrelated work.
