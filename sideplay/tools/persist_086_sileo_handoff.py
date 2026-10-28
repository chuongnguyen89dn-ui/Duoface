#!/usr/bin/env python3
"""Verify public Sileo package bytes and prepend one verified handoff checkpoint.

Run in GitHub Actions on the actual project branch. No client claims, secrets,
native CarPlay screenshot, or device PASS are inferred from APT publication.
"""
import hashlib
import pathlib
import urllib.request

NAME = "com.duoface.jb.embedded"
VERSION = "0.0.86~nativeowner1"
FILE = f"{NAME}_{VERSION}_iphoneos-arm64.deb"
SHA = "a4871bf76b07844bee9be181340101e779372b7e8bdf065ff658fe99724fa409"
SITE = "https://chuongnguyen89dn-ui.github.io/carplaydsp"
RUN = "40638640307"
SOURCE_RUN = "40638250670"
ARCHIVE = "bcf649118091fb9998dc239b45a8c07bf3742985"
PUBLISHER = "ed83d8554682575529eeb604011a3dfa0e666422"


def fetch(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def verify():
    records = []
    for block in fetch(SITE + "/Packages").decode("utf-8").split("\n\n"):
        entry = {}
        for line in block.splitlines():
            if ": " in line and not line.startswith(" "):
                key, value = line.split(": ", 1)
                entry[key] = value
        if entry.get("Package") == NAME:
            records.append(entry)
    if len(records) != 1:
        raise RuntimeError("expected exactly one publicly advertised DuoFace record")
    got = records[0]
    expected = {"Version": VERSION, "Filename": "debs/" + FILE,
                "SHA256": SHA, "Architecture": "iphoneos-arm64"}
    for key, val in expected.items():
        if got.get(key) != val:
            raise RuntimeError(f"public APT mismatch {key}: {got.get(key)}")
    downloaded = hashlib.sha256(fetch(SITE + "/debs/" + FILE)).hexdigest()
    if downloaded != SHA:
        raise RuntimeError("public binary SHA mismatch")
    print("SILEO_PUBLIC_DEB_SHA_VERIFIED", FILE, SHA)


def main():
    verify()
    handoff = pathlib.Path("sideplay/tiep tuc du an.md")
    if not handoff.is_file():
        raise FileNotFoundError("existing project handoff is missing")
    marker = "SILEO PUBLIC .86 VERIFIED — RUN 40638640307"
    previous = handoff.read_text(encoding="utf-8")
    if marker in previous:
        print("PUBLISH_CHECKPOINT_ALREADY_EXISTS")
        return
    note = f"""## {marker} (2026-10-28)

Actual public Sileo APT: `{SITE}/`. Exactly one advertised `{NAME}` version `{VERSION}`. Actual public `{FILE}` downloaded and SHA256 matched `{SHA}` independently in CI. Sileo publisher commit `{PUBLISHER}`, success GHA run `https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/{RUN}`, public binary verifier job `122652134508`; YAML verifier `40638640366` success. Original .83 and .84 remain frozen for rollback. Repo source SHA `205ab7121fe04bf37f449c07d53da42489f70e47`; signed DEB archived as DuoFace commit `{ARCHIVE}` under `sideplay/jb-embedded-appbridge/evidence/runs/{SOURCE_RUN}/` (GHA {SOURCE_RUN} SUCCESS).

What shipped: first-party .86 native CarPlayApp read-only Google Maps FBScene owner snapshot and a guarded, original-referenced YouTube hosted-main-scene orientation correction candidate. `DFSceneLifecycle.m` known-good .83 fix unchanged; no user-rejected 0.80 scale or foreign binary/license. **NOT YET VERIFIED ON DEVICE**: YouTube initial Zoom rotation correction or native Google Maps displayed *inside DuoFace split pane*. The native Maps split compositor has **NOT BEEN IMPLEMENTED** because V7 shows active Dashboard host scene switches from Google Maps to DuoFace, and no evidence a live Maps scene survives behind DuoFace. No arbitrary scene cloning, CPWindow reparent or percentage zoom was done. Sileo publication is not device success.

Next: install .86 via Sileo while car is parked, test YouTube split -> Zoom -> video fullscreen -> restore, record `/var/mobile/Library/Logs/DuoFaceSceneHost.log` and CarPlay owner log, compare real scene generation/owner, Dock, map tiles vs instructions-only, crash/IPS. If map still instructions-only, investigate native CarPlay scene continuity and actual original OmniCar `adopt:slot:` before implementing guarded independent native scene compositor. If Youtube still rotates, use captured scene orientation readback and avoid forcing arbitrary landscape. The .83 physical playback baseline must remain recoverable.

Source details: `sideplay/audit/native12-083-rotation-20261028/DUOFACE_086_NATIVE_MAP_YOUTUBE_STAGE_20261028.md`.

---
"""
    handoff.write_text(note + previous, encoding="utf-8")
    readback = handoff.read_text(encoding="utf-8")
    if not readback.startswith(note) or not readback.endswith(previous):
        raise RuntimeError("handoff verification failed")
    print("PUBLICATION_HANDOFF_READBACK_PASS", marker)


if __name__ == "__main__":
    main()
