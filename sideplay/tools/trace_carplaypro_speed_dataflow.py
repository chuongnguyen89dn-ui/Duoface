#!/usr/bin/env python3
"""Evidence-only caller graph for CarPlayPro Speed original ARM64 disassembly.
Does NOT execute/link original code, decode vendor activation, or claim runtime
GOFA data delivery. Parses exact original tracked Mach-O audit artifacts.
"""
from __future__ import annotations
import argparse, bisect, collections, gzip, json, re
from pathlib import Path

PIVOTS={
    "GOFA_speed_export":254860,
    "GOFA_speed_Swift_wrapper":254864,
    "GOFA_alert_export":256316,
    "GOFA_alert_Swift_wrapper":256320,
}
INSN=re.compile(r"^([0-9a-fA-F]{16})\s+[0-9a-fA-F]{8}\s+([a-z.]+)\s*(.*)$")
BRANCH=re.compile(r"^#0x([0-9a-fA-F]+)\b")
PRIORITY=("gofa","GOFA","notification","SpeedBoard","Datapoint","camera",
          "route","direction","maneuver","speedlimit","alert","navitel")
def parse(asm_text, starts, symbols):
    starts=sorted({int(v) for v in starts})
    names={int(x["value"]):x["name"] for x in symbols if x.get("value") and x.get("section")}
    instructions=[]
    func_callers=collections.defaultdict(set)
    edges=collections.defaultdict(set)
    for raw in asm_text.splitlines():
        m=INSN.match(raw)
        if not m:continue
        at=int(m[1],16)
        i=bisect.bisect_right(starts,at)-1
        if i<0:continue
        owner=starts[i]
        mnemonic=m[2]
        operand=m[3]
        instructions.append((at,owner,mnemonic,operand))
        if mnemonic in ("bl","b") and (v:=BRANCH.match(operand)):
            dest=int(v[1],16)
            edges[owner].add(dest)
            func_callers[dest].add(owner)
    by_owner=collections.defaultdict(list)
    for at,owner,mnemonic,operand in instructions:
        by_owner[owner].append([f"0x{at:x}",mnemonic,operand])
    # Only mark strong ARM64 *direct* branch edges. Indirect calls like BLR,
    # method dispatch objc_msgSend and Swift metadata calls remain unresolved.
    def callers(target,level=0,seen=None):
        seen=set() if seen is None else seen
        if level>=4 or target in seen:return []
        seen.add(target)
        result=[]
        for owner in sorted(func_callers.get(target,())):
            result.append({"owner":f"0x{owner:x}",
                           "symbol":names.get(owner),"depth":level+1})
            result.extend(callers(owner,level+1,seen.copy()))
        return result[:180]
    funcs=[]
    for title,addr in PIVOTS.items():
        i=bisect.bisect_right(starts,addr)-1
        base=starts[i] if i>=0 else addr
        hits=[x for x in instructions if x[0]>=addr and x[0]<addr+260]
        funcs.append({"title":title,"address":f"0x{addr:x}","parent_start":f"0x{base:x}",
          "symbol":names.get(addr),
          "direct_callers":[{"address":f"0x{v:x}","symbol":names.get(v)} for v in sorted(func_callers.get(addr,()))],
          "callers_up_to_four_hops":callers(addr),
          "first_65_instructions":[[f"0x{x[0]:x}",x[2],x[3]] for x in hits[:65]],
          "outgoing_direct_branches":[f"0x{x:x}" for x in sorted(edges.get(base,()))][:110],
          "pivot_code_disassembled":bool(hits)})
    # Original GOFA selectors are in the original binary's section strings;
    # there is no reliable automatic address mapping from raw strings to
    # the running GOFA Swift object methods without ObjC metadata + runtime.
    return {"static_only":True,"instruction_min":hex(instructions[0][0]) if instructions else None,"instruction_max":hex(instructions[-1][0]) if instructions else None,"function_starts":len(starts),"instruction_count":len(instructions),
            "direct_branch_edges":sum(map(len,edges.values())),"pivot_functions":funcs}

