# Exact original DEBs vs signed DuoFace QA125 — complete offline inventory

## SHA-pinned input: all files and all Mach-O (read-only)
| Package | SHA256 | Extracted files | Mach-O |
|---|---|---:|---:|
| Native12 | 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad | 43 | 8 |
| DuoNavi104 | f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd | 50 | 4 |
| OmniCar103 | d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd | 176 | 8 |
| SidePlay104 | 7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c | 136 | 7 |
| DuoFaceQA125 | 1914f4e2c6e8dce0fadb5035166c0869966759fb74eb1c89424712dcf71cbe93 | 34 | 8 |

**Original Native12 1,385 method entries:** 317/1385 selector strings appear in QA125 binary. THIS IS NOT functional parity.

## What is verified vs unknown
- Verified: every package file hash/size/mode, DEBIAN control/scripts, plist injection filters, every compiled Mach-O UUID/import/probe string, 1,385 original Native12 ObjC entries mapped to QA125 selector-string presence.
- Unknown: method execution, return ABI in the device process, exact branch/callback ownership under lock, event ordering and Play ACK.
- Stock DuoDash not included: previous comparison was a repack, not a byte-identical original; do not silently treat it as stock.

## Evidence files
- [NAME]_ALL_FILES_AND_BINARIES.json — all paths/sha256/metadata and every Mach-O probe.
- ALL_PACKAGE_STRING_AND_SELECTOR_CROSSWALK.json — original-only/shared/QA125-only selector probes, only string-level.
- NATIVE12_ALL_1385_METHODS_VS_QA125.json — all actual reference ObjC method selectors and type encodings.
- DUOFACE_QA125_REAL_SOURCE_HOOKS.json — exact line numbers for current first-party potentially conflicting scene/owner writes.
- SUMMARY.json — exact artifact hashes and coverage.

## NON-GO / safety
This is **not** evidence that every original app has been functionally recreated; binary equivalence and phone behavior require on-device owner/callback evidence. Do not copy original licensing or alter other packages. Avoid promoting an untested build to Sileo.
