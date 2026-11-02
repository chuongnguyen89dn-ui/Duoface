# QA172 — Gate G1 evidence (device export, 2026-11-02)

Source: `sideplay/log/DuoFaceAudit.txt` uploaded by the user at commit
`1ac56d441b` (QA171/QA172 branch tips), exported on-device
2026-11-02 17:09 VN by exporter build `0.0.171~gofadiag1`
(iOS 16.7.16, audit schema 4). QA171 was published to Sileo the same
day (carplaydsp commit `ca428c4d79b5`, publisher run `41420918323`,
public index verified: single stanza `0.0.171~gofadiag1`,
SHA256 `2315bfa7…`).

## What the export proves

- The export header carries the probe discovery summary:
  `QA167 GOFA original notification received id=3 userInfoKeys=1
  objectKind=0 ageSeconds=836 sequence=34 (no values)`.
- Per `DF167GOFAEventProtocol.h`: event ids are
  1=`notificationNextBoard`, 2=`notificationOtherBoard`,
  3=`notificationSpeedBoard`; object kinds are 0=none, 1=dictionary,
  2=array, 3=GOFA object, 4=other. The sequence counter is per
  GOFA-process (`++DF167Sequence` in `DF167PublishEvidence`).
- Therefore, in the GOFA process session preceding the export:
  **34 board notifications were observed**, and the most recent one
  (≈16:55 VN, export minus 836 s, during the user's car session with
  GOFA open) was **`notificationSpeedBoard`** with **exactly one
  userInfo key** and a **nil notification object**.
- This matches the Gate G0 field map exactly: the speed board is
  carried by a single key inside `userInfo`
  (`userInfo["pushSpeedBoard"]`), not by `note.object`.
- **Gate G1 question 1 answered: YES — GOFA posts the original board
  notifications on the user's GOFA build, repeatedly, in a live
  session.** The clean-room decoder route (Method B) remains valid.

## What the export does NOT contain

- The `DuoFaceTrafficNav166.log` section of the export is empty:
  "[không đọc được hoặc file chưa tồn tại]" — the probe's per-event
  detail rows (key names + value class names from
  `DF167SummarizeNSDictionary` / `DF167SummarizeObject`) were never
  persisted to `/var/mobile/Library/Logs/DuoFaceTrafficNav166.log`.
- Cause (documented in `DFGofaTrafficNavProbe166.m` itself): the
  probe runs inside the GOFA process; the GOFA sandbox may deny
  cross-sandbox writes to `/var/mobile/Library/Logs`. The source
  comments state this explicitly ("do not claim log persisted") and
  keep NSLog (`[DuoFaceGOFAProbe QA171]`) as the fallback channel.
  The detailed rows therefore exist only in the device unified
  system log, which this export does not include.
- **Gate G1 question 2 remains open**: the exact key name and the
  class of the value under it (`GOFA.SpeedBoardModel` vs dictionary)
  are still unverified at runtime. Static G0 evidence for the key
  name and Mirror-based extraction stands unchanged.

## Decision

- Do not send the user hunting through the system log. Fold the
  remaining question into the QA172 decoder itself: its shadow mode
  (Gate G3) must report the userInfo value's kind/class through the
  Darwin evidence channel (the channel proven to work above), so
  the first QA172 device session answers it from the DuoFace host
  side, where file writes succeed.
- Proceed to Gate G2 (decoder core + host tests with synthetic
  models) on the combined G0 + G1 evidence.
- Flags: QA171 `DEVICE_TESTED` for its diagnostic purpose = the
  discovery path is now device-proven; the QA172 decoder remains
  `DEVICE_TESTED=false`, alerts/turns still NOT CONNECTED.
