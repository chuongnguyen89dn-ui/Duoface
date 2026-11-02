# QA172 — status

- 2026-11-02 (session, Muse as implementer under explicit user
  authorisation to proceed with Method 2 and to keep the sideplay
  project history updated as in previous sessions):
  - Gate G0 completed: full instruction-level trace of the original
    payload helpers against the real Mach-O bytes (selrefs, cstrings,
    CFStrings, Swift small strings resolved). Results in `FIELD_MAP.md`.
  - Design + gated plan written: `DESIGN.md`. No source code changed,
    no build run, no publication, no device claim.
  - Key new facts vs the QA171 checkpoint: the speed board lives in
    `userInfo["pushSpeedBoard"]` (not `note.object`); the alert payload
    key differs by board (`pushNextBoard` vs
    `pushOtherBoardToCarplay`); normalised alert point keys are
    `identity/sign/latitude/longitude`; the existing DuoFace speed
    protocol and HUD already support a limit — only the transport
    publish guard blocks it.
- Next action: Gate G1 — user device session with QA171 (open GOFA,
  export the log via the DuoFace app's "Xuất log / lỗi CarPlay"), or
  explicit user instruction to proceed to G2 on static evidence alone.
- Flags: `DEVICE_TESTED=false`, `SILEO_PUBLISHED=false`,
  `GOFA_REAL_ROAD_ALERTS_CONNECTED=false`,
  `GOFA_REAL_NAVIGATION_TURNS_CONNECTED=false`.
