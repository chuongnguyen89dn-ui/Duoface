# DuoFace native Maps owner log exporter (standalone)

Purpose: after standalone `com.duoface.carplay.nativejoinprobe 0.0.4~mapowner1` has collected actual CarPlayApp snapshots with Maps navigation, tap **Chia sẻ CarPlay Maps JSONL** on the iPhone home screen. This app exports the original JSONL file intact; it does not infer owner, manipulate scenes, open maps, zoom, or change DuoFace. No Filza and no shell needed.

Log source: `/var/mobile/Library/Logs/DuoFaceCarPlayOwnerSnapshot.log`, with app's no-container read entitlement, file size bound 5 MiB, explicit user-initiated share and no uploads. If the app cannot read the file it reports the error, without pretending maps owner was verified. Test while parked: Maps native guidance 35 s, DuoFace split 35 s. If the log contains no real Maps VC/scene association, label native owner unresolved.

Build: `bash sideplay/native-map-owner-export-v6/build.sh` on macOS with iOS SDK, ldid and dpkg-deb. Package ID distinct from existing QA and DuoFace runtime; no dependency on other tweaks or risky admission gate. CI workflow is a source/build verification, not on-device capture. Rollback via Sileo uninstall of only `com.duoface.carplay.mapownerexport`.
