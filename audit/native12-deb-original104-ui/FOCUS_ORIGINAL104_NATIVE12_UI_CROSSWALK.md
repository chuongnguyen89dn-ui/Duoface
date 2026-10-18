# Original 1.0.4 function / Native12 interface - focus/restore audit

Pinned immutable DEB binaries only. This is STATIC evidence, not receiver validation.

## 1. Functional owner — ORIGINAL DuoNavi 1.0.4
- `CBBridgedSplitApp.focusSlot:animated:` 0x10ce70: saveBridgeStateToDisk, layoutSplitViews, refreshSceneLayout.
- `CBBridgedSplitApp.restoreSplitAnimated:` 0x10d40c: same persistence/layout/scene-refresh chain.
- `CBBridgedSplitApp.layoutSplitViews` 0x10bad8: setFocusedMode:, setShowsExpandButton:, setCompactMode:.
This documents the original call chain; the independent QA owns its own scene hosts.

## 2. Visual owner — NATIVE12 HUD8
- `CBSlotPillView.layoutSubviews` 0x84c30: focus hides dots/expand/separator, shows full-width Restore.
- Normal shows app plus optional expand separated by 0.5pt line; Restore hidden.
- Separator layout at 0x84e64..0x84e94; alpha 0.25 in constructor 0x8486c..0x84898.
- Six outer pill states are tracked separately in COMPACT_UI_CONTRACT.json.

## 3. Independent QA parity and unresolved scope
- Verify DFINativeShell.inc focus, separator, and full-width restore against this record.
- DFIInterface.inc focus/restore relies on DFV12SceneHost.resizeTo -> applySize; no original license/manager.
- Original104 compact branch: pane.width <320pt OR pane.height <220.0pt (0x10c99c-0x10c9f8).
- Branch-level proof only: other layout/focus states and showsExpandButton still need full dispatch mapping.
- UI correctness and CarPlay scene visibility still need physical tests.
