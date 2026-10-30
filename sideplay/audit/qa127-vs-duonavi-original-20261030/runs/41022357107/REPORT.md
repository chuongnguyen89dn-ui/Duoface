# Original DuoNavi 1.0.4 vs signed DuoFace QA127 — two real DEBs

## SHA256-verified artifact bytes and package inventory
| File | SHA256 | Paths | Mach-O |
|---|---|---:|---:|
| Original DuoNavi 1.0.4 | f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd | 50 | 4 |
| Signed DuoFace QA127 | ddbc2ded86b768ffd8fa720a0c883e7e6884c24ffc26a142a306431987950a61 | 34 | 8 |

Full control/maintainer scripts, file hashes/modes, plist filters, binary UUID/imports and risk-selector presence are in two retained JSON manifests.

## Original callback contract vs QA127 implementation
| Original evidence | QA127 first-party source |
|---|---|
| DuoNavi three exact ARM64 under-lock registrations at 0x2ecf80/0x2ecfa0/0x2ecfc0 | Only one runtime-ABI-approved background predicate hook; the other methods are not hooked |
| Native12 original observer and separate scene-destroy callback | DFSceneLifecycle.m only hooks settings observer; no separate scene-destroy callback |
| Original selected-app/hosted-scene identity marker + display identity policy | QA127 uses weak current-scene registry and window-dependent owner proof; cannot simply reuse vendor markers |
| Original bridge owner coordinates app lifetime, UI host and frame | QA127 still globally changes foreground NO->YES while CPTemplate background indiscriminately stops TouchOwner |
| Original renderSizeForBundleID app policy | QA127 generic logical 2x for every app, no GOFA map layout receiver confirmation |

## What this DOES NOT prove
- Legacy audit run 41015886871 examined signed QA125; this run actually examines signed QA127 bytes.
- Original methods are disassembled and registered in SHA-pinned prior audits, not executed by this scanner.
- Do not hook original selectors missing on iOS16.7.16; never reuse licensing or passcode/activation logic.
- Original package might itself have app-specific assumptions. Similar strings are not a runtime fix.
- User reports QA127 still crashes and touch does not work; this scanner does not fix or device-test it.

## Concrete repair gate
Implement first-party per-generation scene owner and coherent update/destroy handling, first with exact controller/handle/scene identity, before further foreground modifications. Distinguish true Home/unplug from iPhone lock and verify installed vs loaded dylib UUID. Preserve QA90 rotation, QA92 divider and QA120 Dock. Verify touch transport at the app receiver rather than assuming a pane hit equals Play. Rebuild only once a specific source repair is testable; do not publish guesses.
