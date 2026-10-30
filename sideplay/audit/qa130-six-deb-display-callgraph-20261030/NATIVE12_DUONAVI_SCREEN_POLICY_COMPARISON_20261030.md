# 2026-10-30 — Original Native12 vs DuoNavi display policy, exact ARM64 defaults and guarded delayed unblank

## Purpose and provenance
This is an independent static comparison answering the user's request to scan exactly how original Native12 and DuoNavi handle display state instead of guessing or forcing a backlight hook in QA130. No vendor code/authorization/licensing imported into independent DuoFace. No iPhone runtime, crash, Play, touch or Sileo changes.

**Immutable source packages:**
- Native12-derived DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. Contains SHA-matched original Dashboard payload, but full outer DEB is a derived technical reference, **not untouched stock Native12**.
- Original DuoNavi 1.0.4 DEB SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`; original `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
- Related actual OmniCar original 1.0.3 mechanism: `OMNICAR_ONE_SECOND_BKS_UNBLANK_ORIGINAL_FUNCTION_PROOF.md` — active-host-panes BKS(1), then dispatch_after 1 second on main queue, BKS(0) callback.

## 1. Both Native12 and DuoNavi initialize `screenBlankEnabled` to TRUE

**Proven at actual original constructor machine instructions**, not an assumption based on property spelling:

| Original image | `CBDashboardSettings -init` | Getter | ARM64 proof |
|---|---|---|---|
| Native12 original Dashboard (derived DEB) | `0x360e0 mov w8,#0x100`; `0x360e8 str w8,[x19,#8]` | `0x37ec0 ldrb w0,[x0,#9]` | Byte +9 becomes `1` in little-endian |
| DuoNavi 1.0.4 Dashboard | `0x2d574 mov w20,#0x100`; `0x2d578 strh w20,[x19,#8]` | `0x2f48c ldrb w0,[x0,#9]` | Byte +9 becomes `1` in little-endian |

Their respective setter writes that same +9 byte (`Native12 0x37ec8`, `DuoNavi 0x2f494`). **This establishes initial object default, not current persisted settings after `reload` / `reloadAppPrefs`.** No packaged plist entry matching screenBlank was discovered among scanned plists. Do not claim user device has that setting enabled or that default implies always-on.

## 2. Both have real original BKS calls, not just strings

**Native12 original Dashboard**:
- `0x31af0` dlsym literal BKS; `0x31b04 mov w0,#1;0x31b08 blr x8` = BKS blank 1.
- `0x31da8` same symbol; `0x31dbc mov w0,#0;0x31dc0 blr x8` = BKS unblank 0.
- These are gated by actual branch predicates in disassembly around `0x31aa0…0x31ae8` and `0x31d58…0x31da0`. Nearest preceding ObjC IMP `CBAssistantManager -processVoiceCommand:` is only a bound; we have **not proven specific triggering command or actual CarPlay event**.

**DuoNavi original Dashboard**:
- Multiple original dynamic BKS 0 calls at `0xae340`, `0x1616b0`, `0x1a63f4`, `0x1a6444` and `0x1bf0e4`. The last falls within `CBBridgeManager -deactivateCurrentApp` according to surrounding ObjC IMP boundaries and method metadata, but whether physically invoked requires device logs.
- A distinct BKS(1) branch is now machine-verified at `0x192ec0 mov w0,#1;0x192ec4 blr x22`, with pointer obtained from `dlsym` around `0x192e68..0x192e80`. There is also a BKS(0) branch at `0x192f30 mov w0,#0;0x192f34 blr x22`. Selection depends on upstream ObjC/scene predicate. Do not call this a universal screen-awake setting.

## 3. DuoNavi has THREE explicitly scheduled, conditional delayed callbacks — original GCD imports proven

From signed DuoNavi binary LC_SYMTAB/LC_DYSYMTAB:
- `0x3135c4` = imported **`_dispatch_time`**, `0x31354c` = imported **`_dispatch_after`**; main queue GOT `0x370168` = **`__dispatch_main_q`**.
- After the conditional BKS(1) branch, `0x192ecc/0x192ed0` loads `0x1dcd6500` = **500,000,000 ns (0.5 s)**; schedule `0x192f20` with captured callback `0x1a636c`.
- Alternative BKS(0) branch at `0x192f30/0x192f34`; code then converges and schedules **300,000,000 ns (0.3 s)** (`0x192f3c/0x192f40`, `0x192f90`) with callback `0x1a63b0`.
- The same continuation also schedules **800,000,000 ns (0.8 s)** (`0x192fa0/0x192fa4`, `0x192fe0`) with callback `0x1a6400`.
- Callbacks `0x1a636c`, `0x1a63b0`, `0x1a6400` examine Objective-C selector **`isUIAppBridging`** (literal SEL pointer at `0x3a8cf0`) before conditional BKS(0). This is a **bridged UI app-dependent** display transition, not an unconditional global display unblank.
- All these addresses and guard instructions were checked against real SHA-pinned original disassembly. Actual timer execution on the user's iPhone, brightness level and remote app Play acceptance **are not established**.

