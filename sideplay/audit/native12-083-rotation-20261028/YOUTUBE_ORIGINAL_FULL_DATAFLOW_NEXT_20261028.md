# YouTube orientation original-DEB investigation — 2026-10-28

User confirms .86 YouTube still wrong; Maps frozen and must not be modified. No guessed rotation or new Sileo release.

Verified original binary references: Native12 SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad; SidePlay SHA256 7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c; DuoNavi SHA256 f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd; OmniCar SHA256 d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd.

Existing read-only original binary workflow: .github/workflows/duoface-083-original-orientation-binary-audit.yml and sideplay/tools/audit_original_current_orientation_083.py. Reports: BINARY_DIRECT_083_VS_ORIGINAL.json and OMNICAR_ORIGINAL_NATIVE_MAP_BRANCHES_V2_RUN_40627902229.json. Workflow's source comparison against .83 will fail on changed .86 DFSceneHost.m; use immutable .83 checkout for reference, not current source.

Current code: .86 DFSceneHost.m checks FBScene.settings.interfaceOrientation 2/3/4 before a Portrait=1 settings update; DFSceneOrientationPolicy.m independently limits owned main scene to Portrait=1. Device result remains wrong. OmniCar ABHost.layoutPane original sets frame and interface orientation together, but exact argument provenance remains unverified. YouTube's own fullscreen corrects image and state persists on return to split, suggesting player presentation transition is relevant, not proving its root cause.

NEXT: run read-only SHA-pinned ARM64 dataflow analysis of orientation caller/branch/value and scene/YouTube fullscreen state transitions across originals. No change to Maps, Dock, .83 lifecycle or release until exact mechanism established. This turn: read original audit workflow, current .86 orientation code and original report; no new binary run and no fix claimed.
