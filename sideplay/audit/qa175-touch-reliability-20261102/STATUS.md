# QA175 — Touch reliability (T1–T7) — STATUS

- Branch: feature/duoface-qa175-touch-reliability-20261102 (base: QA174 tip)
- Integrated: 0.0.175~touchfix1 / host 0.1.175~touchfix1, rootless iphoneos-arm64
- Private build: run 41468306241 SUCCESS (head 049e7d9445bc)
- Archive commit: b6c1dc6a5a1e (evidence/runs/41468306241/)
- DEB: 1,259,980 bytes, SHA256 e0123cc18f59cf0e582a27081bd058919b76a8dd64599576b446797fd1393859
- Control verified from the built DEB: Conflicts/Replaces complete;
  postinst/postrm uicache-only, unchanged.
- SILEO_PUBLISHED=false (per work order §3 — publish only after user review)
- DEVICE_TESTED=false

## Per-item

- T1 DONE: fall-through mark set only at the pane (slot) creation site in
  DFNative12Chrome.m; makeWindow no longer marks. Divider/splash/picker/
  style/appPicker windows are never marked. Kill switch RootTouchPassThrough
  (qa173 plist) unchanged.
- T2 DONE: layoutScene only records pending size + (re)arms a trailing-edge
  timer (kDF175GeometryDebounceSeconds = 0.09). Skipped commits retry via
  df175NoteGeometrySkip (cap: geometryCommitAttempts 4) and pollScene re-arms
  while a pending size stays uncommitted. Resize logged once per settled
  commit. Supersedes QA161's 120/300ms solo split and QA173's same-pass
  commit. Relay: host republish throttle 0.75s -> 0.30s behind the
  YTRelayGuard flag (com.duoface.nativehost.qa175.plist, absent = on);
  relay no longer restores pre-host snapshots on silent lease expiry when
  the flag is on (explicit deactivation/owner change still restores).
- T3 DONE: divider visibility decided in one function
  (df175RefreshDividerVisibility) called from layoutControls; conditions
  unchanged (startup / slot count / focus / any sheet); one log line
  (qa175-divider-visibility) only on change, naming blockers. Focus remains
  a blocker because a focused pane is expanded (the two panes are then not
  simultaneously visible).
- T4 DONE: DFSceneSurface observers register once, after all start guards
  (observersRegistered175); stop already removed them symmetrically.
  Frozen-host digest re-pinned through the sanctioned path: a0f62fa5...
  (test_qa148/149/150/151/161 + test_qa141 QA175 normalization section,
  locally verified byte-exact outside start).
- T5 DONE (risk reduced, not eliminated): decoder + probe work confined to
  serial queues (com.duoface.gofa.decoder172 / com.duoface.gofa.probe166);
  blocks copy userInfo before hopping; throttle/sequence/token statics are
  only touched on the queue; observer tokens kept, teardown path exists.
  Mirror still reads live objects, now from the decoder's own queue.
  Decoder stays shadow; bubble speed stays GPS.
- T6 DONE: build labels updated to the current build (0.0.175~touchfix1) in
  DFDeepTrace.h and DFTouchOwnerProbe.m (continuation of the QA174 fix, so
  logs name the running build).
- T7 READ-ONLY REPORT: the built entry is V1ATweak.x (Makefile
  DFV1APreflight_FILES; Tweak.x is not in the build). Its SpringBoard hook
  runs BOTH [MTPreflight startReadOnlyDiagnostics] (log-only) AND
  [[MTBridgeCoordinator sharedCoordinator] start]. The coordinator polls
  the opt-in plist (com.duoface.mytweak.v1bc.plist, Enabled absent = off);
  window creation / MTSceneHost hosting happens only when Enabled=1.
  So: diagnostics + coordinator polling run at load; hosting stays dormant
  until opt-in. Evidence: Makefile FILES line, V1ATweak.x hook body,
  MTBridgeCoordinator.m gate.

## Tunables

- kDF175GeometryDebounceSeconds = 0.09 (DFSceneHost.m)
- geometry retry cap = 4 fast retries, then pollScene cadence
- kDF175YTStateThrottleSeconds = 0.30 (flag on) / 0.75 (flag off)
- Flags: YTRelayGuard (qa175 plist, absent = on),
  RootTouchPassThrough (qa173 plist, absent = on)
