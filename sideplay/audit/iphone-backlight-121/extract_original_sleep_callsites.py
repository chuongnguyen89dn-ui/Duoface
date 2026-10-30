#!/usr/bin/env python3
"""Read-only verified original ARM64 method evidence, no vendor code imported."""
import argparse,bisect,hashlib,json,pathlib
from audit_native12_license_class_xrefs import MachO,select_arm64
from audit_native12_carplay_add_app_chain import methods,disassemble
SHA={
"DuoNavi": "44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
"OmniBridge": "d99b8d00dc60f69db7b54fc1addaec6b8cb866b8dcdde6f1d85e06ce5b7d6e79",
"OmniSplit": "f696b518579266cf99cfd46f85cb54931d18e679c793a563ee2fcc9bf8115754"}
TERMS=("carplaysleepassertion","idleTimerDisabled","shouldBeBackgroundUnderLock","preventsDisplaySleep",
"backlight","brightness","lockScreen","displayBlank","backgroundUnderLock")
def main():
  ap=argparse.ArgumentParser()
  for k in ("duonavi","omnibridge","omnisplit","out"):ap.add_argument("--"+k,required=True)
  args=ap.parse_args();out=pathlib.Path(args.out);out.mkdir(parents=True,exist_ok=True)
  info={}
  for name,path in (("DuoNavi",args.duonavi),("OmniBridge",args.omnibridge),("OmniSplit",args.omnisplit)):
    binary=pathlib.Path(path).read_bytes()
    if hashlib.sha256(binary).hexdigest()!=SHA[name]:raise RuntimeError(name+" SHA256 does not match actual original")
    mach=MachO(select_arm64(binary))
    if name=="DuoNavi":
      cfstrings={}
      # Original verified IOPM acquire method at 0x1c05b8 passes these
      # two literal CFStrings in x0 and x2. Capture the public API argument
      # names (not implementation/license) to distinguish idle-vs-display
      # assertions. If any pointer is protected, retain an unresolved value.
      for role,vm in (("assertionType",0x39c0600),("assertionName",0x39c05e0)):
        try:
          cfstrings[role]=mach.cstr(mach.ptr(vm+16))
        except (ValueError,KeyError,IndexError,AssertionError) as error:
          cfstrings[role]="unresolved:"+type(error).__name__
    else:
      cfstrings={}
    classes={}
    # Some OmniCar arm64e chained/auth pointers cannot be represented by the
    # original non-auth classlist decoder. Fail closed *for that binary only*
    # rather than fabricate method names or skip DuoNavi's proven metadata.
    try:
      class_names=list(mach.classes())
      class_error=None
    except (ValueError,KeyError,IndexError,AssertionError) as e:
      class_names=[]
      class_error=type(e).__name__+": "+str(e)
    print("ORIGINAL121_METHOD_SCAN",name,"classes",len(class_names),
          "metadata_status",class_error or "decoded",flush=True)
    for cl in class_names:
      try:classes[cl]=methods(mach,cl)
      except (ValueError,KeyError,IndexError,AssertionError):continue
    starts=sorted(set(m.get("vm") for d in classes.values() for m in d.values() if m.get("vm")))
    matched=[]
    for cl,d in classes.items():
      for sel,m in d.items():
        if not any(k.lower() in sel.lower() for k in TERMS):continue
        vm=m.get("vm")
        if not vm:continue
        j=bisect.bisect_right(starts,vm)
        limit=min(starts[j] if j<len(starts) else vm+0x900,vm+0x900)
        instructions=disassemble(mach,vm,limit)
        matched.append({"class":cl,"selector":sel,"imp":hex(vm),
                        "instructionCount":len(instructions),"instructions":instructions[:160]})
    info[name]={"sha256":SHA[name],"carPlaySleepAssertionCFStrings":cfstrings,"classCount":len(classes),
                "metadataError":class_error,"methods":matched}
  (out/"ORIGINAL_SLEEP_METHOD_IMP.json").write_text(json.dumps(info,indent=2,ensure_ascii=False)+"\n")
  md=["# DuoNavi / OmniCar original sleep assertion, blanking and lock policy — ARM64",
      "","SHA verified original binaries, bounded ARM64 method inspection. Selector presence is NOT proof of invocation.",""]
  for name,row in info.items():
    md+=["## "+name,"- SHA256: "+row["sha256"],"- Verified IOPM CFString x0/x2: "+str(row["carPlaySleepAssertionCFStrings"]),"- Matches: "+str(len(row["methods"])),
           "- Class metadata: "+(row["metadataError"] or "decoded"),""]
    for method in row["methods"]:
      md+=["### "+method["class"]+"."+method["selector"]+" @ "+method["imp"],
            "ARM64 instructions: "+str(method["instructionCount"])]
      md+=["    "+x[:230].replace(chr(96),"'") for x in method["instructions"][:130]]
      md+=[""]
  md+=["## Limits","Methods without Objective-C class metadata and indirect C calls may not appear. Do not claim screenshot brightness or hardware Play fixed by this read-only scan."]
  (out/"ORIGINAL_SLEEP_CALLSITES.md").write_text("\n".join(md)+"\n")
  print("ORIGINAL121_ARM64_SHA_PINNED_PASS",{k:len(v["methods"]) for k,v in info.items()})
if __name__=="__main__":main()
