# DuoFace VisualTest12 — launch-recovery1, Sileo release evidence (2026-10-17)

## Requirement and scope
User urgently prioritizes getting the original **VisualTest12** app to open on the iPhone whose trial period ended. This supersedes repeated read-only forensic audits for the current immediate deliverable. Original package `com.duonavi.app` version `1.0.3-12~visualtest`; do **not** swap binaries from `com.duoface.independent` or modify its working Speed8 Hub package. Do not mistake CI success for an iPhone launch test.

## Source, commits, workflow, commands
Project: `chuongnguyen89dn-ui/Duoface`, feature branch `feature/duoface-exact-payload-migration`. Original pinned DEB: `dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb`, SHA256 `8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a`.

Builder: `migration/full_payload/native_test/build_visualtest12_launchfix1.py`, commits `f7cfc296` and `0725ed24`, reuses vetted prior Native4 and Native5 ABI/expiry recovery work on arm64 extracted from the original VisualTest12 universal binary. 248 UI and 43 Dashboard method bodies plus two expired-state UI methods; all remaining Objective-C metadata retained for compatibility, no class deletion. Original visual hook and 35 other package files retained. Generic arm64 only, hosts re-signed; original FAT arm64e slice not included to avoid stale code.

Workflow `.github/workflows/duoface-visualtest12-launch-recovery-deb.yml`, commit `ba87f209`. Commands on macos-15 from DuoFace repo root:

```bash
brew install dpkg ldid
python3 -m py_compile migration/full_payload/native_test/build_visualtest12_launchfix1.py
python3 migration/full_payload/native_test/build_visualtest12_launchfix1.py \
  --out dist/visualtest12-launchfix1/com.duonavi.app_1.0.3-12~visualtest12launch1_iphoneos-arm64.deb \
  --report dist/visualtest12-launchfix1/BAO_CAO.json
```

Run `39021729748`, job `117364723983`, failed: `AssertionError: Missing or added original payload path`, because original input DEB did not include `DEBIAN/md5sums`. Fixed builder to allow generation of this exact manifest without removing or adding payload paths, commit `0725ed24`. Run **`39021792773` job `117364909028` SUCCESS**: compile, DEB, iOS signing, rootless package metadata, lipo arm64, otool, hash tests.

Output retained in project feature branch:
- `dist/visualtest12-launchfix1/com.duonavi.app_1.0.3-12~visualtest12launch1_iphoneos-arm64.deb`
- `dist/visualtest12-launchfix1/BAO_CAO.json`, `SHA256SUMS`, `CONTENTS.txt`
- package ID `com.duonavi.app`, version `1.0.3-12~visualtest12launch1`, SHA256 **`e30148affc767ce039040f0e0cccd9a0ecbd40e523ee66409ca96e6ef2085f02`**, size **1,555,368 bytes**; feature artifact `12096469859`. Build commit with actual DEB `82d20f59318417de6b6bb9838a86995243cd5b5f`. Latest report feature head at public verification: `953c4be4cbbb2628f3e0a4b8f4ebe54141ffeb05`.

## Sileo publication / actual downloaded verification
Live APT repo: `https://chuongnguyen89dn-ui.github.io/carplaydsp/`; publishing repository `chuongnguyen89dn-ui/carplaydsp` main. Its `.github/workflows/build.yml` was changed ONLY for VisualTest12: pin the new DuoFace source file, exact SHA, new package/version, leave Hub path/SHA unchanged. Commit `15f70f0c` attempted publish but run `39021929432` failed in APT index stage because the hash check still referenced the old filename; corrected at commit **`b60952bc030a9df222250219be72ba9ace670431`**.

Subsequent **CarPlayDSP run `39022124541` SUCCESS**, build job `117365855193` and GitHub Pages deploy job `117366205398` SUCCESS. Actual public Pages independent downloaded-byte QA: DuoFace workflow `.github/workflows/duoface-visualtest12-launchfix1-public-sileo-verify.yml`, commit `d3e02ae6718e157aee87bf2590aaf2792e33c4c4`; run **`39022327036` SUCCESS**, artifact `12096563729`; output `audit/payload-migration/VISUALTEST12_LAUNCHFIX1_PUBLIC_SILEO.json`, saved in feature commit `953c4be4cbbb2628f3e0a4b8f4ebe54141ffeb05`. Public downloaded DEB's SHA256 matches **`e30148affc767ce039040f0e0cccd9a0ecbd40e523ee66409ca96e6ef2085f02`**, public index advertises correct ID/version. Hub remains **`com.duoface.independent 0.1.0~native12+speed8compact`** SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. Public DEB URL: `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duonavi.app_1.0.3-12~visualtest12launch1_iphoneos-arm64.deb`.

## Current state, next action and acceptance criteria
**DONE:** Original package updated to new signed installable candidate, git commits saved, actual public Sileo DEB download/hash and index verified, Hub unchanged.

**NOT VERIFIED:** On-device launch after expiration, CarPlay connection, split/picker/dashboard, long-running state, or comprehensive physical license-code deletion. Metadata retained intentionally. Never claim successful app opening from build or Sileo publication alone.

**NEXT:** User refreshes existing CarPlayDSP source in Sileo on the expired-trial iPhone, updates `com.duonavi.app` to `1.0.3-12~visualtest12launch1`, and tries opening the DuoFace app on iPhone first (without CarPlay). Then reports **whether the app enters its interface**. If it opens, test CarPlay split and picker. If it does not open, collect SpringBoard/app crash or diagnostic logs and inspect remaining launch blockers with exact installed version; avoid blind rebuild/reinstall loops. Baseline original pinned DEB remains in DuoFace for rollback. No continuing job was intentionally left running; verify Actions at new-session start.
