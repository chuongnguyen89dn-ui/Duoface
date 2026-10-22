#!/usr/bin/env python3
"""Read-only SHA-pinned Native12 C/static thumbnail raster helper extraction.

Direct branch evidence: CBMultitaskingOverlayView.setupPresetCards... @0xa6484
calls 0x9efe0 with preset tag and dimensions; this is NOT an ObjC selector.
Extract exact function-start bounded ARM64 instructions before implementing
independent nine-style preview. No vendor code, binary or license is copied
into DuoFace's compiled runtime.
"""
import argparse,bisect,hashlib,json,pathlib,re,subprocess
SRC_DEB="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
MACHO="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
HELPER=0x9efe0
INSN=re.compile(r"^\s*([0-9a-fA-F]+):\s+(\w[\w.]*)\s*(.*)$")
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--binary",type=pathlib.Path,required=True)
    parser.add_argument("--method-index",type=pathlib.Path,required=True)
    parser.add_argument("--out",type=pathlib.Path,required=True)
    args=parser.parse_args()
    actual=hashlib.sha256(args.binary.read_bytes()).hexdigest()
    if actual!=MACHO:raise ValueError("original Dashboard hash mismatch "+actual)
    j=json.loads(args.method_index.read_text(encoding="utf8"))
    target=next(x for x in j["native12"] if x["filename"]=="DuoFaceDashboard.dylib")
    assert target["sha256"]==MACHO
    starts=sorted({int(v,16) for v in target["lc_function_starts"]} |
                  {int(m["imp"],16) for m in target["objc_methods"]})
    ix=bisect.bisect_right(starts,HELPER)
    if HELPER not in starts:raise ValueError("thumb helper does not have exact lc_function_starts boundary")
    if ix>=len(starts):raise ValueError("helper has no next function start")
    end=starts[ix]
    if not 0 < end-HELPER < 0x20000:raise ValueError("unbounded helper "+hex(end))
    proc=subprocess.run(["llvm-objdump","--macho","--disassemble",
                         "--no-show-raw-insn",str(args.binary)],
                         capture_output=True,text=True,encoding="utf8",errors="replace")
    if proc.returncode:raise RuntimeError(proc.stderr[-1400:])
    ins=[]
    for row in proc.stdout.splitlines():
        m=INSN.match(row)
        if m and HELPER<=int(m[1],16)<end:ins.append(row.strip())
    if not ins or not ins[0].startswith("9efe0:"):
        raise ValueError("no exact helper instructions")
    calls=[x for x in ins if "bl\t" in x or "blr\t" in x]
    original={
        "evidence_type":"EXACT_ORIGINAL_NATIVE12_STATIC_HELPER_ARM64_NO_RUNTIME",
        "original_deb_sha256":SRC_DEB,"original_dashboard_sha256":MACHO,
        "helper_start":hex(HELPER),"helper_end":hex(end),
        "original_caller":"CBMultitaskingOverlayView.setupPresetCards... @0xa6484",
        "instruction_count":len(ins),"instructions":ins,
        "calls":calls,"preview_pixels_reconstructed":False,
        "no_vendor_binary_in_new_duoface":True,
    }
    args.out.mkdir(parents=True,exist_ok=True)
    (args.out/"ORIGINAL_PREVIEW_HELPER_INSTRUCTIONS.json").write_text(
        json.dumps(original,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    (args.out/"REPORT.md").write_text(
        "# Native12 original nine-style preview raster helper\n\n"
        +f"Original SHA: {SRC_DEB}\nDashboard SHA: {MACHO}\n"
        +f"Caller: 0xa6484 → {hex(HELPER)}, bounds {hex(HELPER)}..{hex(end)}\n"
        +f"Instructions: {len(ins)}, calls: {len(calls)}\n"
        +"Read-only static evidence; renderer not yet equivalent.\n\n"
        +"## Calls\n"+"\n".join("    "+x for x in calls)+"\n",encoding="utf8")
    print("ORIGINAL_NATIVE12_THUMBNAIL_HELPER_VERIFIED",
          hex(HELPER),hex(end),len(ins),len(calls))
if __name__=="__main__":main()
