# Build .87 Native12 YouTube handshake — 2026-10-28

Previous full run 40650496428 passed all runtime tests but failed linking new receiver: undefined CGPointZero. Add explicit CoreGraphics dependency; source gate now performs a real arm64 dylib link too. Native12 arguments remain portrait=1, updateStatusBar=NO, duration=0, skipCallbacks=YES. Build current source ONE integrated rootless DEB, verify exact YouTube-only payload, archive checksums and existing handoff. No Sileo publication or device success claim. Maps/Dock/.83 lifecycle untouched.

Build marker: 087-coregraphics-link-fix-3.
