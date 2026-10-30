# 2026-10-30 — Full six real DEB ARM64 crosswalk: what original tweaks really do to phone screen, and what QA130 lacks

## User's request, acceptance and scope
User: "Làm ơn quét kỹ cách làm của các deb khác sao ng ta ko bị mà mình lại bị tối màn hình." Their **physical QA130 result is NO IMPROVEMENT**, Play remains unresponsive when locking iPhone, and DuoFace doesn't show the dim-lit iPhone behavior observed with original OmniCar/DuoNavi while hosting nonnative apps. Apple's hardware AOD is NOT the feature requested. **Do not modify or force brightness/lock yet, and do not confuse screen power with remote touch/scene foreground.**

## Inputs — six actually extracted, immutable SHA-pinned packages
A real CI on GitHub Actions [41057818631](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41057818631) **SUCCESS**, 2026-10-30 12:46:23Z, ran `sideplay/audit/qa130-six-deb-display-callgraph-20261030/trace_original_screen_callers.py` with signed DEB inputs; SHA256 checked each **before** `dpkg-deb -x`, enumerated every Mach-O and resolved ARM64 `adrp/add` dynamic symbol-name references and selected Objective-C methods. Results durably recorded as `MACHO_REFERENCES.json` and `SUMMARY.json` in this **DuoFace repo**, latest checked commit `de948f0f72af000909cfcfba7ea029ece7551684`. The central three ZIPs `01-github-continuity.zip`, `02-ios-deb-ipa-carplay.zip`, `05-research-debug-testing.zip` were SHA checked, tested and SKILL.md read in runner. No original binary distributed in results.

| DEB | Pinned SHA256 | Mach-O | Screen-blank API `BKSDisplayServicesSetScreenBlanked` in package |
|---|---|---:|---|
| Native12-derived technical reference; original Dashboard dylib (NOT untouched vendor stock package) | `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad` | 8 | yes |
| DuoNavi 1.0.4 original | `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd` | 4 | yes |
| OmniCar 1.0.3 original | `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd` | 8 | yes |
| SidePlay 1.0.4-1 original | `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` | 7 | yes |
| DuoDash 1.1.3 available **repack**, NOT byte-verified vendor stock | `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465` | 4 | yes |
| Actual signed DuoFace QA130 (public Sileo) | `d0573ac14e402dfca450e4b01fd57f898ed03852b354361b0a8acf54a432e24b` | 8 | **no** |

**This is a proven structural absence in QA130**: all five reference DEBs carry the screen blank API name; current QA130 lacks it. The other five don't necessarily use identical semantics. The presence of BKS symbol alone DOES NOT prove default backlight brightness, whether any phone remains locked or unlocked, or actual YouTube Play acceptance. Specifically, it **does not prove** that a "brighten screen" patch is needed.

## New machine-instruction proof: actual BLANK and UNBLANK callers; not only strings
From immutable code addresses and bounded original ARM64 sites (stored with context in `MACHO_REFERENCES.json`):

### Native12 original embedded dashboard
- **0x31af0**: `adrp/add` build literal `BKSDisplayServicesSetScreenBlanked`, resolve symbol, null-check, then `mov w0,#1; blr x8` at **0x31b04/0x31b08**. The payload **can call with blank flag 1** on that control branch.
- **0x31da8**: same resolution/null-check, then **`mov w0,#0; blr x8`** at **0x31dbc/0x31dc0**. The payload **can call with unblank flag 0** on another branch.
- Associated iPhone settings app and dashboard each have `setScreenBlankEnabled:` / `screenBlankEnabled` preference selectors. This links the API to a display-state **policy that has both directions**, not a universal always-on display mode. We have not fully traced upstream button/connection conditions or initial default value.
- **Technical detail: Native12's call code is not identical to our source, and vendor licensing/implementation cannot be imported**. The references guide independent acceptance criteria only.

### DuoNavi original dashboard
- **0xae32c**: resolve BKS name, `mov w0,#0; blr x8` at **0xae33c/0xae340**.
- **0x16169c**: `mov w0,#0; blr x8` at **0x1616ac/0x1616b0**.
- **0x1bf0d0**: `mov w0,#0; blr x8` at **0x1bf0e0/0x1bf0e4**.
- Additional symbol locations **0x192e68, 0x1a63dc, 0x1a642c** also resolve BKS, but their bounded control-flow / tail-call needs separate confirmation. These 3 confirmed sites **do show the original code actively reaches a call with unblank flag 0 if that branch executes**, a considerably stronger finding than counting strings. No real device branch activation measured, and unblanking is *not the same as setting the backlight to a faint brightness*.
- Original DuoNavi `CBBridgeManager.acquireCarPlaySleepAssertion` @0x1c05b8 and release @0x1c0650 use IOPM `PreventUserIdleSystemSleep`, which QA130 also uses. Thus **DuoFace merely adding this system-idle assertion cannot reproduce DuoNavi's independent BKS screen-control policy**. Original has distinct `CBWindow` CarPlay CADisplay and app-scene/under-lock coordination too.

