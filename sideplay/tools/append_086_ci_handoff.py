#!/usr/bin/env python3
"""Append verified immutable CI artifact data to the project's EXISTING handoff.

Called only after all build/package tests passed; never rewrite another branch
without first refreshing it. Does not claim physical CarPlay device success.
"""
import hashlib
import pathlib
import sys


def main(args):
    if len(args) != 4:
        raise ValueError("args: handoff_path run_id source_commit archive_directory")
    filename, run_id, source, folder = args
    if not run_id.isdigit() or len(source) != 40 or any(c not in "0123456789abcdef" for c in source):
        raise ValueError("invalid immutable CI provenance")
    handoff = pathlib.Path(filename)
    if not handoff.is_file():
        raise FileNotFoundError("existing handoff missing; do not create duplicate")
    archives = list(pathlib.Path(folder).glob("com.duoface.jb.embedded_0.0.89~splitscene1_*.deb"))
    if len(archives) != 1:
        raise ValueError("expected exactly one staged .89 DEB")
    deb = archives[0]
    digest = hashlib.sha256(deb.read_bytes()).hexdigest()
    marker = f"CI run `{run_id}` source `{source}`"
    checkpoint = f"""## CHECKPOINT 2026-10-28 DuoFace .89 — signed build archived (not hardware-verified)

{marker}; signed staged DEB: `sideplay/jb-embedded-appbridge/evidence/runs/{run_id}/{deb.name}`; SHA256 `{digest}`.
Build provenance, tests and ldid/dpkg verify under GitHub Actions `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/{run_id}`.
Changes (first-party YouTube-only .89): .88 real device log proves host-to-app IPC is delivered (105 ACKs; 17 internal-window ACKs), yet controller orientation=3 transiently while UIWindowScene orientation=1 at lines 7238-7244. Native12 Chrome sends ACTUAL split vs SOLO state even when the second pane is empty; host includes this in v2 owner-scoped IPC. App re-checks controller after 120ms and, only for a remaining portrait-scene/two-pane mismatch, issues at most one public UIKit supported-orientation/geometry refresh per owner/size/mode. Readback now includes host-side clientSettings versus settings orientation; no global hooks, no arbitrary scaling or fixed landscape. No changes to Maps, Dock, .83 video lifecycle or system scene hooks. This is a hypothesis-driven DEVICE CANDIDATE, not a proven fix.

**IMPORTANT:** Build and SHA verification are NOT proof YouTube rotation is corrected on iPhone or that native Google Maps is displayed simultaneously in a DuoFace split pane. Native Maps actual scene still unproven after the CarPlay Dashboard switches to DuoFace, so **native Maps split is NOT IMPLEMENTED**. Do not pretend scene reparent or clone is safe. Device QA and separate native scene lifecycle evidence remain required. Do not auto-deploy or mark Sileo published solely from build. Keep .83/.84 immutable rollback.

Source audit: `sideplay/audit/native12-083-rotation-20261028/DUOFACE_088_SCENEHOST_REAL_DEVICE_ACK_20261028.md`. This .89 does not claim video rotation pass until tested.

---
"""
    old = handoff.read_text(encoding="utf-8")
    if marker in old:
        print("CHECKPOINT_ALREADY_EXISTS", run_id)
        return
    handoff.write_text(checkpoint + old, encoding="utf-8")
    check = handoff.read_text(encoding="utf-8")
    if not check.startswith(checkpoint) or not check.endswith(old):
        raise RuntimeError("handoff readback verification failed")
    print("CHECKPOINT_READBACK_VERIFIED", run_id, deb.name, digest)


if __name__ == "__main__":
    main(sys.argv[1:])
