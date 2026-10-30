# DuoNavi Observer — original live-session read-only trace

Distinct independent Sileo rootless package: com.duoface.qa.duonaviobserver, version 0.0.1~passive1, iPhone X iOS16.7.16. Not DuoNavi itself and **contains no DuoNavi vendor payload/license**.

One SpringBoard/CarPlay/CarPlayApp-filtered dylib observes UIKit public screen/scene/app lifecycle notifications and samples externally present display geometry, the host process's own scene counts, and iOS protected-data state. On SpringBoard it **reads**, without invoking or replacing, the ObjC type encodings of the three SBSuspendedUnderLockManager methods previously found in the original DEB. Each process logs its own timestamped JSONL, rotate at 2MiB. A standalone on-phone app provides five pre-event marker buttons and a single share/export action, no network or shell/Filza.

**Never install both active DuoFace QA124 scene hooks and original DuoNavi concurrently**. Back up prefs if appropriate; use Sileo to deactivate DuoFace hooks, use original legally obtained DuoNavi and this passive observer, then Respring from jailbreak manager. Park vehicle. Open original with YouTube, mark VIDEO_AWAKE; mark BEFORE_PHONE_LOCK just before locking; use CarPlay while locked, unlock and mark AFTER_PHONE_UNLOCK; mark BEFORE_CARPLAY_HOME then use actual Home separately; mark BEFORE_UNPLUG then physically detach. Open DuoNavi Observer on iPhone and share TXT into GitHub sideplay/log.

Log limitation: this is a passive sampler, not a guaranteed per-selector method-call tracer. Original proprietary method presence does NOT prove call execution. Compare observed state transitions with DuoFaceAudit 10: screen lock and CarPlay Home need separate user timestamps.

Source test: python3 sideplay/duonavi-observer/tests/test_passive.py.
Build: bash sideplay/duonavi-observer/build.sh on macOS with iOS SDK, ldid, dpkg. Do not claim real-device working until user supplies log. Do not alter QA120 measured Dock, .90 YouTube rotation, .92 split divider.
