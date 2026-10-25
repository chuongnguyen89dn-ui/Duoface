#!/usr/bin/env python3
"""SHA-pinned original DuoFace Native12 read-only ARM64: divider + media + scene teardown.
No vendor code imported, no app linking, no licensing.
"""
import pathlib
import runpy
import struct
import sys
import hashlib

source = pathlib.Path(__file__).resolve().parents[2] / "audit/native12-layout-forensic-20261021/extract_layout_imp.py"
module = runpy.run_path(str(source))
module["main"].__globals__["METHODS"] = [
    ("CBDividerView", "pointInside:withEvent:"),
    ("CBDividerView", "hitTest:withEvent:"),
    ("CBDividerView", "configureWithButtonConfigs:"),
    ("CBDividerView", "moveButtonTouchDown:"),
    ("CBDividerView", "moveButtonTouchUp:"),
    ("CBDividerView", "moveButtonTouchCancelled:"),
    ("CBDividerView", "handleMoveButtonLongPress:"),
    ("CBDividerView", "handlePan:"),
    ("CBDividerView", "updateGripLayout"),
    ("CBDividerView", "moveButtons"),
    ("CBBridgedUIAppView", "updateLayout"),
    ("CBBridgedUIAppView", "refreshSceneLayout"),
    ("CBBridgedUIAppView", "updateSceneSettingsFrame"),
    ("CBBridgedUIAppView", "setAudioOnlyBackgroundMode:"),
    ("CBBridgedUIAppView", "dismiss"),
    ("CBBridgeManager", "renderSizeForBundleID:"),
    ("CBDividerView", "startBlinking"),
    ("CBDividerView", "stopBlinking"),
    ("CBBridgedSplitApp", "noteUserActivity"),
    ("CBBridgedSplitApp", "startBlinkingSession"),
    ("CBBridgedSplitApp", "stopBlinkingSession"),
    ("CBBridgedSplitApp", "startContainerBorderBlinking:"),
    ("CBBridgedSplitApp", "stopContainerBorderBlinking:"),
    ("CBBridgedSplitApp", "configureDividerButtons"),
    ("CBBridgedSplitApp", "layoutSplitViews"),
]
def append_verifiable_blink_literals():
    """Only read original Mach-O __const values; do not execute vendor code."""
    argv=sys.argv
    binary=pathlib.Path(argv[argv.index("--binary")+1])
    dest=pathlib.Path(argv[argv.index("--out")+1])
    data=binary.read_bytes()
    if hashlib.sha256(data).hexdigest()!="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea":
        raise ValueError("Wrong original Native12 dashboard")
    if struct.unpack_from("<I",data,0)[0]!=0xfeedfacf:
        raise ValueError("Not a 64-bit Mach-O")
    off=32
    segments=[]
    for _ in range(struct.unpack_from("<I",data,16)[0]):
        cmd,sz=struct.unpack_from("<II",data,off)
        if sz<8 or off+sz>len(data):raise ValueError("Bad load command")
        if cmd==0x19:
            _,vmaddr,vmsize,fileoff,filesize=struct.unpack_from("<16sQQQQ",data,off+8)
            segments.append((vmaddr,vmsize,fileoff,filesize))
        off+=sz
    addresses={
       "blink_start_animation_duration_100d9c":0x30f968,
       "blink_stop_animation_duration_1011ec":0x30f968,
       "blink_session_NSTimer_interval_10c848":0x311b20,
       "blink_grip_scale_100eb8":0x312498,
    }
    rows=["", "## Original binary's verified blink duration/scale literals",
          "", "Each double is mapped from the exact original Dashboard SHA; "
          "selector execution or final idle duration still requires CFG/runtime interpretation.", ""]
    for name,addr in addresses.items():
        matched=[fo+addr-va for va,vs,fo,fs in segments
                 if va<=addr and addr+8<=va+min(vs,fs)]
        if len(matched)!=1:raise ValueError(f"Blink literal mapping ambiguous {name}")
        index=matched[0]
        value=struct.unpack_from("<d",data,index)[0]
        rows.append(f"- `{name}` VM `0x{addr:x}`, file off `0x{index:x}`: "
                    f"double `{value:.12g}`, raw hex `{data[index:index+8].hex()}`")
        print("NATIVE12_VERIFIED_BLINK_LITERAL",name,hex(addr),value)
    with (dest/"REPORT.md").open("a",encoding="utf8") as report:
        report.write("\n".join(rows)+"\n")

if __name__ == "__main__":
    module["main"]()
    append_verifiable_blink_literals()
