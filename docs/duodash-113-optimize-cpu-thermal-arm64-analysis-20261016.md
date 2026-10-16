# DuoDash Optimize CPU And Thermal — ARM64 forensic audit — 2026-10-16

## Provenance / constraints

Request: inspect DuoDash CPU/thermal performance feature deeply and contrast with DuoFace Native12; RESEARCH ONLY. No DEB build, no Sileo update, no DuoFace runtime/CarPlay change.

Correct work repo: chuongnguyen89dn-ui/Duoface. Reference archived binary: chuongnguyen89dn-ui/DauDat-CarPlay at immutable commit 5f683ad16a2c4f2b37e333e891cfb8f7ba3e0d6b, file DuoDash_1.1.3_Fullscreen427_iphoneos-arm64.deb, Git blob SHA1 6f3e7a4543a01358b3c1e24653aec5bdb3975206, SHA256 ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465. Metadata version **1.1.3+fullscreen1**. Inspected library: var/jb/usr/lib/TweakInject/DuoDash.dylib, SHA256 b41dd7f892bfd3722e95a40f764a989886078b4a30943c1f0b50d47b6e248a47.

IMPORTANT LIMIT: A distinct earlier user-uploaded DuoDash 1.1.3 DEB had SHA256 16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601. It was inspected in a prior chat but its binary bytes were not persisted in these repos. Because the hashes differ, do not claim the archived 1.1.3+fullscreen1 binary is byte-identical to the user's original 1.1.3 binary. The conclusions below are proven against this archived reference.

Audit source at feature/duoface-exact-payload-migration:
- migration/full_payload/native_test/audit_duodash_perf_thermal_113.py
- migration/full_payload/native_test/trace_duodash_carplay_fps_113.py
- .github/workflows/duodash-perf-cpu-thermal-static-audit.yml
- .github/workflows/duodash-fps-encoder-thermal-deep-audit.yml

Raw evidence in that branch:
- audit/duodash-1.1.3/DUODASH_PERF_CPU_THERMAL_RAW_TRACE.json
- audit/duodash-1.1.3/DUODASH_FPS_ENCODER_SYMBOL_TRACE.json

CI run 38879870747 and run 38880502956 both completed/success, validated binary and wrote inspected JSON to GitHub (static only). Workflow read 3 ZIP skills directly from Gpt-training-: 01-github-continuity, 02-ios-deb-ipa-carplay, 05-research-debug-testing. This is not an iPhone runtime test.

## 1. Preference setting and warning

Both DuoDash plist configurations carry Optimize CPU And Thermal as a PSSwitchCell:
- key = perf_tweak_enabled
- domain = com.sensetechlab.duodash.settings
- default = false
- notification = com.sensetechlab.settings.changed
- developer description: lowers CarPlay frame rate to reduce phone heat and screen dropout when overloaded.
- beta warning says it can cause serious problems and requires disconnect/reconnect of CarPlay after toggling.
- Deep Sleep and Close Unloaded Pane Apps are separate switches; never infer their behavior from this one.

## 2. Exact binary call path — enable

Actual ARM64 code from rootless DuoDash.dylib, not pseudo-code:

- At VM 0x4b778–0x4b79c: _CFPreferencesSynchronize then _CFPreferencesCopyValue reads CFString VM 0xca428 = perf_tweak_enabled from CFString VM 0xc94e8 = com.sensetechlab.duodash.settings.
- 0x4b7bc–0x4b7c8: _CFBooleanGetValue and conditional set yield w25=0 for TRUE/enabled; w25=1 for FALSE or absent.
- 0x4b818: immediate 0xF (decimal **15**) is used to compare with existing preferred settings.
- 0x4b880: conditional branch to 0x4b928 when toggle is TRUE.
- 0x4b928: mov w8,#0xf; 0x4b944: _CFNumberCreate.
- 0x4b954: CFString key maxFPS; 0x4b970: _CFPreferencesSetValue(value=15).
- 0x4b978: CFString key encoderFPSFixed; 0x4b98c: _CFPreferencesSetValue(value=15).
- The CFString domain at 0xcd768 decodes exactly to **com.apple.airplay**; both values are written under that domain, using CFPreferences user/host.
- 0x4b99c onward synchronizes then reads back both keys and checks target value. There is further asynchronous handling; device behavior unverified.

