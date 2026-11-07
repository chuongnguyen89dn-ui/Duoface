# Manual QA184 one-time signed build request — 2026-11-07

User explicitly authorized: "Hãy đóng gói và ký DEB QA184 tích hợp, kiểm tra đầy đủ và gửi file để tôi thử trên xe. Chưa phát hành lên Sileo."

This single sentinel change triggers only `.github/workflows/duoface-184-nativeowner-signed-once.yml` on the QA184 branch. It is not a standing auto-packaging workflow: no code change is in its trigger path. Once artifact succeeds, disable the one-shot push path and keep only `workflow_dispatch`, so future packaging remains manual-only.

Package: `com.duoface.jb.embedded`, version `0.0.184~nativeowner1`. NativeHost `0.1.184~nativeowner1`. This test package replaces the current DuoFace QA182 by package identity only if the user elects to install it; no Sileo deployment. All Apple-native, native Home, H1/keyboard, and watchdog safety gates stay in scope. Real vehicle pixels and split acceptance are not proven by CI.

## Build retry after code-version test mismatch
- First user-authorized run 42336895085 failed during prebuild QA180 version assertions, before building/signing any binaries. Source-only companion 42336894822 failed the same stale assertion. QA182/H1 implementation was not changed and the version in two actual log stampers needed QA184 update.
- Follow-up source commit updates exact runtime log stampers `DFDeepTrace.h` and `DFTouchOwnerProbe.m` to `0.0.184~nativeowner1` and adjusts only QA180/QA179/QA188 test expectations to current package version. All frozen behavior remains unchanged. This same one-shot build request marker is intentionally modified to trigger exactly one retry on the same QA184 branch. The signed workflow push path now matches ONLY this marker (not workflow file nor generic source changes).
