# Manual QA184 one-time signed build request — 2026-11-07

User explicitly authorized: "Hãy đóng gói và ký DEB QA184 tích hợp, kiểm tra đầy đủ và gửi file để tôi thử trên xe. Chưa phát hành lên Sileo."

This single sentinel change triggers only `.github/workflows/duoface-184-nativeowner-signed-once.yml` on the QA184 branch. It is not a standing auto-packaging workflow: no code change is in its trigger path. Once artifact succeeds, disable the one-shot push path and keep only `workflow_dispatch`, so future packaging remains manual-only.

Package: `com.duoface.jb.embedded`, version `0.0.184~nativeowner1`. NativeHost `0.1.184~nativeowner1`. This test package replaces the current DuoFace QA182 by package identity only if the user elects to install it; no Sileo deployment. All Apple-native, native Home, H1/keyboard, and watchdog safety gates stay in scope. Real vehicle pixels and split acceptance are not proven by CI.

## Build retry after code-version test mismatch
- First user-authorized run 42336895085 failed during prebuild QA180 version assertions, before building/signing any binaries. Source-only companion 42336894822 failed the same stale assertion. QA182/H1 implementation was not changed and the version in two actual log stampers needed QA184 update.
- Follow-up source commit updates exact runtime log stampers `DFDeepTrace.h` and `DFTouchOwnerProbe.m` to `0.0.184~nativeowner1` and adjusts only QA180/QA179/QA188 test expectations to current package version. All frozen behavior remains unchanged. This same one-shot build request marker is intentionally modified to trigger exactly one retry on the same QA184 branch. The signed workflow push path now matches ONLY this marker (not workflow file nor generic source changes).

## User-requested PRESENTED diagnostic package — 2026-11-07
- Latest user: “Chưa có deb thì làM j?” — proceed to build/sign/check/deliver private integrated diagnostic DEB now. No Sileo.
- New version 0.0.184~nativeowner2diag1; NativeHost 0.1.184~nativeowner2diag1. Exact diagnostic code 43f973ff29e9cf013e5acbe1d6303fd4bf037197 passed source CI 42340063112. This build adds only synchronized version labels/tests and exact linked diagnostic-marker verification.
- Reuse existing user-request marker one-shot mechanism because connector has no workflow_dispatch capability and browser is signed out. No credential access requested. Trigger matches this path, branch and exact request commit message only. Restore workflow_dispatch-only immediately after run registration.
- No in_progress/queued jobs observed before this request. Preserve AppDelegate background/heartbeat and all admission predicates; no Home fix claimed. Verify binary markers, Mach-O signatures, metadata, SHA256 and durable archive before delivery.

- Attempt aab8082/run42340591501 failed YAML parsing before jobs; folded exact-message guard fixed.
- Attempt ea28831/run42340641150 job128307335550 passed QA184 source/package and QA182 behavioral tests, failed stale QA182 Version literal before toolchain/build. Exact error: AssertionError: 'Version: 0.1.184~nativeowner1' not found. Update remaining QA182 and integrated144 version expectations only; no behavior test removed or weakened. Re-run authorized diagnostic build.

## QA185 admission1 authorized signed build + Sileo candidate
- User now explicitly orders fix/build/CI/package/publish Sileo. Source-only CI42343003298 job128314620140 SUCCESS on1d75be7715d77d30082f4b8077971241ee318a31 (all source contracts,31 new launch/Home +44 receipt +35 lease cases, iOS16 arm64 syntax).
- Produce0.0.185~admission1; exact real native launch identity for PRESENTED, view hidden/alpha after admission, watchdog/Home/AppDelegate frozen. No claim of hardware PASS.
- Same scoped once-only request marker. Restore manual-only immediately after registered signed job. After verified artifact, archive unchanged signed DEB in duoface-debs- and publish via existing carplaydsp workflow with pinned SHA, preserve QA182 rollback. Acceptance remains actual COMMITTED, sustained minutes, correct touch.
