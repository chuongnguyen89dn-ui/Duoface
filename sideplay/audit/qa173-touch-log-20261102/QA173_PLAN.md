# QA173 — touch + log reduction (from QA172)

Scope fixed by the user on 2026-11-02: ONLY the three items below.
The QA172 GOFA decoder stays in shadow mode; bubble speed stays GPS.

1. Log reduction (done in code): DFDeepTrace de-duplicates identical
   repeats within 5s and rotates at 256 KiB (was 2 MiB); the per-module
   log files (DuoFaceTouchOwner.log, DuoFaceSceneHost.log) now append
   through DFLogGuard173.h (same de-dupe + 256 KiB rotation to .old);
   the per-layout `resize` scene line is state-change-only. Export
   diagnostics (QA167/QA172 summaries, traffic-nav log) are untouched.
   Background: system report 2026-11-02 showed the CarPlay process
   writing ~1,073 MB in ~6 hours.
2. Hosted-app touch (YouTube): DFSceneHost commits remote scene
   geometry in the same layout pass (was a 0.30s / 0.12s one-shot
   timer); DFNative12Chrome adds a root-window touch fall-through for
   DuoFace's own external windows (hit resolving to the bare root
   container returns nil), gated by preference
   com.duoface.nativehost.qa173.plist key RootTouchPassThrough
   (absent = ON; set 0 + respring = OFF). No other app behavior is
   changed; the GOFA/YouTube geometry relays are untouched.
3. Waze icon on the native CarPlay Home: NOT fixed in code. Project
   records (DFHomePublisher136Core.m, DFCarPlayHomeCatalogPolicy.h)
   establish the native roster is owned by iOS; DuoFace never rewrites
   native membership, and native apps can be excluded by CarPlay's own
   Home/Settings icon policy. User-side check: iPhone Settings >
   General > CarPlay > car > Customize.

Versions: host 0.1.173~touchlog1, integrated 0.0.173~touchlog1.
State: DEVICE_TESTED=false until the user drives it.
