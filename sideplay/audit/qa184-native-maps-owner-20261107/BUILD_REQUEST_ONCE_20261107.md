# Manual QA184 one-time signed build request — 2026-11-07

User explicitly authorized: "Hãy đóng gói và ký DEB QA184 tích hợp, kiểm tra đầy đủ và gửi file để tôi thử trên xe. Chưa phát hành lên Sileo."

This single sentinel change triggers only `.github/workflows/duoface-184-nativeowner-signed-once.yml` on the QA184 branch. It is not a standing auto-packaging workflow: no code change is in its trigger path. Once artifact succeeds, disable the one-shot push path and keep only `workflow_dispatch`, so future packaging remains manual-only.

Package: `com.duoface.jb.embedded`, version `0.0.184~nativeowner1`. NativeHost `0.1.184~nativeowner1`. This test package replaces the current DuoFace QA182 by package identity only if the user elects to install it; no Sileo deployment. All Apple-native, native Home, H1/keyboard, and watchdog safety gates stay in scope. Real vehicle pixels and split acceptance are not proven by CI.
