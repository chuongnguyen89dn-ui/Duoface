# QA172 — GOFA payload field map v1 (evidence-graded)

Date: 2026-11-02. Scope: static, read-only analysis of the original
CarPlayPro Speed 0.9.97 `SpeedAlerts.dylib` (DEB SHA256
`e5b0918b3bc1948420f37a8a9e21365756da46fba44d582a3f2893aee9b4102f`, arm64
slice) performed to derive an *interface specification* for a clean-room
DuoFace decoder. No vendor code, binary, asset or license material is copied
into DuoFace; only externally observable interface facts (notification names,
dictionary keys, value shapes) are recorded here — the same facts the QA166
audit already established, now traced to instruction level.

Method (new this session): the full 60,552-instruction disassembly
(`qa166-gofa-dataflow/FULL_ORIGINAL_ARM64_DISASSEMBLY.txt.gz`) was re-analysed
against the actual Mach-O bytes: `__objc_selrefs`, `__cstring`, `__cfstring`,
`__objc_classrefs` and Swift small-string immediates were resolved to literal
values, so every key/name below is tied to a concrete address, not to a
first-65-instructions sample.

Grades: **[V]** verified statically at instruction level (address given) ·
**[S]** strong inference from multiple static signals · **[U]** unknown —
must not be guessed in code.

## 1. Registration (unchanged from QA166, re-confirmed)

- Setup function `0x3ce1c` registers, via
  `addObserverForName:object:queue:usingBlock:` (ObjC stub `0x440a0`):
  `notificationSpeedBoard` (CFString `0x63968`) and the static array
  `0x64568` = [`notificationNextBoard`, `notificationOtherBoard`].
- Alert callback `0x3cfb4` (gate: max 8 concurrent), speed callback
  `0x3d468`. Both live in the GOFA process (filter plist injects
  `com.lumi.GOFA`, `com.apple.CarPlayApp`, VietMap/WYN/Navitel bundles).

## 2. Speed channel — `gofaSpeedPayload` (`0x3e390`) **[V]**

Input is the `NSNotification` object itself (raw pointer argument).

1. `note.name` (selref `0x6b030` -> `name`, call `@0x3e3c0`) must equal
   `notificationSpeedBoard` (inline compare vs `__cstring 0x553f0`,
   `@0x3e3ec`).
2. `dict = note.userInfo` (selref `0x6b038` -> `userInfo`, `@0x3e440`),
   bridged `NSDictionary -> [AnyHashable: Any]` (`@0x3e478`).
3. `raw = dict["pushSpeedBoard"]` — key built as a Swift small string
   (`@0x3e488..0x3e4a4`), dictionary subscript helper `0x3f938`.
   **The speed board is in `userInfo`, not in `note.object`.**
4. `converted = mirrorToDictionary(raw)` — shared helper `0x3da6c`, which
   uses `Mirror` metadata (`0x3db98`), `Mirror(reflecting:)` (`0x3dc50`)
   and `Mirror.children`: it walks the object's labelled stored properties
   into a `[String: Any]` dictionary. No fixed offsets are read.
5. Dynamic type-name check: `String(reflecting: type(of: raw))` compared
   with `GOFA.SpeedBoardModel` (`__cstring 0x55410`, `@0x3e5bc`). This is a
   *name* check, not a class identity check.
6. Keys read out of the converted dictionary (each via dictionary subscript
   helpers `0x3e038`/`0x3e234`/`0x3fa14`, values numerically normalised):
   - `userSpeed` (small string `@0x3e6e0`)
   - `speed` (small string `@0x3e738`)
   - `currentAllowSpeed` (`__cstring 0x55430`, `@0x3e7a0`)
   - `limit` (small string `@0x3e670` and again `@0x3e7f4`)
7. Output: a **new** dictionary containing the found subset of those keys,
   bridged back to `NSDictionary` (`_bridgeToObjectiveC`, `@0x3e89c`) and
   returned. Speed callback then calls the collector setter
   `setGofaBoard:` (ObjC stub `0x46a80`, `@0x3d938`) and separately reads
   `board["limit"]` (CFString `@0x3d5c8`). Diagnostics counters:
   `gofaBoardsAccepted` / `gofaBoardsRejected` (`@0x3d860`).

So `SACollector.gofaBoard` is an `NSDictionary` with (subset) keys
`userSpeed`, `speed`, `currentAllowSpeed`, `limit`. **[V]**

## 3. Alert channel — `gofaAlertPayload` (`0x3e940`) **[V]**

1. `note.name` must equal `notificationNextBoard` (`__cstring 0x55450`) or
   `notificationOtherBoard` (`__cstring 0x55470`).
