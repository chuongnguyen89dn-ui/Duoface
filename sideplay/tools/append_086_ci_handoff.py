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
    # The immutable run folder contains exactly one newly built integrated
    # package. Version is pinned to the known .90 rollback or current .91
    # explicit native Maps QA, never inferred from another build directory.
    archives = list(pathlib.Path(folder).glob("com.duoface.jb.embedded_*_iphoneos-arm64.deb"))
    if len(archives) != 1:
        raise ValueError("expected exactly one signed integrated DEB in this run")
    version = archives[0].name.split("com.duoface.jb.embedded_", 1)[1].split("_iphoneos-arm64.deb", 1)[0]
    if version not in ("0.0.90~nativegetters1", "0.0.91~nativemapqa1"):
        raise ValueError("unsupported QA archive version: " + version)
    deb = archives[0]
    digest = hashlib.sha256(deb.read_bytes()).hexdigest()
    marker = f"CI run `{run_id}` source `{source}`"
    checkpoint = f"""## CHECKPOINT 2026-10-28 DuoFace .90 — signed build archived (not hardware-verified)

{marker}; signed staged DEB: `sideplay/jb-embedded-appbridge/evidence/runs/{run_id}/{deb.name}`; SHA256 `{digest}`.
Build provenance, tests and ldid/dpkg verify under GitHub Actions `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/{run_id}`.
Changes (independent YouTube-only .90): based on full SHA-pinned original Native12 36 ARM64 callback audit, install strictly process-scoped UIKit orientation getter/window rotation wrappers if supported, with exact leased YouTube-scene check, original UIKit IMP outside lease, 3-second heartbeat expiry and ACK virtualization telemetry. The .89 real device test FAILED; this is an unverified hardware candidate, not a proven video rotation fix. Maps, Dock and .83 video lifecycle unchanged.

**IMPORTANT:** Build and SHA verification are NOT proof YouTube rotation is corrected on iPhone or that native Google Maps is displayed simultaneously in a DuoFace split pane. Native Maps actual scene still unproven after the CarPlay Dashboard switches to DuoFace, so **native Maps split is NOT IMPLEMENTED**. Do not pretend scene reparent or clone is safe. Device QA and separate native scene lifecycle evidence remain required. Do not auto-deploy or mark Sileo published solely from build. Keep .83/.84 immutable rollback.

Source audit: `sideplay/audit/native12-083-rotation-20261028/DUOFACE_088_SCENEHOST_REAL_DEVICE_ACK_20261028.md`. This .90 does not claim video rotation pass until tested.

---
"""
    if version == "0.0.91~nativemapqa1":
        checkpoint = f"""## CHECKPOINT 2026-10-28 DuoFace .91 native Maps QA — signed source/package only, NOT CarPlay PASS

{marker}; archived first-party **one** rootless QA package: `sideplay/jb-embedded-appbridge/evidence/runs/{run_id}/{deb.name}`; SHA256 `{digest}`.
Full compile/test/provenance: `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/{run_id}`. User-triggered, CarPlay-only `DFNativeMapPaneCoordinator` and iPhone `Bố cục > Thử nghiệm bản đồ CarPlay native` left/right/restore actions are **compiled and packaged**.
Native Maps tile rendering, seamless Google Maps navigation alongside YouTube, correct touchscreen map position, continuous routing, CarPlay enabled status and SpringBoard crash-safety remain **NOT device tested**. This is an experimental, explicitly user-armed controller containment path; no automatically activated native Maps take-over or private scene lifecycle calls. Preserve immutable public .90 YouTube rotation PASS and DO NOT automatically mark .91 published to Sileo.

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
