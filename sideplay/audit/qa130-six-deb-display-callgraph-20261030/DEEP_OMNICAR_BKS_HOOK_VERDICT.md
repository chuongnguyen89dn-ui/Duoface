# 2026-10-30 — Confirmed real OmniCar BKS interception, branch-by-branch, not a mere selector string

## Scope & immutable evidence
User asked to keep scanning deeper into original DEB **functions and instructions**. We did NOT modify QA130 or its Sileo publisher. Existing public signed QA130 `0.0.130~sceneowner1` has **user-confirmed NO IMPROVEMENT** for locked YouTube Play/touch and phone display, and does not implement original BKS screen blank owner. Six original/reference DEB comparison is `REPORT.md`; this extension targets the actual **OmniCar 1.0.3** dynamic screen blank interceptor and original callable.

Real signed original DEBs:
- OmniCar 1.0.3 SHA256 **`d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`**
- Native12-derived technical reference SHA256 **`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`** (contains pinned original Dashboard but DEB not untouched vendor stock)
- DuoNavi original 1.0.4 SHA256 **`f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`**
- User's published QA130 SHA256 **`d0573ac14e402dfca450e4b01fd57f898ed03852b354361b0a8acf54a432e24b`**, unchanged.

## Two deep real-CI runs (all steps succeeded)
1. First [GitHub Actions **41059116740**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41059116740) **SUCCESS**, original SHA verified, Capstone ARM64 disassembly. Second [**41059287176**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41059287176) **SUCCESS**, expands separate BKS `0` path and persists **`DEEP_BKS_ARM64.json`** to DuoFace repo. Source `trace_omnicar_bks_hook_deep.py` commit `7c234dceea4c4d9fc904387d7182f16723ba4297`, expanded `31c0b5b392aa616d2e60cc49558ce9abe8c11877`; workflow `.github/workflows/duoface-omnicar-bks-original-interceptor-deep-audit.yml` commit `0a4a374cf9a773b704b4d82759ec35ac5093b12e`. ZIPs `02-ios-deb-ipa-carplay.zip` and `05-research-debug-testing.zip` SHA checked, extracted SKILL.md read in the actual CI runner, original packages verified. No vendors' proprietary source copied; only original-code disassembly windows and independent interpretation saved.
2. Independent control-flow assertion `validate_omnicar_bks_intercept.py` commit `1da300337cbc83df5009ecf711cf590da688054d`, `.github/workflows/duoface-omnicar-bks-hook-machine-proof.yml` commit `d4e2f6046e638fb145729782c0febe729be6d82e`, [GitHub Actions **41059485677**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41059485677) **SUCCESS**, job **124075330680**. Exact six branch and argument assertions passed, not hardware QA. The full decoded original addresses/instructions are in `DEEP_BKS_ARM64.json`.

## Confirmed ARM64 flow in original OmniCarAppBridge.dylib

### Hook installation of system BKS symbol, NOT a direct BKS invocation
- At **0x6f54**, `x1` is the literal address of `BKSDisplayServicesSetScreenBlanked`.
- **0x6f58** sets `x0=-2` (consistent with RTLD_DEFAULT), **0x6f5c** calls the dynamic lookup stub. Return 0 skips the installation at **0x6f60**.
- On resolved symbol, **0x6f68** sets replacement function `x1=0x777c`; **0x6f70** provides **original function pointer storage address** `x2=0x3ea10`; **0x6f80** branches to a three-argument hooking stub `0x243e0`. That imported stub has not yet been identified via a fully decoded dyld bind symbol; its semantics are consistent with a function interpose/trampoline. **Do not claim this initial site directly lights the screen**.

### Hook replacement at 0x777c explicitly reads the requested blank state
- **0x778c** `mov x19,x0` stores caller's requested blank flag.
- **0x7790** `cmp w0,#1`, **0x7794** `b.ne #0x780c`: any request not equal to 1 is passed to the saved original.
- For request 1, replacement invokes additional original library methods/condition checks; at **0x77c0**, `cbz x21,#0x780c` skips supplemental handling if the internal condition is false. **Predicate meaning is not decoded yet.**
- On the checked branch **0x77c8** loads saved original `[0x3ea10]`, then **0x77cc mov w0,#1; 0x77d0 blr x8** calls actual BKS with flag **1**, then executes additional I/O/notification calls and returns zero. Not a general suppression of screen blanking!
- On skipped/ordinary branch **0x7810** loads saved original pointer, **0x7814 mov x0,x19; 0x7824 br x1** forwards the **original requested blank value** unchanged.

### A separate original callback can issue UNBLANK=0
- A separately referenced path at **0x9688** resolves original pointer address, **0x968c** loads it, **0x9690 mov w0,#0**, **0x9694 br x1** tail-calls the original **BKS with flag 0**.
- At **0x958c..0x9664** the same nearby function range performs other work and branches, but there are intervening entries and branch targets **0x9668/0x966c/0x9670**. The exact upstream **CarPlay connection state, app bundle, phone brightness and when this code executes** are NOT yet established from the bounded binary alone. Do not claim all CarPlay connections invoke this unblank.
- This proves original OmniCar has **both an actual BKS function interceptor and a separate original BKS unblank path**, not merely a string reference. Original Native12 additionally has explicit 1/0 BKS sites, and DuoNavi many 0 sites (see six-DEB report).

## Why the finding matters — and what it DOES NOT prove
1. DuoFace QA130 does NOT install a comparable original BKS interceptor or independently call unblank. It does retain `PreventUserIdleSystemSleep`, a DIFFERENT power assertion that does not keep the main iPhone backlight awake. Therefore the previous QA130 repair of scene registration/foreground does NOT address this cross-DEB missing subsystem.
2. **Do not infer the exact faded iPhone Lock Screen state from BKS blank=0**; unblank may let the screen return to current iOS display brightness policy, and CarPlay dimness can involve a different handler, display ownership or app-specific frame clock. Screenshots cannot indicate source of power/scene.
3. No same-session user QA130 logs prove the touch-to-Play event reaches YouTube. It is possible the original screen policy correlates with, but is not the cause of, remote app activation and input delivery. Current device evidence says QA130 STILL FAILS. No new DEB or Sileo release happened in this scan.

## Next exact bounded investigations
- Resolve **import/binding of stub `0x243e0`** and **the condition-producing call `0x25420` / original callback's `x21`**, rather than guessing its purpose. Decode upstream callers of `0x9688..0x9694` using actual method boundaries, and preference gating for Native12 `screenBlankEnabled`. Determine if the 0 call happens on connect, disconnect, backlight wake, supported versus bridged app, or UI transition.
- Test any independent first-party mechanism only with an exact owned CarPlay session predicate, known screen policy, restoring original state on Home/disconnect, safe device lock/battery behavior, and a new signed QA version after arm64 ABI tests. Never blindly force iPhone unlocked or maximum brightness.
- Obtain same-session physical QA130 loaded UUID and remote gesture ACK before claiming Play fixed. Protect QA90 orientation, QA92 bar, QA120 Apple Dock, QA128 user-verified GOFA size; system CarPlay Home selected-app icon publisher remains separate incomplete feature.

**No source tweak/publisher was changed**, only reproducible forensic programs, CI workflows and this audit. 
