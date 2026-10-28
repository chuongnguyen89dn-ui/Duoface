# Build request — .87 Native12 YouTube app handshake — 2026-10-28

Stage one integrated rootless 0.0.87~ythandshake1 DEB from this exact source. First gates 40650190891 and 40650190759 passed. Final original ARM64 cross-check confirms updateStatusBar=NO, duration=0, skipCallbacks=YES at 0x2aa108/0x2aa10c; executable mock now asserts these exact arguments. Run fresh tests, compile, sign, verify exact YouTube-only filter and preserve artifact/checksums/handoff. No Sileo or device-success claim.

Build marker: 087-native12-exact-callback-arguments-2. Supersedes initial run 40650319400; concurrency cancels the obsolete candidate. Maps/Dock/.83 lifecycle unchanged.
