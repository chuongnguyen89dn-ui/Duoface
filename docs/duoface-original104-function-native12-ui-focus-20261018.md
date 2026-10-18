# DuoFace QA — two immutable source DEBs: original104 function, Native12 interface (2026-10-18)

This is read-only disassembly/source comparison, **not** physical CarPlay acceptance.
Do not ship the original vendor compiled Dashboard or its CBBridgeManager/license objects into independent DuoFace.

## Provenance and rule

| Responsibility | DEB | Exact SHA256 | Dashboard SHA256 |
|---|---|---|---|
| Functional connection, focus, restore, scene refresh, lifecycle | Original DuoNavi **1.0.4** | `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd` | `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15` |
| UI geometry, visibility, visual states | Actual DuoFace **Native12 HUD8** | `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad` | `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea` |

## Original104 — actual functional paths

- `CBBridgedSplitApp.focusSlot:animated:` IMP `0x10ce70` and `restoreSplitAnimated:` IMP `0x10d40c`: actual ARM64 selector references include `saveBridgeStateToDisk`, `layoutSplitViews` and `refreshSceneLayout`. The original uses `CBBridgeManager`, **not** suitable for a second scene owner in independent QA.
- `CBBridgedSplitApp.layoutSplitViews` IMP `0x10bad8` reads frame geometry and sends `setFocusedMode:`, `setShowsExpandButton:`, `setCompactMode:` to the original pill as needed. Exact flag triggering is a separate dataflow problem, not deducible from the presence of a selector alone.
- In independent QA, `DFV12SceneHost.resizeTo` calls `applySize`, sets FBScene mutableSettings frame and invokes `updateSettings:withTransitionContext:completion:`; focus/restore handlers resize pane hosts by their current layout. That is an independently owned analog of original geometry refresh, **not** proof of functional equality on CarPlay.

## Native12 — confirmed actual visual frames

- `CBSlotPillView.layoutSubviews` IMP `0x84c30`, branch `0x84cf8..0x84d88`: when focused, hides dots button, expand button and separator; displays **only Restore**. Restore is set to the entire pill bounds. Previous independent QA exposed dots when focused and used half-width Restore; now corrected in `DFINativeShell.inc`.
- Nonfocused branch `0x84db8..0x84eb0`: dots + optional expand, restore hidden; a narrow separator occupies `CGRect(halfWidth-0.25,3.5,0.5,pillHeight-7)`. Constructor `0x8486c..0x84898` uses white with alpha `0.25`.
- `CBSlotPillView.updateBoundsSize` IMP `0x85184`: widths `38/44/64/72/76/80pt`, heights `19/22pt` under original flags. Actual frame sizes, not six separate permanent buttons.
- Divider visible grip and pill inner button frames already covered by `docs/duoface-native12-comprehensive-dimensions-20261018.md`.

## Evidence and tests

- Native12 + original104 pinned DEB audit: `scripts/audit_native12_original104_ui_debs.py` and `.github/workflows/duoface-native12-actual-deb-ui-audit.yml`, report `audit/native12-deb-original104-ui/FOCUS_ORIGINAL104_NATIVE12_UI_CROSSWALK.json` and Markdown companion.
- Full original104 `layoutSplitViews` ARM64 control flow exported into `audit/native12-deb-original104-ui/ORIGINAL104_LAYOUT_PILL_MODE_ARM64.txt`, to decode the input to compact/show-expand. `0x10c9a8` compares pane width to 320pt; a second height threshold is loaded from Mach-O VM `0x33ebe8` and must be verified from the original immutable binary before QA behavior changes.
- QA source regression: `replacement/visual12/tests/test_native_shell_structure.py`; two-source regression: `scripts/test_original104_function_native12_visual_focus.py`; iOS16 ARM64 compile/link workflow `.github/workflows/duoface-visual12-engine-bind-ci.yml`.

**Boundary:** successful audit or ARM64 compile does NOT mean a DEB is built, installed, uploaded to Sileo, or that all eight layouts, Dock/safe area, app switch, crash/exitMode or device touch work. Stable Native12 HUD8 is untouched.
