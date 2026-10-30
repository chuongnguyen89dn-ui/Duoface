# Manual callback ownership correction — 2026-10-30

Status: local source candidate, not an established device fix. Remote push blocked by automatic approval review. No SDK compile, package, installation or Sileo publish.

## Verified starting point
- Repository: chuongnguyen89dn-ui/Duoface.
- Baseline: a8b334e9694fb88378d59158d26e8502a1436dea, feature/duoface-original-pair-qa127-20261030.
- Local work branch: fix/duoface-manual-observer-contract-20261030.
- Source change commit: 7acca078 (resolve full SHA with git rev-parse).
- Read-only ls-remote confirmed baseline branch a8b334e and main ae5d92d9f10a64260f50f58530168e0f05365bc0. No newer main logs identified. Actions in_progress query returned no runs before work.
- Central Gpt-training- SKILL_INDEX, AGENTS, PROJECT_INSTRUCTIONS, DEB_IPA_SKILL and actual base64 ZIPs 02 / 05 were read and decompressed this turn. Git blob IDs: 14978becab3e5bcab39b160fda1dae848dc28101 and 93fef0e87cbc3f066eac201ee49d4e6530e2a511.

## Concrete source defect and evidence boundary
DFSceneHost.m registers an owner probe which returns nil when surface.window is nil/hidden or child window differs. DFSceneLifecycle.m previously used that SAME probe to decide whether SBAppViewController was manually managed. However, the controller still has automatesLifecycle=NO during a temporary detach. The observer then forwards to automatic Apple handling solely because presentation changed. It can also happen before pollScene accepts a replaced scene (350ms poll interval).

The original Native12 ARM64 report sideplay/audit/native12-foreground-hooks-20261027/HOOKS_AND_ARM64.json, scene_observer at 0x2c8ca8, confirms controller-associated identity/manual lifecycle rather than window visibility controls its automatic observer path. Independent source implements its own current-handle restriction; no vendor markers or binaries copied.

IPS analysis in qa125-crosslog-rootcause-20261030 proves Apple observer was reached through our wrapper, but does NOT prove which old guard rejected it. Thus this counterexample is a verified source-contract flaw and a testable crash candidate, NOT a proved explanation of every physical crash.

## Implemented change
Only callback admission changes. A registered controller, current incoming handle with an existing scene, and valid no-argument BOOL automatesLifecycle returning NO owns the callback independently of visibility. Off-main, foreign/unregistered controllers, obsolete handles, absent scenes and automatic controllers still forward. ABI check additionally verifies getter argument count and exact B/c return type.

The presentation owner probe still gates foreground rewriting and under-lock exceptions with the original window/scene/session checks. Home/disconnect teardown, unregister ordering, rotation QA90, divider QA92, Dock QA120 and all geometry remain unchanged. No new hook or scene-destroy behavior introduced.

## Validation actually performed
From repository root:

    cc -std=c11 -Wall -Wextra -Werror sideplay/duoface-native-scene-host/tests/manual_observer_contract_test.c -o /tmp/df-observer-contract
    /tmp/df-observer-contract

PASS: 64 ownership/ABI/input combinations x two visibility states = 128. Test executes the actual shared C predicate used by Objective-C. The detached registered manual current-handle case fails the modeled old presentation-dependent condition and passes the new one. This is an abstract contract test; it does not simulate UIKit or prove callback identity on iPhone.

34 existing Python tests PASS across seven suites; exact commands/output in LOCAL_VALIDATION.txt. These are source/policy/geometry checks, not UI or Play tests. git diff --check PASS.

No local xcrun/iPhone SDK. A new isolated macos-15 workflow is prepared to syntax-check DFSceneLifecycle.m against the real iPhone SDK and run the same tests. Workflow does not package, deploy, archive a binary or modify Sileo. It has NOT RUN.

## Blocker
Automatic approval review rejected git push to the new work branch, stating that remote source/workflow publication was not authorized. No alternate connector/write route attempted. Local commits are not durable GitHub handoff. Need explicit approval to push the reviewed source, tests, workflow and this existing handoff. No secrets added.

## Remaining risks and next execution
1. After approval, read remote branch/head; push this work branch only; inspect macOS contract workflow. Do not rebase over another session blindly.
2. Confirm source compile before producing a package. Production version remains QA127; DO NOT package this candidate with that version. Any future signed candidate needs its own version and explicit packaging decision.
3. This patch still forwards callbacks for stale/missing handles, and after unregister. A crash on one of those paths is not fixed. New current scenes are recognized for callback ownership before geometry poll admission; no foreground or frame privilege is granted by that fact. Match real controller/handle/scene data before broadening further.
4. Global foreground rewrite, missing scene-destroy coordination, phone-lock vs CPTemplate background, touch transport and GOFA viewport acceptance remain unresolved. Do not combine speculative changes into this candidate.
5. Before device attribution, verify actual installed and loaded Mach-O UUID. Next matched session must capture current owner/handle/scene at rejected callback and exception reason. Successful acceptance requires no crash on lock/Zoom, Play with screen on/off, no spontaneous gestures, correct Home/unplug cleanup and reconnect. No device PASS exists.
