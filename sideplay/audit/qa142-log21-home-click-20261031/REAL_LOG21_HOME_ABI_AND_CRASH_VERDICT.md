# QA142 — real iPhone Log21, 2026-10-31: selected Home icon tap still does not activate an app

## Exact source and reproducibility
- USER device report: six chosen third-party icons appear on genuine CarPlay Home but taps do NOT open their apps; **never overwrite this observation with CI build success**.
- Project `chuongnguyen89dn-ui/Duoface`. Original latest user upload in **main** commit `b495e90a8d25f9c65802cf7ef040fe4f4c0aba54` (distinct from feature branch); `sideplay/log/DuoFaceAudit 21.txt`, Git blob `595cff0e687825008bc443e2a1d2bcc63560b3f5`, **6,370,307 bytes, 35,067 lines, SHA256 `45408726bce40fcf7193c615968891dddad1f86ea5a2146324d81617bf876ac1`**. Export header 2026-10-31 06:19:13 UTC = 13:19:13 ICT. Device iPhone X iOS 16.7.16.
- Read-only GitHub Actions **[41176289183](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41176289183)** job 124464418770 executed full `git show b495e90a:sideplay/log/DuoFaceAudit 21.txt` plus all three IPS files, parsed and archived on feature branch commit `d6489bcf35f7798ad3cec3535fa68e6691c941ed`. Result `sideplay/audit/qa142-log21-home-click-20261031/LOG21_HOME_CLICK_AND_CRASH_FINDINGS.json` and receipt. Code `analyze_log21_home_click.py`, workflow `.github/workflows/duoface-qa142-log21-home-forensics.yml`. This is **replay of user device's actual log**, not a new on-device click test.

## iOS16.7.16 real live Home/workspace ABI now proven

| Runtime selector, CarPlay app process | Exact encoding returned |
|---|---|
| `-[DBDashboardHomeViewController iconManager:launchIconForIconView:]` | **`v32@0:8@16@24`** — exists! |
| `-[DBDashboardHomeViewController iconManager:launchIcon:]` | **absent** |
| `-[DBWorkspace initWithOwner:]` | `@24@0:8@16` |
| `-[DBWorkspace requestStateChange:]` | `v24@0:8@16` |
| `-[DBWorkspace state]` | `@16@0:8` |
| `-[DBMutableWorkspaceStateChangeRequest activateApplication:]` | `v24@0:8@16` |
| `-[DBDashboardWorkspaceOwner init]` | `@16@0:8` |
| `+[DBApplicationController sharedInstance]` | **absent** |
| `-[DBApplicationController applicationWithBundleIdentifier:]` | **absent** |
| `-[DBWorkspaceState activeBundleIdentifier]` | **absent** |

**Significant:** previous apparent blocker was the older `_CARDashboardHomeViewController` being absent, but current real iOS16 method `DBDashboardHomeViewController iconManager:launchIconForIconView:` is NOW confirmed with precise return/argument ABI. Future first-party adapter must target **this** class and selector, not vendor old class, preserve original forwarding for genuine Apple/native and unselected apps.

**Different necessary correction:** a separate reference app suggests `DBApplicationController.sharedInstance → applicationWithBundleIdentifier:`, but on this user's actual CarPlay process **both selectors are unavailable**. Do not transplant that reference launch path. `DBWorkspace`/request methods exist, but neither the live workspace owner instance nor a genuine `DBApplication` for user-selected non-CarPlay apps has yet been captured. Method existence does **not** prove third-party activation can be requested or will display on CarPlay.

## Exactly what Log21 proves about the user's session
- `DuoFaceHomeLaunch142.log` contains **13** section lines: 10 method ABI measurements, footer, whitespace. **NO hook/callback or selected icon tap trace.** QA142 is a read-only class sampler and was never designed to open apps.
- QA141 active current CarPlay PID **92554**, hooks typed3/typed2/DashBoard factory all installed (`1/1/1`), selected consent enabled, six selected app declarations read back `getterReadback=1`; `FBSApplicationLibrary newRecords=6`; 10 current selected policy callbacks. Native Home registration works. These were recorded ~**13:12:48–13:14:11 ICT**, after QA142 was released. The `launch=0` in these logs means optional ABI-checked `setLaunchAsCarApplication:` invocation unavailable, **NOT** evidence that an application's launch was refused. Current `DFHome141.m` source does not implement Home-tap scene activation.
- The `DFHomeLaunchABI142.m` instrument had a bounded class-list enumerator. No `candidate-count` line appeared in device sample; the conditional enumeration may have been skipped (e.g. total >20,000) and so cannot be used as absence-of-icon-controller evidence. The explicitly queried class method above **does exist**.

## Three crash IPS are real, but are NOT proof QA142 crashed
User separately uploaded three `CarPlay` `EXC_BAD_ACCESS/SIGSEGV` reports with timestamps **10:18:02, 10:18:13, 10:18:24 ICT**, all **earlier than the QA142 source session 13:12 ICT**. Their triggered thread queue `com.apple.frontboard.applicationLibrary.taskQueue`; each first ~511 recorded frames show `DF138Selected` once, **165× `DF138Entitlement3` and 165× `DF138Answer`**, interleaved with `DFFirstPartyAdmission.dylib`, then `CoreFoundation` property list parsing, finally stack protection fault. All three same `DFCarPlayDockOwner.dylib` Mach-O UUID `26f13ecd-22fa-3fe0-8350-fc80dc45c526`. This **directly identifies prior QA138-style entitlement hook recursion / stack overflow**, not a missing YouTube URL, app executable, or native Home launch failure, and not the current QA142 executable. Its QA138 code path was already removed from QA141/142 builds; never copy it back or infer current QA142 physical crash. Report `Crash-0-CarPlay-2026-10-31-101825 4.ips` and other two in pinned main commit.

## Correct next implementation boundary (not yet performed)
1. First-party, **ABI exact** and **consent/selected-only** CarPlay Home tap handler for `DBDashboardHomeViewController iconManager:launchIconForIconView:`: forward original exactly once, instrument real icon-view application identity, real app launch request/result, and distinguish native-unselected. No global entitlement recursion.
2. Only once a live owned `DBWorkspace` and requested `DBApplication` or a verified first-party scene bridge are identified, connect the tap to a **real activation**; no unsupported `DBApplicationController.sharedInstance`, guessed app file paths, URL, window/foreground setters. Native apps remain untouched; generation/back/off and no-user-consent fail closed.
3. Build signed source, release Sileo, re-test physically with fresh Log22 and compare actual tap callback vs app scene ready/Back. Do not claim this Log21 fixed clicking. Preserve QA141 Home roster and GOFA/YouTube/Dock/phone-lock improvements.