2. The `userInfo` lookup key depends on the name (csel `@0x3eb0c`):
   - Next board  -> `pushNextBoard` (Swift small string, length 13,
     built `@0x3e970`/`0x3e980`)
   - Other board -> `pushOtherBoardToCarplay` (`__cstring 0x55490`,
     length 23)
3. `value = userInfo[key]`; dynamic type-name compared with
   `Swift.Array<GOFA.DatapointModel>` (`__cstring 0x554b0`, `@0x3ec84`):
   **the payload is an array of GOFA `DatapointModel` objects.**
4. `Mirror(reflecting:)` over the value (`@0x3ed24`), children iterated;
   each element's type name compared with `GOFA.DatapointModel`
   (`__cstring 0x554e0`, `@0x3edfc`); each element is itself mirrored
   (`Mirror` + `children`, `@0x3ef30`) into labelled fields.
5. Per-point fields read:
   - `traffic_sign_id` (Swift small string, length 15, `@0x3f224`)
   - `lat`, `lon` (length-3 type/field strings `@0x3f358`, `@0x3f3ac`),
     extracted via `swift_dynamicCast` (`@0x3f340`, `0x3f394`, `0x3f3f0`)
     and read as numbers via `doubleValue` (`@0x3f408` and following).
6. Normalised output point keys (built `@0x3f5f0..0x3f664`, and read back
   by collector code at `0x13010` / `0x13424` with exactly these names):
   `identity`, `sign`, `latitude`, `longitude`. **[V]**
   (`traffic_sign_id` is therefore normalised to output key `sign`.)
7. Alert callback wraps the points with group metadata using CFString
   keys `group`, `at`, `items`, `points` (`@0x3d200..0x3d298`), maintains
   counters `gofaAlertAccepted` / `gofaAlertRejected` (`@0x3d140`), and
   the collector stores groups/points plus a `CLLocation`
   (`gofaAlertGroups`, `gofaPassedPoints`, `gofaAlertLocation` per QA166
   property inventory). Ahead-distance is computed downstream — the
   collector reads a `distance` key in many places (e.g. `@0x116b0`).

Normalised alert point (v1 target for DuoFace):
`{ identity, sign, latitude, longitude }` + locally computed distance. **[V/S]**

## 4. Second lead — Flutter method channel (not yet traced) **[U]**

Around `0x3c1e8..0x3c2c0` the original contains a separate mechanism with
CFStrings `lastFlutterChannel`, `incoming`, `flutterDirection`,
`decodeMethodCall:`, `arguments`, using `NSClassFromString` /
`sharedInstance` / `NSSelectorFromString`. This looks like a Flutter
platform-channel observation path, distinct from the NSNotification route,
and may be where maneuver/direction data comes from. **Not traced; do not
design against it yet.** Maneuvers remain out of QA172 v1 scope.

## 5. Remaining unknowns (blocking items marked)

- **[U] Which of `userSpeed` vs `speed` the collector displays, and their
  units.** Both are copied into `gofaBoard`; the display-side selection in
  the collector/overlay was not traced this session. Decoder must carry
  both, labelled, and let the device log decide. Do not drop one.
- **[U] Value types/ranges** of the four speed keys on the user's GOFA
  build (NSNumber vs Swift numeric; km/h assumed from product behaviour
  only). Runtime evidence required (QA171 log shows classes of `userInfo`
  values; QA172 shadow mode will log value *classes and ranges*, never
  coordinates).
- **[U] Full stored-property list** of `SpeedBoardModel`/`DatapointModel`.
  Only the keys the original *consumes* are known — which is sufficient
  for parity of consumed data, because the mirror conversion copies all
  labels but only these keys are ever read downstream.
- **[U] Whether the three notifications fire at all** in the GOFA version
  installed on the user's iPhone X, and whether `userInfo` carries the
  `push*` keys there. This is exactly what QA171 was built to answer; no
  decoder result may be claimed before that log exists.
- **[U] The `lat`/`lon` double computations inside the alert helper**
  (constants around `0x3f454..0x3f4bc`) — likely distance/validity maths;
  DuoFace will compute distance itself from its own authorised location,
  so parity here is not required.

## 6. What this map is sufficient for

Writing a first-party decoder that: observes the same three notifications
inside the GOFA process; reads `userInfo` (not `object`); extracts
`pushSpeedBoard` / `pushNextBoard` / `pushOtherBoardToCarplay`; converts
Swift model objects to labelled dictionaries by reflection; and emits the
normalised speed board + alert points above. Everything else stays behind
the gates in `DESIGN.md`.