### OmniCar 1.0.3 original
- `OmniCarAppBridge.dylib` BKS literal @**0x6f54** and `dlsym` setup at 0x6f5c. This proves it **resolves** the function dynamically (native arm64e metadata issues elsewhere). The sampled BKS site does not independently prove eventual **0** or **1** call or its call timing. `OmniCarSplitScreen.dylib` additionally contains `setPreventsDisplaySleepDuringVideoPlayback:`; presence isn't proof of usage.
- Given user's physical observation while OmniCar is installed, this is a relevant ABI path, **not a verified explanation why their screen is dim**. Need bounded downstream callgraph and matching runtime event/brightness state.

### SidePlay original
- `SidePlay.dylib` contains the BKS C literal. This audit's direct `adrp/add` xref search didn't find a caller for that name; indirect/GOT/chained-fixups may carry it. No proven BKS invocation, let alone screen mode. Do not assert that SidePlay necessarily dims.

### DuoDash 1.1.3 repacked candidate
- `DuoDash.dylib` BKS references @**0x24e74** and **0x52808** visible in ARM64 text. At least one resolves/stores dynamic symbol. Original stock DuoDash SHA from historical notes isn't available byte-exact, so results apply strictly to the accessible **repack**. No full call/argument proof for this package.

### Actual DuoFace QA130
- `DFTouchOwnerProbe.dylib` references `IOPMAssertionCreateWithName` + `PreventUserIdleSystemSleep`, but **NO** original-style BKS blank/unblank symbol or `setScreenBlankEnabled:` toggle in any of its 8 signed Mach-O components. `DFSceneLifecycle.m` has scope-limited under-lock foreground policy, not iPhone screen blanking; `DFSceneHost.m` uses manual `SBAppViewController`; `DFYouTubeOrientationRelay.m` is orientation-only. It does NOT have per-app car-scene frame clock like the unrelated CarSurf project either.
- QA130's previous scope changed a scene-destroy/foreground-owner guard, not power/display policy, so the fact the iPhone did not become dim is **explained by what was *not* implemented**; persistent failed Play may still have a separate cause.

## Independent deterministic regression verification (same six SHA-pinned records)
- Source `sideplay/audit/qa130-six-deb-display-callgraph-20261030/verify_screen_blank_transition.py` commit **`ddc750d3f4ae07dd1ce6775599d2b00deac83a7b`**.
- CI `.github/workflows/duoface-six-deb-display-transition-evidence-test.yml` commit **`5d222d671aa4ab48a054887e139ab190457d8375`**.
- GitHub Actions [41058160513](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41058160513) job **124070831027** **SUCCESS**. It validates 6 exact immutable package SHA values, BKS presence/absence, Native12 `blank=1` and `blank=0` instructions and three DuoNavi `blank=0` indirect calls; independently records what has **not** been verified in OmniCar/DuoDash/SidePlay. The CI writes a JSON verdict artifact, not a patched binary. **No new DEB built or Sileo changed**.

## Decision: fill the proven missing behavior only after caller ownership confirmed
- **Confirmed difference**: original Native12 and DuoNavi contain real screen-blank *and* unblank invocation code; OmniCar has a dynamically-resolved API; QA130 does not. Confirmed other difference: original nonnative app owner/lock policy and app process display clocks are richer than QA130. Current QA130 **never tests or controls the iPhone display blank API**.
- **NOT confirmed**: system activates original BKS calls precisely when a nonnative app is selected and the phone dim glow shows up; whether it keeps phone locked; whether enabling that API alone fixes YouTube Play; actual QA130 per-app touch event ending/foreground.
- Next exact forensic step: resolve original OmniCar AppBridge's **downstream** BKS function-pointer call, the 0/1 argument and connection+app activation precondition; repeat for DuoNavi if relevant, and correlate on-device same-session after real Sileo QA130 loaded UUID. Without identifying the qualifying *selected app + active CarPlay + visible pane* predicate, don't add an unconditional unblank, passcode bypass, full-brightness keep-awake or generalized `UIApplication.sharedApplication.idleTimerDisabled` tweak.
- A reversible, first-party, session-scoped screen policy is potentially justified only after proving a callback and avoiding iPhone battery/thermal and lock security regressions. Under-lock YouTube Play is still a separate acceptance test and physical QA130 verdict remains **NO IMPROVEMENT**.
- A verified implementation would need a unique QA version and real on-car acceptance, plus Apple Dock/Zoom/GOFA/Play/Home/disconnect restore. Currently **NO runtime fix** is claimed.
