# QA173 STATUS — 2026-11-02

- Private build run `41450574137` SUCCESS (all contract batteries,
  including the frozen-host guard re-pinned to the reviewed QA173
  DFSceneHost revision `2686c453...` and the QA141 baseline diff
  taught the QA173 spans). Archive commit `f43c8c53baa3`:
  `com.duoface.jb.embedded_0.0.173~touchlog1_iphoneos-arm64.deb`,
  1,258,804 bytes, SHA256 `681c60958298211b...`.
- PUBLISHED to Sileo: carplaydsp publisher commit `4ed0836f48ae`,
  run `41451982509` SUCCESS (5 jobs). Public index independently
  verified: exactly one embedded stanza 0.0.173~touchlog1 with the
  matching SHA. QA172/QA171 retained as rollbacks.
- Item outcomes: (1) log reduction DONE in code; (2) same-pass
  geometry + flag-gated root-window touch fall-through DONE in code,
  touch effect UNVERIFIED until a device session; (3) Waze icon NOT
  changed (native roster is iOS-owned per project records).
- DEVICE_TESTED=false. Device session owed: install via Sileo,
  check YouTube taps top/middle/bottom in both panes, confirm the
  log files stay small, run one GOFA navigation drive and export
  (the QA172 shadow verdict is still open and rides this build).