Thus the concrete adjustment is **maxFPS=15 and encoderFPSFixed=15 in Apple's AirPlay preference domain**. This is an output/encoder-frame-cap request. It does not directly prove a real 15 FPS measured stream, nor does it show a CPU/GPU frequency governor change.

## 3. Exact binary call path — disable and lifecycle

- When the setting is FALSE (w25=1), branch 0x4b884 through 0x4b8c0 calls _CFPreferencesSetValue with NULL for each of maxFPS and encoderFPSFixed under com.apple.airplay. This removes the two active overrides.
- Synchronization/re-read paths are visible afterward.
- The binary also contains /var/mobile/Library/DuoDash/airplay_backup.plist, /var/mobile/Library/DuoDash/airplay_absent, and /var/mobile/Library/Preferences/com.apple.airplay.plist. These show a backup/absence-tracking design, but complete restoration of old arbitrary values is **NOT verified**. Do not claim disabling always restores the exact prior state.
- Native code at 0x4b574–0x4b5bc references Darwin notify com.sensetechlab.carplay/fps, with _notify_register_check, _notify_set_state, _notify_cancel and _notify_post. Some notification code passes 0x3c (=60) as STATE; this is NOT a measurement of current CarPlay FPS or proven output at 60 FPS.
- Developer specifically requires reconnecting CarPlay to apply a toggle: not evidence of guaranteed hot-apply.

## 4. What it does and does not optimize

Confirmed direct code action: writes static AirPlay video-related frame-control preferences to 15, plausibly reducing encoding/streaming work *if the iOS version honors undocumented keys*. That may reduce energy use and thermal load, while sacrificing fluidity of map scrolling, CarPlay menus and video output. No percentage CPU or Celsius improvement has been measured.

NOT verified: dynamic thermal sensor-driven FPS selection; adapting FPS based on temperature or CPU; CPU/GPU DVFS throttling; lowering actual media decode FPS inside YouTube; guarantees that Apple accepts maxFPS and encoderFPSFixed on this iOS; effects restricted to DuoDash; crash-free operation across USB and wireless CarPlay.

The target domain is com.apple.airplay (system-wide preference domain), so modifying it can potentially affect *other* AirPlay/CarPlay use. This is a risk, not a verified incident.

Apple WWDC23 session on CarPlay video encoding: https://developer.apple.com/videos/play/wwdc2023/10150/ . This contextual reference does NOT document the private preference keys. There is no public Apple promise of support for them.

## 5. Contrast against DuoFace Native12

DuoFace Native12 Dock monitoring uses host_statistics to display system CPU load, battery monitoring, IOKit temperature or fixed thermalState fallback, with approximately 5-second expanded / 12-second collapsed timer. It does not lower CarPlay FPS. DuoFace's iPhone screen-blank switch is a separate screen control.

DuoDash's performance option is more aggressive: alters AirPlay encoder-related FPS preference for the streaming pipeline itself. Copying a DuoDash binary or applying its undocumented global FPS adjustment automatically in DuoFace would violate user requirement to preserve working Native12 and could degrade smooth navigation. Current policy: DuoFace future DEBs must start ONLY from immutable Native12 (package SHA256 85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7), never Native13–21.

If future implementation is explicitly requested: first verify exact DEB equivalence if available, iOS support for AirPlay overrides, ability to backup/restore existing AirPlay settings, measured FPS and responsiveness in maps/video, CPU/thermal behavior over time and reliable rollback. Make the function opt-in/off by default. No change authorized in this research turn.

## 6. Status / next checkpoint

DONE: exact pinned archival DEB download, Git blob verification and SHA256, DEB metadata audit, ZIP skills read, Mach-O arm64/arm64e scanning, normalized authenticated pointer handling, C-string to CFString pointer resolution, imported stub mapping, disassembly proving 15 + two AirPlay keys and normal removal calls, 2 JSON reports saved in DuoFace feature branch. CI success, physical device untested.

NOT DONE: original stock 1.1.3 binary diff, complete analysis of backup/restore edge cases, actual on-device FPS and thermal benchmarks, updated DuoFace DEB or Sileo changes (intentionally none).
