# Original post-lock helper decoded; independent candidate staged

Baseline f84e27a9; public QA128 untouched. This turn read actual original DEB from dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb, checked DEB SHA f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd, extracted with dpkg-deb, checked Dashboard SHA 44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15. No original binary executed or modified.

## New exact result
LC_FUNCTION_STARTS bounds helper 0x2eca50..0x2eced8: all 290 ARM64 instructions decoded. intercept 0x2ed954..0x2eda64: 68 instructions. See ORIGINAL_POSTLOCK_AND_OWNER_ARM64.json. Helper applies positive target frame when needed, foreground YES, occluded NO, underLock NO, canShowWhileLocked YES, deactivationReasons 0 and idleModeEnabled NO. It contains raw-ivar fallbacks. It does NOT synthesize touches, call Play or directly deliver input. Original intercept calls Apple's IMP first, then checks bridge owner and extra eligibility before applying helper on settings. This is additional post-lock normalization, not another boolean under-lock predicate.

Also decoded full LC_FUNCTION_STARTS-delimited CBWindow show/hide/dismiss/activeCarPlayWindow and bridge manager dismiss/connection/screen callbacks. Direct show/hide use window visibility/animation; connected screen callbacks check actual CarPlay display. However these bodies have dynamic dispatch and block callees: the exact original lock-vs-Home discriminator is NOT established by these functions alone. Do not infer that external display presence means DuoFace is foreground on CarPlay Home.

## First-party implementation, staging only
DFSceneLifecycle.m adds independently implemented interceptUpdateForScene:withNewSettings: with runtime void/two-object ABI validation. Original IMP called exactly once before owner gating. Only existing strict current scene/manual controller + external visible window + fresh live session gate can apply typed BOOL setters with readback: foreground YES, occluded NO, scene underLock NO, canShowWhileLocked YES, idle NO. No frame change, no raw ivars, no device/passcode/activation hooks, no copied vendor markers or binary methods. A destroyed/stale/foreign/revoked scene receives Apple's original behavior only.

Not full vendor equivalence: deactivationReasons is NOT zeroed because reason-bit semantics and current blockers are unproven; original raw-ivar fallback deliberately omitted. The CPTemplate background stop/recreate path found in Audit13 is NOT altered. Therefore this candidate cannot be called a complete locked Play/input fix. Public QA128 crash and GOFA user PASS remain the accepted baseline.

## Verification
Local: decoder exact-SHA PASS, all 10 chosen functions fully decoded by LC_FUNCTION_STARTS, wrong-input SHA rejection PASS (ValueError: wrong original binary SHA256), py_compile PASS; 3 new static integration gates and 5 underlock source gates PASS; diff whitespace PASS. Initial scanner attempt included a very large sendStateToApp method and stopped with 'incomplete function' due prior parser instruction cap; that unrelated target was removed, not falsely reported as full decode.

Parser provenance: existing first-party tooling from Duoface feature/visual12-duodash-recovery migration/full_payload/native_test; Git blobs audit_native12_license_class_xrefs.py=71f1816984439363f2b93de0c2aec7ac22c867ae; audit_native12_carplay_add_app_chain.py=745bcc34fdada0361c83d6d7aa14dca12520b7be. Capstone 5.0.7 installed in /tmp/duoface-capstone. Parser files in /tmp/duoface-parser, extract in /tmp/duonavi-current-ref; reproducible command from repo root:

    PYTHONPATH=/tmp/duoface-capstone python3 sideplay/audit/qa128-postlock-helper-20261030/inspect_original_postlock.py --binary /tmp/duonavi-current-ref/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib --parser-dir /tmp/duoface-parser --out sideplay/audit/qa128-postlock-helper-20261030

Isolated branch fix/duoface-postlock-settings-20261030 runs existing SDK syntax/contract workflow only; QA128 packaging workflow matches another branch, so this source MUST NOT be packaged as 0.0.128. Need separate version only if later authorized/released. No DEB, Sileo or physical test in this turn.

Next: inspect real SDK result; finish exact native owner/Home transition and deactivation-reason evidence before deciding a signed candidate. Do not undo QA128 crash admission correction, touch geometry, GOFA map size, divider or Dock.