def markdown(data,original_symbols):
    out=["# CarPlayPro Speed 0.9.97 — confirmed static ARM64 GOFA call-site trace",
         "","This is **original binary evidence**, not GOFA device execution and not original source code.",
         "Original dylib: `main:sideplay/audit/carplaypro-0.9.97/unpacked/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SpeedAlerts.dylib`.",
         "Symbols/ARM64 disassembly: original audited `007-SpeedAlerts.dylib-arm64.*`.",
         "No vendor license or binary is incorporated into DuoFace.",
         f"","## Exact analysis counts",
         f"- ARM64 function starts: {data['function_starts']}",
         f"- decoded instructions inspected: {data['instruction_count']}",
         f"- disassembly instruction address span: {data['instruction_min']} .. {data['instruction_max']}",
         f"- direct B/BL edges: {data['direct_branch_edges']}",
         "","## Proven GOFA-specific symbols and branch callers"]
    for f in data["pivot_functions"]:
        out.extend(["",f"### {f['title']} @ {f['address']}",
          f"- Parent function start: `{f['parent_start']}`",
          f"- Symbol: `{f['symbol']}`",
          f"- Direct call branches to exact address: **{len(f['direct_callers'])}**",
          "- Direct callers: "+(", ".join("`"+x["address"]+"`" for x in f["direct_callers"][:35]) or "none found"),
          "- Reverse callers up to four hops: "+(", ".join("`"+x["owner"]+"`" for x in f["callers_up_to_four_hops"][:50]) or "none from direct B/BL")])
        out.extend(["","First instructions at exported address:"])
        out.append("```text")
        out.extend(" ".join(ins) for ins in f["first_65_instructions"][:28])
        out.append("```")
    out.extend(["","## Relevant strings are present, but their runtime meaning requires validation",
          "","The following tokens were checked in the original Mach-O's ObjC selector and C-string sections:"])
    for name in ("GOFA.SpeedBoardModel","GOFA.DatapointModel","notificationSpeedBoard",
                 "notificationNextBoard","notificationOtherBoard","pushOtherBoardToCarplay",
                 "currentAllowSpeed","flutterDirection","cameraUpcoming",
                 "gofaAlertGroups","navigationSample","distanceRemaining",
                 "upcomingManeuvers"):
        out.append(f"- `{name}`: {'PRESENT' if name in original_symbols else 'NOT_FOUND'}")
    out.extend(["","## What these findings do *not* prove",
       "- Whether `notificationNextBoard` is a literal NSNotification name (could be a Swift/ObjC property).",
       "- Which GOFA object property holds a camera, speed limit, turn or distance at runtime.",
       "- That a direct branch means a successful GOFA event: wrappers can short-circuit or call indirectly.",
       "- A zero direct-caller count does NOT imply an exported hook has no caller (IMP dispatch, function pointers and BLR are invisible).",
       "- Successful parsing is NOT a CarPlay hardware test.",
       "","## Required next test",
       "Use exact call sites/ObjC selector tables and runtime symbol type evidence to validate"
       " a GOFA-specific *read-only* adapter. Do not synthesize signs/cameras/turns,"
       " or claim the current QA166 speed HUD displays them."])
    return "\n".join(out)+"\n"

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--disasm-gzip",type=Path,required=True)
    p.add_argument("--function-starts",type=Path,required=True)
    p.add_argument("--symbols",type=Path,required=True)
    p.add_argument("--section-strings",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    args=p.parse_args()
    txt=gzip.decompress(args.disasm_gzip.read_bytes()).decode("utf-8","replace")
    funcs=json.loads(args.function_starts.read_text())
    syms=json.loads(args.symbols.read_text())
    section=json.loads(args.section_strings.read_text())
    strings=set(section.get("__cstring",[])+section.get("__objc_methname",[]))
    result=parse(txt,funcs,syms)
    result["original_goFA_source_tokens"]={s:s in strings for s in
        ("GOFA.SpeedBoardModel","GOFA.DatapointModel","notificationNextBoard",
         "notificationOtherBoard","currentAllowSpeed","flutterDirection")}
    args.out.mkdir(parents=True,exist_ok=True)
    (args.out/"GOFA_CALL_GRAPH.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    (args.out/"GOFA_CALL_GRAPH.md").write_text(markdown(result,strings))
    print("CARPLAYPRO_ORIGINAL_ARM64_GOFA_STATIC_CALLGRAPH_PASS",
          result["instruction_count"],"instructions")
if __name__=="__main__":
    main()
