# DuoFace .67: device crash and divider evidence (2026-10-26)

Evidence from user-provided crash reports and manual diagnostic export; keep raw private logs outside GitHub.

- Two uploaded IPS files are byte-identical SHA256 `bf88e731b0b33da180ae6f2f3139068a95c7814dcd1a479a5ed2a459d22831a9`: ONE SpringBoard incident at 13:40:36 UTC+7, iOS 16.7.16, `EXC_CRASH/SIGABRT`.
- `lastExceptionBacktrace` throws in `-[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]+440` during FrontBoard `FBScene` settings transaction. The same exception stack includes an AppData scene-update hook and an OmniCarAppBridge frame. Neither is proven to be the root cause; original failed assertion is unknown.
- Current v0.0.67 deep trace recorded 18 matching before/after live scene reference-size dispatch checkpoints in SpringBoard before crash. Last relevant callbacks at approximately 13:40:24.93 local, 6.5 seconds before capture. Completion of a setter call is NOT scene/pixel correctness evidence.
- Current runtime confirmed logo dragging *does reach the state machine*: the axis-2 log shows logo fraction 0.500 -> 0.536 -> 0.702 -> 0.471. Axis-1 ratio actions and swap were also emitted. Visible logo positioning on CarPlay is still NOT verified.
- The export also contains untimestamped older logs: `live-scene-private-reference-update-suppressed` refers to historical binaries and must not be assigned to .67.
- Root-cause triage: scene setting diff/ownership conflict is demonstrated; exact trigger remains unknown. Investigate read-only concurrent FBScene hooks and first-party scene generation/close behavior before any private API modification. A future reproducible parked-device test separating interacting tweaks requires user consent; do not uninstall other tweaks automatically.

State: **diagnosis only**. No source, DEB, Sileo changes from this report. Previous public .67 retained. Never upload entire raw device audit publicly.
