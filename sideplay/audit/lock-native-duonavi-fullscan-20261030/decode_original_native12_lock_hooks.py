#!/usr/bin/env python3
"""Precise SHA-pinned original Native12 ARM64 *under-lock hook* disassembly.

This does NOT provide runnable hooks, vendor code, license, or claims of runtime
use; it shows bounded machine code and exact original install registration.
"""
import argparse,hashlib,json,pathlib,re,struct
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from native12_objc_stub_decoder import sections_for_binary
PIN="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
# Start/end derived from original SHA-verified registration and next replacement.
RANGES={
 "fbscene_update_settings":(0x2c7e08,0x2c8410),
 "fbscene_apply_update":(0x2c8410,0x2c85d0),
 "scene_prepare_update":(0x2c85d0,0x2c8668),
 "underlock_intercept_update":(0x2c8668,0x2c8768),
 "underlock_should_background":(0x2c8768,0x2c8870),
 "underlock_should_underlock":(0x2c8870,0x2c895c),
 "scene_reference_size":(0x2c895c,0x2c8a50),
 "scene_reference_orientation":(0x2c8a50,0x2c8b4c),
 "scene_supports_orientation":(0x2c8b4c,0x2c8ca8),
 "manual_scene_observer":(0x2c8ca8,0x2c8ef8),
 "manual_scene_destroy":(0x2c8ef8,0x2c9060)
}
def main():
 parser=argparse.ArgumentParser()
 parser.add_argument("--native12-dashboard",required=True)
 parser.add_argument("--out",required=True)
 a=parser.parse_args()
 p=pathlib.Path(a.native12_dashboard)
 digest=hashlib.sha256(p.read_bytes()).hexdigest()
 if digest!=PIN:raise RuntimeError("wrong original Native12 Dashboard SHA "+digest)
 sections,read=sections_for_binary(p)
 def cstring(vm,maxlen=180):
  data=bytearray()
  for i in range(maxlen):
   v=read(vm+i,1)
   if not v:return None
   if v==bytes((0,)):break
   data+=v
  if data and all(32<=x<=126 for x in data):
   return data.decode("ascii")
  return None
 def ptr(vm):
  b=read(vm,8)
  if b is None:return None
  return struct.unpack("<Q",b)[0]
 decoded={}
 for name,(low,high) in RANGES.items():
  raw=read(low,high-low)
  if raw is None:raise RuntimeError("Original unmapped "+name)
  arr=list(Cs(CS_ARCH_ARM64,CS_MODE_ARM).disasm(raw,low))
  if len(arr)!=len(raw)//4:raise RuntimeError("Original incomplete "+name)
  lines=[]; strings=[];branches=[];calls=[]
  for inst in arr:
   line=f"{inst.address:#x}: {inst.mnemonic} {inst.op_str}"
   match=re.fullmatch(r"x[0-9]+, #(0x[0-9a-f]+)",inst.op_str)
   if match and inst.mnemonic in ("adr","ldr"):
    addr=int(match.group(1),16)
    try:
     v=cstring(addr) if inst.mnemonic=="adr" else cstring(ptr(addr) or 0)
     if v:
      strings.append(v)
      line+=" ; original_literal="+repr(v)
    except (ValueError,TypeError):pass
   if inst.mnemonic in ("b","bl","br","blr","cbz","cbnz","tbz","tbnz"):
    if inst.mnemonic in ("blr","bl"):calls.append(line)
    else:branches.append(line)
   lines.append(line)
  decoded[name]={"start":hex(low),"end":hex(high),"instruction_count":len(arr),
                 "literal_matches":sorted(set(strings)),"branches":branches,
                 "calls":calls,"instructions":lines}
 out=pathlib.Path(a.out);out.mkdir(exist_ok=True,parents=True)
 (out/"NATIVE12_11_HOOKS_LOCK_ARM64.json").write_text(json.dumps({
   "sha256":PIN,"exact_registered_hook_count":11,"hooks":decoded
  },indent=2,ensure_ascii=False)+"\n")
 md=["# Original Native12 — all 11 installed hooks (3 specific under-lock hooks)",
     "","Original SHA256: `"+PIN+"`",
     "Evidence: exact 11 MSHookMessageEx replacements are already verified in",
     "`sideplay/audit/native12-foreground-hooks-20261027/HOOKS_AND_ARM64.json`.",
     "This extends their 3 previously decoded windows to all 11, including the",
     "**real SBSuspendedUnderLockManager selectors**. Disassembly is binary evidence",
     "NOT proof the hook fires when the user locks iPhone or video plays.",""]
 for name,item in decoded.items():
  md+=["## "+name+" "+item["start"]+".."+item["end"],
       "- ARM64 instructions: "+str(item["instruction_count"]),
       "- Decoded literals: "+repr(item["literal_matches"]),
       "- Call count: "+str(len(item["calls"]))+"; branch count: "+str(len(item["branches"])),""]
  md+=["    "+x.replace("`","'") for x in item["instructions"]]
  md+=[""]
 md+=["## Exact distinction from current DuoFace",
      "- Original Native12 installed THREE under-lock callbacks: interceptUpdateForScene:withNewSettings:, _shouldBeBackgroundUnderLockForScene:withSettings:, shouldBeUnderLockForScene:.",
      "- Current first-party `DFSceneLifecycle.m` does NOT register those three; it corrects FBScene foreground and consumes owned manual observer updates only.",
      "- Original also hooks _UIScenePresentationView, FBScene apply-update, scene-destroy. A blanket foreground YES or skipping all callbacks would be unsafe.",
      "- Original DuoNavi independently has a real IOPM sleep assertion pair, and its Dashboard shares many CBBridgeManager/CBBridgedUIAppView owners with Native12. These source similarities alone do not establish runtime lock behavior.",
      "- To match the user's Dock-still-visible black panes without harming CarPlay Home, gate an independent per-scene owner and generation, distinguish phone lock vs native CarPlay Home and preserve teardown on Home.",
      "- Any proposed patch must be built/tested and device-tested; this report makes no fix claim."]
 (out/"NATIVE12_11_HOOKS_LOCK_ARM64_VERDICT.md").write_text("\n".join(md)+"\n")
 print("NATIVE12_ALL_11_INSTALLED_HOOKS_DISASSEMBLED_PASS",len(decoded),
       "underlock_count",sum(k.startswith("underlock_") for k in decoded))
if __name__=="__main__":main()
