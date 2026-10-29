# Signed DuoFace 116 Dock seam binary verification

- Direct verified signed Debian package: com.duoface.jb.embedded 0.0.116~pane-trace1, iphoneos-arm64.
- Original immutable source/archival ref: eaad4d45d8b6fbb6d41b32a04c632592d6f8d3a7
- DEB SHA256: fc87ceb4a8492469563246c00a9a205b838498f7652f8515bb08b9ca356285a8
- Actual rootless dynamic library present: var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib
- Actual binary strings confirm ContentRect / native12-ui-owner-visible / content-too-small markers.
- Exact signed-source contract still contains MAX(42,screen.size.width*.082) + MAX(region.origin.x,safeLeft).
- This audit does not assert direct machine disassembly of the numeric expression; the source hash and signed package are pinned by CI provenance.
- This proves an independent software origin adjustment path exists; proving it caused the photographed band needs measured CarPlay ContentRect and Dock right edge.

## dpkg control

    Package: com.duoface.jb.embedded
    Name: DuoFace Independent (Integrated CarPlay Beta)
    Version: 0.0.116~pane-trace1
    Architecture: iphoneos-arm64
    Section: Applications
    Priority: optional
    Maintainer: DuoFace Independent
    Depends: firmware (>= 16.0), mobilesubstrate
    Conflicts: com.duoface.mytweak.v1a.preflight, com.duoface.carplay.nativebridgeqa, com.duoface.carplay.firstpartyadmission, com.duoface.carplay.nativescenehost, com.duoface.qa.controlapp, com.duoface.independent, com.duoface.sideplaydisplay, com.duonavi.app, com.duoface.app
    Replaces: com.duoface.mytweak.v1a.preflight, com.duoface.carplay.nativebridgeqa, com.duoface.carplay.firstpartyadmission, com.duoface.carplay.nativescenehost, com.duoface.qa.controlapp
    Description: Independent rootless iOS16 CarPlay DuoFace beta in one DEB with integrated app bridge, scene host and DuoFace UI; no separate CarBridge required. Native12-inspired controls include app picker, split, logo move, swap and zoom. CarPlay hardware behavior and media playback are not yet verified. Replaces conflicting older first-party DuoFace QA modules; review changes before installation.
