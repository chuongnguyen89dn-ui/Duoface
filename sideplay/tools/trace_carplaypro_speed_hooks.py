#!/usr/bin/env python3
"""Cross-reference original CarPlayPro Speed hook imports with full ARM64 B/BL.

Only static call sites, no tweak code executed and no vendor licensing touched.
"""
from __future__ import annotations
import argparse,bisect,gzip,json,re
from pathlib import Path

PAT=re.compile(r"^([0-9a-fA-F]{16})\s+[0-9a-fA-F]{8}\s+(bl|b)\s+#0x([0-9a-fA-F]+)\b")
ROW=re.compile(r"^\s*(?:0x)?([0-9a-fA-F]{6,16})\s+\d+\s+(_[a-zA-Z0-9_.$]+)\s*$")
IMPORTANT=("_MSHookFunction","_MSHookMessageEx","_dlsym","_objc_msgSend","_swift_dynamicCast")
def scan(disassembly:str,indirect:str,starts:list[int])->tuple[list[dict],int]:
    selected={}
    for line in indirect.splitlines():
        m=ROW.match(line)
        if m and any(m[2]==x for x in IMPORTANT):
            selected[int(m[1],16)]=m[2]
    starts=sorted(int(x) for x in starts)
    rows=[];count=0
    for raw in disassembly.splitlines():
        m=PAT.match(raw)
        if not m:continue
        count+=1
        at=int(m[1],16);dst=int(m[3],16)
        if dst not in selected:continue
        pos=bisect.bisect_right(starts,at)-1
        rows.append({"at":f"0x{at:x}","function":f"0x{starts[pos]:x}" if pos>=0 else None,
                    "target":f"0x{dst:x}","import":selected[dst],"instruction":raw})
    return rows,count

def main():
    p=argparse.ArgumentParser()
    for name in ("disassembly","indirect","function_starts","out"):
        p.add_argument("--"+name.replace("_","-"),required=True,type=Path)
    a=p.parse_args()
    ins=gzip.decompress(a.disassembly.read_bytes()).decode("utf-8","replace")
    indirect=a.indirect.read_text(errors="replace")
    starts=json.loads(a.function_starts.read_text())
    rows,count=scan(ins,indirect,starts)
    selected=[line for line in indirect.splitlines() if any(s in line for s in IMPORTANT)]
    out={"source":"full original ARM64 disassembly + Apple otool -Iv",
         "static_only":True,"direct_instructions":count,
         "import_lines":selected,"identified_direct_call_sites":rows}
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"ORIGINAL_IMPORT_HOOK_XREFS.json").write_text(json.dumps(out,indent=2)+"\n")
    md=["# CarPlayPro Speed original hook-import xrefs (ARM64, static only)",
        "","These are actual original import stub references. A found call to",
        "`MSHookFunction` is evidence of a hooking mechanism, **not** proof of",
        "which GOFA method was hooked or which traffic data fields are available.",
        "","## Exact otool indirect import lines"]
    md.extend("- `"+x+"`" for x in selected[:90])
    md.extend(["","## Direct B/BL call sites to these stubs"])
    md.extend("- `"+x["at"]+"` in `"+str(x["function"])+"`: `"+x["import"]+"` -> "+x["target"] for x in rows[:150])
    if not rows:md.append("- No references resolved; confirm Apple otool indirect table format before drawing conclusions.")
    md.append("")
    md.append("## Original GOFA hook install / callback machine-code excerpts")
    md.append("These windows contain the **actual** address/loading sequence for dlsym and MSHookFunction.")
    for title,lo,hi in (
        ("GOFA candidate dlsym + MSHookFunction registration",0x392f0,0x39454),
        ("GOFA raw alert callback into SAGofaAlertPayload",0x3cfb4,0x3d080),
        ("GOFA raw speed callback into SAGofaSpeedPayload",0x3d468,0x3d5b0),
        ("Substrate registration at 0x36f64: identify hooked class/selector",0x36f64,0x37200),
        ("Substrate registration at 0x3728c: identify hooked class/selector",0x3728c,0x37520),
        ("AudioQueueStart/Pause/Stop MSHookFunction region, NOT GOFA",0x39390,0x39430),
    ):
        md.append("")
        md.append("### "+title+" `"+hex(lo)+"..`"+hex(hi))
        md.append("```text")
        for line in ins.splitlines():
            try:
                at=int(line[:16],16)
            except (ValueError,IndexError):
                continue
            if lo<=at<=hi:
                md.append(line)
        md.append("```")
    md.extend(["","## Evidence limitations","ObjC dispatch/Swift function pointers may use BLR,",
      "and imported stubs can be wrapped by local trampoline functions. This is",
      "not runtime source-model field evidence and does not authorize made-up",
      "GOFA camera, speed-limit or next-turn values."])
    (a.out/"ORIGINAL_IMPORT_HOOK_XREFS.md").write_text("\n".join(md)+"\n")
    print("QA166_ORIGINAL_SPEEDALERTS_IMPORT_STUBS_SCANNED",len(selected),len(rows))
if __name__=="__main__":main()