## 4. Concrete comparison with current DuoFace QA130

| Feature | Original OmniCar | Native12 original Dashboard | DuoNavi original 1.0.4 | Current DuoFace QA130 |
|---|---|---|---|---|
| System BKS blank/unblank handling | MSHookFunction intercepted; 1s delayed original BKS(0) if hosted pane count nonzero | Explicit BKS(1) and BKS(0) original callers | Explicit BKS(1/0), 0.5s / 0.3s / 0.8s guarded callbacks, `isUIAppBridging` | **Absent** in compiled source audit; uses `PreventUserIdleSystemSleep` assertion only |
| Object screen-blank property initialized true | Not proven for same property | **YES** (source byte +9) | **YES** (source byte +9) | No analogous property |
| Hardware evidence of dim/Play | No physical test this audit | No physical test this audit | No physical test this audit | **User QA130 FAIL / no change** |

**Interpretation**: References share a real concept of display-state transitions conditioned on bridged/non-native app state, though implementation differs. This strongly supports testing a reversible session-scoped display policy in our independent project. The data **does not prove** that a faint backlight state itself delivers the missing remote YouTube Play touch: real pane scene clock, under-lock foreground and touch-ACK may be independent.

## Actual execution and reproducibility
- Workflow `.github/workflows/duoface-omnicar-bks-original-interceptor-deep-audit.yml` at commit `5865a62180eadb94918bd88aea0f0ce321e72fbf` fetched 3 immutable reference DEBs (SHA checks), central ZIP `02-ios-deb-ipa-carplay.zip` and `05-research-debug-testing.zip` (SHA/integrity/read `SKILL.md`), Capstone ARM64 parser, and ran:
  - `python3 sideplay/audit/qa130-six-deb-display-callgraph-20261030/audit_native12_duonavi_screenblank_preferences.py --Native12Derived "$RUNNER_TEMP/debs/native12.deb" --DuoNavi104 "$RUNNER_TEMP/debs/duonavi.deb" --out "$RUNNER_TEMP/omnicar-bks/NATIVE12_DUONAVI_BKS_PREFS.json"`
  - `python3 sideplay/audit/qa130-six-deb-display-callgraph-20261030/trace_duonavi_original_delayed_display.py --deb "$RUNNER_TEMP/debs/duonavi.deb" --out "$RUNNER_TEMP/omnicar-bks/DUONAVI_ORIGINAL_DISPLAY_TIMER.json"`
  - `python3 sideplay/audit/qa130-six-deb-display-callgraph-20261030/verify_native12_duonavi_screen_policy.py --prefs "$RUNNER_TEMP/omnicar-bks/NATIVE12_DUONAVI_BKS_PREFS.json" --duonavi "$RUNNER_TEMP/omnicar-bks/DUONAVI_ORIGINAL_DISPLAY_TIMER.json" --out "$RUNNER_TEMP/omnicar-bks/NATIVE12_DUONAVI_SCREEN_POLICY_VERIFIED.json"`
- **[GitHub Actions run 41064820220](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41064820220)** job **124093363776** **COMPLETED SUCCESS** (2026-10-30 13:38:21 UTC). CI checkout commit `5865a621`; generated evidence saved via working branch GitHub push at saver commit **`cb4c3509`** (read full SHA if required). SHA readback blob of independently verified artifact `NATIVE12_DUONAVI_SCREEN_POLICY_VERIFIED.json`: **`1d667b2d780ef7b601d7ca29fd179b2ec114715c`**. Full bounded source evidence `NATIVE12_DUONAVI_BKS_PREFS.json` and `DUONAVI_ORIGINAL_DISPLAY_TIMER.json` also persisted on same project branch.
- Other verified successes: Native12/DuoNavi initial SHA-pinned scan [41063746254](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41063746254), settings-init expansion [41063983123](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41063983123), DuoNavi callbacks [41064292990](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41064292990), after 0.3/0.8 selector discovery [41064441827](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41064441827), main queue readback [41064634144](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41064634144) all SUCCESS.

## Next executable decision, not yet an implementation
1. Use existing first-party QA130 log + matching SpringBoard IPS and loaded UUID for **same-session under-lock** input: YouTube actual UITouch/Play ACK, app scene active/foreground and phone backlight policy. User already reports Play fails and there is no slight phone screen glow; cannot infer causality from symptoms alone.
2. Once correlated, design independently scoped **opt-in and reversible** display policy (only active non-native CarPlay pane/host, fail-close on Home, disconnect, scene death; do not copy vendor binaries or license, do not defeat passcode/always unlock). Use smoke tests and rollback package before any QA release; retain QA90 rotation, QA92 divider, QA120 native Dock, QA128 GOFA sizing.
3. Real CarPlay Home app icon publisher remains separate incomplete feature. No new QA build/DEB or Sileo publish performed by this static forensic audit.
