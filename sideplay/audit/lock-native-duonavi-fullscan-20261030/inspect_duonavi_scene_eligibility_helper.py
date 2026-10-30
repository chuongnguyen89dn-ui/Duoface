#!/usr/bin/env python3
"""Read-only bounded SHA-pinned DuoNavi 1.0.4 helper disassembly.

The DuoNavi underlock hooks require an EXTRA boolean helper AFTER shouldBridge:
0x2edb0c and 0x2edc14 BL 0x2eeb24, then CBZ w0, before policy returns NO.
Do not identify helper's semantic purpose from address alone.
"""
import argparse,hashlib,json,pathlib,re
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
PIN="44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"
START=0x2eeb24
LIMIT=0x2eec64
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--duonavi",required=True)
 p.add_argument("--source13",required=True)
 p.add_argument("--out",required=True)
 a=p.parse_args()
 b=pathlib.Path(a.duonavi).read_bytes()
 if hashlib.sha256(b).hexdigest()!=PIN:raise RuntimeError("wrong original DuoNavi SHA")
 first=json.loads(pathlib.Path(a.source13).read_text())["functions"]
 for name in ("_shouldBeBackgroundUnderLockForScene:withSettings:","shouldBeUnderLockForScene:"):
  code=first[name]["instructions"]
  if not any(line.endswith("bl #0x2eeb24") for line in code):
   raise RuntimeError("required direct original helper edge unverified "+name)
 m=MachO(select_arm64(b))
 pos=m.map(START)
 code=m.data[pos:pos+(LIMIT-START)]
 inst=list(Cs(CS_ARCH_ARM64,CS_MODE_ARM).disasm(code,START))
 if len(inst)*4!=len(code):raise RuntimeError("incomplete bounded helper disasm")
 lines=[];literals=[]
 for z in inst:
  line=f"{z.address:#x}: {z.mnemonic} {z.op_str}"
  match=re.fullmatch(r"x[0-9]+, #(0x[0-9a-f]+)",z.op_str)
  if match and z.mnemonic in ("ldr","adr"):
   try:
    vm=int(match.group(1),16)
    raw=m.cstr(m.ptr(vm) if z.mnemonic=="ldr" else vm)
    if raw and len(raw)<120 and all(32<=ord(t)<127 for t in raw):
     line+=" ; original literal='"+raw.replace("'","")+"'"
     literals.append(raw)
   except (ValueError,IndexError,KeyError):pass
  lines.append(line)
 result={"originalSHA256":PIN,"helper":hex(START),
         "boundedEndExclusive":hex(LIMIT),"notProvenFullFunction":True,
         "directCallers":["0x2edb0c background under lock","0x2edc14 should under lock"],
         "readableLiterals":sorted(set(literals)),"instructions":lines}
 out=pathlib.Path(a.out);out.mkdir(parents=True,exist_ok=True)
 (out/"DUONAVI_UNDERLOCK_EXTRA_GUARD_HELPER_ARM64.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
 txt=["# DuoNavi additional under-lock scene eligibility guard — exact bounded ARM64",
     "","Original DuoNavi SHA256: `"+PIN+"`.",
     "Native12 under-lock owner gate has isUIAppBridging+shouldBridge:, but",
     "DuoNavi 1.0.4 **also calls helper 0x2eeb24 and checks the return value**",
     "before overriding Apple's under-lock decision. This is verified by",
     "two separate direct ARM64 caller PC sites. Semantic meaning of helper",
     "is NOT assigned from its address; inspect body below.",
     "","## Original bounded helper disassembly "+hex(START)+".."+hex(LIMIT),
     "- Original literals: "+repr(result["readableLiterals"]),"",
     "Note: window may include adjacent function bytes; no forced function-end claim.",""]
 txt+=["    "+x for x in lines]
 txt+=["","## Independent DuoFace implication",
   "- Even an owned YouTube scene must meet its actual hosted scene eligibility criteria.",
   "- Do not return false for all scenes, bypass SBMainWorkspace passcode or disable iPhone lock; nonowned scenes use Apple's original decision.",
   "- Preserve QA120 Dock sizing, Home scene frontmost behavior, .90 orientation and .92 divider. This report is research, not a runtime build/test."]
 (out/"DUONAVI_UNDERLOCK_EXTRA_GUARD_VERDICT.md").write_text("\n".join(txt)+"\n")
 print("DUONAVI_ORIGINAL_UNDERLOCK_EXTRA_GUARD_PASS",len(lines),result["readableLiterals"])
if __name__=="__main__":main()
