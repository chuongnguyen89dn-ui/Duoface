# DuoFace DIAG3: CarPlay app launch policy (iPhone X, iOS 16)

This is an isolated rootless diagnostic package. It upgrades only `com.duoface.diagnostic` v0.2.0~diag2 to v0.3.0~diag3 and does not replace DuoFace, Speed8 or CarPlay.

New user observation on iPhone X: every app that does **not** officially support CarPlay also fails to open, while official CarPlay apps work. This changes the hypothesis from DuoFace-only window creation to a shared unofficial-app launch policy/interception gate.

DIAG3 adds **passive** return-value tracing for the existing DuoFace class methods `isOfficialApp:`, `isBridgedApp:`, `shouldInterceptLaunchForApp:`, `isDashboardPolicySignalActive`. It verifies Objective-C signature before hooking, calls original once and returns its unmodified BOOL result. It also preserves DIAG2 icon-activation and SpringBoard state traces. No UI changes, forced activation, permissions reset or preference deletion. The `app` field contains only a validated bundle identifier or class placeholder; no arbitrary object descriptions.

Test only on failing iPhone X, with car parked: install package locally, respring, connect CarPlay; tap one **official supported app**, then one **nonofficial app**, then DuoFace, keeping ~5s between attempts. Note app names/order/time. Keep CarPlay connected at least 30s. Collect both `/var/mobile/Library/Logs/DuoFaceDiagnostic3-CarPlay.jsonl` and `DuoFaceDiagnostic3-SpringBoard.jsonl`; earlier DIAG2 files are not used. Log may be rotated to `.previous` after 3MiB. `POLICY_HOOK_INSTALLED` must exist before interpreting results. If policy hooks do not fire for the nonofficial app, that does not prove a denial; the launch path may bypass DuoFace class entirely.

If errors occur, remove only `com.duoface.diagnostic`, respring. Leave working iPhone 8 Plus untouched. GitHub Actions success verifies build/package, not device behaviour. No automatic Sileo publication.
