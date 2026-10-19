# DuoFace MyTweak v1b+v1c: ONE combined on-device test

Upgrades the same Sileo package ID from v1a; all v1a diagnostics remain active.
v1b: one app picker, independent SBAppViewController, scene logs/resize/close.
v1c: two hosted apps, Split 2/Single, divider ratio drag 25–75%, 0.3s long-press swap, Swap button, Zoom, individual slot × close, global Close.
Real Apple AppDock has NOT been spoofed or declared verified; no fake dock is included.

## Enable using Filza
1. Install/update DuoFace MyTweak V1B+C Combined CarPlay Test from the existing Sileo CarPlayDSP source.
2. Default = OFF. After respring, open Filza preferences file:
   /var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist
   Set Boolean Enabled from false to true while parked and with other CarPlay scene-host windows inactive.
3. Connect CarPlay. The trial starts in one-app mode. Tap App and choose an installed app. Then press Split 2, choose a second app via its slot, touch both, drag the divider, long-press it to swap, Zoom/Close and test disconnect/reconnect.
4. Press Close to stop all hosts and reset Enabled=false; or turn it off in Filza; the poller reacts without another Sileo update.
5. In Filza share /var/mobile/Library/Logs/MyTweakV1BC.log and MyTweakSceneHost.log, plus screenshot and any SpringBoard .ips on crash.

## Safety and evidence
Do not overlap this CarPlay host with existing SidePlay/QA or Native12 hosts; preserve QA11 and use parked vehicle only. If SpringBoard has problems, use jailbreak safe mode, disable DFV1APreflight.dylib in Filza or remove the optional test package.
Static tests and green GitHub Actions are build-only evidence. Actual scene pixels/touch/audio, dual-host stability, real Apple Dock and shutdown/reconnect must be verified once on iPhone X. The scene-ready log alone is not proof.
