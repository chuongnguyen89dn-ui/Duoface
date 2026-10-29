# DuoFace — Independent app habits and explicit default choices (source-only)

Date: 2026-10-29. Repository: `chuongnguyen89dn-ui/Duoface`.
Branch: `feature/duoface-jb-embedded-appbridge-20261020`.

## Latest user decision: supersedes earlier #2

The earlier proposal to preselect apps for "left/right" or "slot 1–4" on iPhone is explicitly **cancelled**. The product should instead use a user's **explicit default/favorite apps and actual CarPlay selection habits** as the place from which they **manually choose an app** when opening the existing CarPlay app picker. It must not infer apps for physical panes, auto-open a default app, or change existing nine layout presets. This is a distinct, independent UX, not a requirement to match the proprietary original DEB.

## Changes written to source

- `DFAppHabits.h` — new independent Foundation-only preference policy. Two versioned on-device files: `com.duoface.nativehost.app-choices.v1.plist` (one default, ordered pins) and `com.duoface.nativehost.app-usage.v1.plist` (successful scene selection counts). Readback after atomic saves; fail-safe invalid input, bundle eligibility, bounded counts and cross-process Darwin notification; no fixed position or window state.
- `DFNativeHostRootController.m` — iPhone **Ứng dụng → Mặc định & Ưa dùng** screen. Select any eligible+enabled installed app; independently set or clear one default, pin/unpin favorites, view real successful previous selection count. No assigning apps to panes; original global .94 enable/disable and 9 presets remain.
- `DFAppPickerVC.m` — list still comes only from `DFAppLibrary installedUserApps` filtered by the existing enabled-app policy. In-app order: default first, explicitly pinned next, higher successfully hosted usage counts, then original inventory order. Registers new notification, refreshes on changes; retains one-app-per-user-tap behavior.
- `DFNative12Chrome.m` — after a **real sceneReady** has committed the pending scene, updates local selection count; never counts failed host scenes, never auto-starts or switches other panes.
- `tests/test_app_habits_096.py` and `tests/app_habits_runtime.m` — source contract and Foundation runtime tests; add runner to `.github/workflows/duoface-native12-source-only-validation.yml`.

Relevant source commits: `7e01d2c`, `c6b7d82`, `c14c41b`, `4dcdb2f`, `60508cf`, `c3ede65f`, `4fb4932`.

## Preservation and verification gates

- The preexisting YouTube .90 rotation, .92 logo 3-second hold, Apple system Dock, existing CarPlay split/solo, Maps experimental mechanism and active scenes are deliberately unchanged by this UX; regression needs actual tests.
- Source is committed; **CI success, macOS Objective-C runtime PASS, signed DEB, Sileo release and physical CarPlay behavior are not yet verified by this report**. Do not confuse source-only with on-device success.
- CI check: macOS Foundation `xcrun clang -fobjc-arc -fblocks -Wall -Wextra -Werror -framework Foundation -I . tests/app_habits_runtime.m` from `sideplay/duoface-native-scene-host` and run executable, plus `python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_app_habits_096.py' -v`, iOS16 arm64 syntax checks.
- No new DEB version or Sileo publisher updated for this requirement. Latest independently verified prior .94 DEB run 40786398702 remains just a previous stage, not proof of this feature.
- Next: inspect source-only run and fix exact failed step; only after green can stage a separately versioned, signed one-DEB artifact with SHA and user approval for Sileo. Parked vehicle tests: default and pin ranking; habits only after ready; toggled off/uninstalled apps not shown; no automatic app opening, no YouTube/Maps/Dock/logo regressions.

The companion workflow `.github/workflows/duoface-096-app-habits-handoff.yml` appends this decision to the existing `sideplay/tiep tuc du an.md` rather than creating a duplicate. Its GitHub push and readback must be verified separately.
