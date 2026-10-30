#!/usr/bin/env python3
"""SHA-checked, READ ONLY original DuoNavi 1.0.4 lock/workspace ABI comparison.

Consumes prior exact imported MSHookMessageEx argument-validated registration
as source of ranges, not guessed offsets. Bounded disassembly proves code paths
but cannot prove iOS16 runtime activation, and ships no original binaries.
"""
import argparse,hashlib,json,pathlib,re
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
PIN="44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--duonavi",required=True)
 p.add_argument("--register-json",required=True)
 p.add_argument("--out",required=True)
 a=p.parse_args()
 buf=pathlib.Path(a.duonavi).read_bytes()
 if hashlib.sha256(buf).hexdigest()!=PIN:raise RuntimeError("incorrect original DuoNavi dylib SHA")
 m=MachO(select_arm64(buf))
 registers=json.loads(pathlib.Path(a.register_json).read_text())["DuoNavi"]["hooks"]
 group=[x for x in registers if 0x2ecf0c<=int(x["pc"],16)<=0x2ed0d4]
 if len(group)!=13 or group[3]["class"]!="SBSuspendedUnderLockManager" or group[-2]["class"]!="SBMainWorkspace":
  raise RuntimeError("DuoNavi unexpected original C hook table identity")
 found={}
 for index,x in enumerate(group):
  start=int(x["replacement"],16)
  stop=int(group[index+1]["replacement"],16) if index+1<len(group) else start+0x120
  if not 0<stop-start<=0x800:raise RuntimeError("unexpected original function size, fail closed")
  off=m.map(start)
  raw=m.data[off:off+(stop-start)]
  instructions=list(Cs(CS_ARCH_ARM64,CS_MODE_ARM).disasm(raw,start))
  if len(instructions)*4!=len(raw):raise RuntimeError("incomplete ARM64 function")
  lines=[];literals=[];returns=[];originals=[]
  prev_storage=x["originalStorage"]
  for ins in instructions:
   val=f"{ins.address:#x}: {ins.mnemonic} {ins.op_str}"
   if ins.mnemonic=="ldr":
    match=re.fullmatch(r"x[0-9]+, #(0x[0-9a-f]+)",ins.op_str)
    if match:
     vm=int(match.group(1),16)
     try:
      st=m.cstr(m.ptr(vm))
      if st and all(32<=ord(ch)<127 for ch in st[:160]):
       val+=" ; original literal='"+st[:100].replace("'","")+"'"
       literals.append(st[:100])
     except (ValueError,IndexError,KeyError):pass
   if ins.mnemonic=="mov" and ins.op_str.endswith(", #0"):
    returns.append(val)
   if ins.mnemonic in ("blr","br"):originals.append(val)
   lines.append(val)
  found[x["selector"]]={"class":x["class"],"registeredPC":x["pc"],
      "replacement":x["replacement"],"originalStorage":prev_storage,
      "end":hex(stop),"instructions":lines,"returnZeroSites":returns,
      "indirectCalls":originals,"strings":sorted(set(literals))}
 obj={"signedOriginalSHA":PIN,"verifiedDuoNaviCRegistrations":len(group),"functions":found}
 out=pathlib.Path(a.out);out.mkdir(parents=True,exist_ok=True)
 (out/"DUONAVI_13_LOCK_AND_WORKSPACE_HOOKS_ARM64.json").write_text(json.dumps(obj,indent=2,ensure_ascii=False)+"\n")
 md=["# DuoNavi 1.0.4: 13 exact C hook implementations for scene, lock and workspace",
     "","Original signed dashboard SHA256: `"+PIN+"`.",
     "C registration proven by previous `EXACT_DUONAVI_REGISTERED_UNDERLOCK_HOOKS.json`",
     "and independent validation against 11 known Native12 originals.",
     "This is read-only ARM64 function evidence, not proof of invocation on a",
     "physical iOS 16 device and not an independent-runtime patch.",""]
 for name,record in found.items():
  md+=["## "+record["class"]+" "+name+" @ "+record["replacement"],
    "- Registration call PC: "+record["registeredPC"],
    "- Original IMP storage: "+str(record["originalStorage"]),
    "- Original callback may be reached through *indirect* dynamic dispatch.",
    "- Literal strings resolved: "+repr(record["strings"]),
    "- Conditional zero-return candidate sites: "+repr(record["returnZeroSites"]),
    "- Indirect calls: "+repr(record["indirectCalls"]),"",
    "### Bounded original ARM64"]
  md+=["    "+line for line in record["instructions"]]
  md+=[""]
 md+=["## Comparison target for independent DuoFace",
     "- Original Native12 and DuoNavi both register the same 3 SBSuspendedUnderLockManager hooks; DuoNavi additionally registers SBMainWorkspace passcode/activation callbacks.",
     "- A low-level no-background/no-underlock decision applies only for an owned, actively bridged scene; do not blanket bypass iPhone locks or non-owned apps.",
     "- Current DuoFace FBScene foreground correction alone is not the same as returning before Apple's under-lock background decision.",
     "- Current CPTemplate sceneWillResignActive hides DuoFace windows while Apple Dock remains; verify iPhone-lock-vs-CarPlay-Home ownership separately.",
     "- No changes to QA120 native Dock sizing, .90 YouTube rotation, .92 divider; no build/DEB/Sileo or hardware Play result in this audit."]
 (out/"DUONAVI_13_LOCK_AND_WORKSPACE_HOOKS_ARM64_VERDICT.md").write_text("\n".join(md)+"\n")
 print("DUONAVI_13_EXACT_ORIGINAL_LOCK_HOOKS_ARM64_PASS",len(found),
       "underlock",sum("UnderLock" in rec["class"] for rec in found.values()),
       "workspace",sum("SBMainWorkspace"==rec["class"] for rec in found.values()))
if __name__=="__main__":main()
