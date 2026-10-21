#!/usr/bin/env python3
"""Read-only, SHA-pinned ARM64 IMP extraction from original Native12 binary.
No guessed preset mapping and no vendor executable or license runtime copied.
"""
import argparse, bisect, hashlib, json, pathlib, re, subprocess

METHODS = [
    ("CBBridgedSplitApp", "layoutSplitViews"),
    ("CBBridgedSplitApp", "setSplitPreset:"),
    ("CBBridgedSplitApp", "handleDividerPan:isVertical:state:"),
    ("CBBridgedSplitApp", "focusSlot:animated:"),
    ("CBBridgedSplitApp", "restoreSplitAnimated:"),
    ("CBBridgedSplitApp", "rotateAllSlotsClockwise"),
    ("CBBridgedSplitApp", "moveSlot:direction:"),
    ("CBBridgedSplitApp", "swapSlot:withSlot:"),
    ("CBBridgedSplitApp", "replaceAppInSlot:withBundleIdentifier:"),
    ("CBDashboardSettings", "setSplitPreset:"),
    ("CBDashboardSettings", "setGridRows:"),
    ("CBDashboardSettings", "setGridCols:"),
    ("CBMultitaskingOverlayView", "presetSelected:"),
    ("CBMultitaskingOverlayView", "setupPresetCardsInCardW:cardH:contentY:"),
    ("CBBridgeManager", "switchToMultiSplitMode:apps:ratio:"),
    ("CBWindow", "carPlayUsableBounds"),
]
EXPECTED = "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
SOURCE_DEB = "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
INDEX_BLOB = "efa45df59bc3c16887cc979bf3aedc0c93c92111"
INSN = re.compile(r"^\s*([0-9a-fA-F]+):\s+(\w[\w.]*)\s*(.*)$")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--binary",type=pathlib.Path,required=True)
    ap.add_argument("--method-index",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    a=ap.parse_args()
    actual=hashlib.sha256(a.binary.read_bytes()).hexdigest()
    if actual != EXPECTED: raise ValueError("Original Dashboard SHA mismatch: "+actual)
    idx=json.loads(a.method_index.read_text(encoding="utf8"))
    assert "native12" in idx and isinstance(idx["native12"],list)
    dashboard=next(x for x in idx["native12"] if x["filename"]=="DuoFaceDashboard.dylib")
    assert dashboard["sha256"]==EXPECTED
    methods=dashboard["objc_methods"]
    starts=sorted({int(v,16) for v in dashboard["lc_function_starts"]} |
                  {int(m["imp"],16) for m in methods})
    lookup={(m["class"],m["selector"]):m for m in methods}
    for k in METHODS:
        if k not in lookup:raise ValueError("Not in original method-index: "+str(k))
    raw=subprocess.run(["llvm-objdump","--macho","--disassemble",
                        "--no-show-raw-insn",str(a.binary)],
                       capture_output=True,text=True,encoding="utf8",errors="replace")
    if raw.returncode:raise RuntimeError(raw.stderr[-2000:])
    selected={}
    for cls,sel in METHODS:
        method=lookup[cls,sel]
        addr=int(method["imp"],16)
        nextix=bisect.bisect_right(starts,addr)
        if nextix >= len(starts):raise ValueError("Missing end of function: "+sel)
        selected[addr]={"class":cls,"selector":sel,"imp":method["imp"],
                        "objc_type":method["type"],"end":hex(starts[nextix]),
                        "instructions":[],"branch_sites":[],"constant_sites":[]}
    addrs=sorted(selected)
    n_total=0
    for line in raw.stdout.splitlines():
        m=INSN.match(line)
        if not m:continue
        pc=int(m.group(1),16)
        i=bisect.bisect_right(addrs,pc)-1
        if i<0:continue
        entry=selected[addrs[i]]
        if pc>=int(entry["end"],16):continue
        opcode=m.group(2);operands=m.group(3)
        entry["instructions"].append(line.strip())
        n_total+=1
        if opcode.startswith(("b.","cbz","cbnz","tbz","tbnz")) or opcode in ("b","bl","blr"):
            entry["branch_sites"].append(line.strip())
        if "#" in operands and opcode in ("mov","movz","movn","movk","cmp",
                                         "cmn","fcmp","fmov","add","sub","subs","lsr","lsl"):
            entry["constant_sites"].append(line.strip())
    if not n_total or any(not entry["instructions"] for entry in selected.values()):
        bad=[x["selector"] for x in selected.values() if not x["instructions"]]
        raise ValueError("Unable to extract original function body: "+str(bad))
    a.out.mkdir(parents=True,exist_ok=True)
    ordered=[selected[int(lookup[c,s]["imp"],16)] for c,s in METHODS]
    evidence={"evidence_type":"BINARY_ARM64_IMP_INSTRUCTION_RANGES_NOT_RUNTIME",
      "original_native12_deb_sha256":SOURCE_DEB,
      "dashboard_macho_sha256":EXPECTED,"method_index_git_blob":INDEX_BLOB,
      "mode":"READ_ONLY_NO_VENDOR_BINARY_IN_NEW_DUOFACE",
      "target_count":len(ordered),"instructions_collected":n_total,
      "runtime_original_preset_frames_verified":False,
      "independently_written_8_layout_presets_are_parity_verified":False,
      "methods":ordered}
    (a.out/"ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json").write_text(
        json.dumps(evidence,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    lines=["# Original Native12: layout and preset ARM64 IMP evidence",
       "",f"- Verified original DEB SHA256: \`{SOURCE_DEB}\`",
       f"- Verified Dashboard SHA256: \`{EXPECTED}\`",
       f"- Original method index blob: \`{INDEX_BLOB}\`",
       f"- Exact extracted IMPs: **{len(ordered)}**, ARM64 instructions: **{n_total}**",
       "- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.",
       "- A selector in an Objective-C call site does NOT prove a receiver.",
       "- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until",
       "  original function control flow and numerical CGRect outputs are derived.",
       "- This artifact contains read-only evidence; no vendor code linked to app.",""]
    for x in ordered:
        lines += [f"## {x['class']}.{x['selector']} @ {x['imp']}",
                  f"Original ABI: \`{x['objc_type']}\`",
                  f"Function boundary: \`{x['imp']}..{x['end']}\`",
                  f"Instruction count: **{len(x['instructions'])}**; branches **{len(x['branch_sites'])}**;",
                  "Potential numerical operations (not yet semantic proof):",""]
        lines += ["    "+p for p in x["constant_sites"][:40]]
        lines += ["","Branch samples:"]+["    "+p for p in x["branch_sites"][:40]]+[""]
    (a.out/"REPORT.md").write_text("\n".join(lines)+"\n",encoding="utf8")
    print("NATIVE12_ORIGINAL_LAYOUT_IMP_EVIDENCE_EXTRACTED",
          len(ordered),n_total)
if __name__=="__main__": main()
