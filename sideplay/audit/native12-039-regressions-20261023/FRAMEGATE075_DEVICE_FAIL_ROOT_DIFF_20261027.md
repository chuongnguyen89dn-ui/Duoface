# DuoFace .75 boxed video AND still crashes — user report 2026-10-27

## Evidence classification
- **DEVICE USER REPORT**, supersedes the .75 beta release assumption: the player is boxed again and launching an app still crashes. No new .75 crash IPS or log has been uploaded; DO NOT assert the same crash offset has been observed on .75.
- Earlier three actual .74 SpringBoard SIGABRT +440 logs and full sanitized chronology are in CRASH_074_SPRINGBOARD_SCENE_DIFF_20261027.md; 09:13:19 had NO logged scene-settings-frame-requested event before abort. Therefore disabling this one FBScene mutation was not an established crash repair.

## Exact verified source regression
- Real .37 source at Git commit a8cdec6252b0e772faa726e92b84ee66246590ed, .74 source 6fa66d47ad0e2362448d49cc187c87d1ef9b187d, .75 source 120f6f4529a044f9be0282b60067fe1b04ffcfec.
- At .75 DFSceneHost.m the hard-coded function DFEnableUnverifiedFBSceneFrameMutation() returned NO, making the formerly-live ready-scene FBScene updateSettingsWithBlock: / settings.setFrame: transaction unreachable. The .37/.74 route existed and the user confirmed .74 was visually not boxed; the user now confirms .75 is boxed. Removing this route was the **wrong release decision**.
- Previous assertions that four preserved physical UIWindows and private content reference selectors GUARANTEED .37 video were false: preserving these did not preserve actual remote FBScene viewport behavior. The failure is a real source/device regression, not a cosmetic issue.
- .74 and .37 DFSceneHost.m also differ in reentrancy/async touch logic, but no evidence yet uniquely implicates those differences in the SpringBoard abort. No fresh crash .75 process ID has been examined.

## Applied remediation
- Commit 07dd6bbda2b899fd5adbeb7e834f582b3aa4e26d reverted only the incorrect hard-OFF FBScene mutation gate **in source**; .37 frame dispatch restored while the generation ownership safeguards remain. The immutable published .75 DEB is NOT changed by this commit and the crash is NOT repaired by it.
- Commit c992e88168fe84c80e3ccc14791935f30463c182 changed source tests to fail when a future edit again blocks the original scene frame route without device playback parity.
- Publisher repo chuongnguyen89dn-ui/carplaydsp main commit 51469c2f165a1802ad64fb408e3d9c2e9f74cea7 was made to keep both immutable binaries but return the single Sileo APT record to .74. Public deployment and SHA verification still require checking Actions. **.74 itself is also known to crash**, so this is a GEOMETRY ROLLBACK, NOT a stable crash fix. Sileo does not automatically offer downgrade from already installed .75.
- Do not rebuild .75 with changed source/version name; reserve a new version for a future candidate.

## Next exact step
- Obtain crash-report IPS and DeepTrace from the new .75 failure, align pid / build / actual exception stack and last scene state. Analyze how SBAppViewController scene diff observer is triggered without frame mutation, including lifecycle/scene ownership. Compare source snapshot .37 and .74, isolate any new callsite from evidence.
- Preserve original ready-scene geometry and four physical media UIWindow owners, native12 menu, Zoom, divider, Dock and fullscreen. Do not publish another guessed fix.
- Test on parked real device YouTube x3 + 70mai + ChatGPT; verify both unboxed viewport AND no SpringBoard crash, not just static unit tests.
- Safety: if SpringBoard keeps aborting, disable DuoFace tweak in jailbreak manager until new findings; if downgrading to archived .74, it can still crash. Do not claim the device is safe.
- Prior raw uploads contain identifiers; only sanitized analysis belongs in public GitHub.
