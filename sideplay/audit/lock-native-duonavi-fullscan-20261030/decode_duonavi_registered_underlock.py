#!/usr/bin/env python3
"""Read-only original DuoNavi C hook receiver + selector proof.

Requires verified original whole-file hashes; disassembles imported
MSHookMessageEx argument setup without loading/changing vendor binary.
Unit fixture must match historical 11 Native12 hooks exactly before DuoNavi
results are considered proven.
"""
import argparse,collections,hashlib,json,pathlib,re
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
from verify_duonavi_hook_imports import imported_stubs,PINS
EXPECTED_NATIVE=[
("FBScene","updateSettings:withTransitionContext:completion:"),
("FBScene","_applyUpdateWithContext:completion:"),
("_UIScenePresentationView","scene:didPrepareUpdateWithContext:"),
("SBSuspendedUnderLockManager","interceptUpdateForScene:withNewSettings:"),
("SBSuspendedUnderLockManager","_shouldBeBackgroundUnderLockForScene:withSettings:"),
("SBSuspendedUnderLockManager","shouldBeUnderLockForScene:"),
("SBDeviceApplicationSceneViewController","setContentReferenceSize:withInterfaceOrientation:"),
("SBDeviceApplicationSceneViewController","setContentReferenceSize:withContentOrientation:andContainerOrientation:"),
("SBDeviceApplicationSceneHandle","_mainSceneSupportsInterfaceOrientation:"),
("SBAppViewController","sceneHandle:didUpdateSettingsWithDiff:previousSettings:"),
("SBAppViewController","sceneHandle:didDestroyScene:"),
]
LIT=re.compile(r"^x([0123]), #(0x[0-9a-f]+)$")
def decode(path,name):
    orig=pathlib.Path(path).read_bytes()
    filehash=hashlib.sha256(orig).hexdigest()
    if filehash!=PINS[name]:raise ValueError(name+" original hash mismatch")
    m=MachO(select_arm64(orig))
    imported=imported_stubs(m)
    def targets(s):
        return {pc for k,pcs in imported.items() if s.lower() in k.lower() for pc in pcs}
    hooks=targets("MSHookMessageEx")
    classes=targets("_objc_getClass")
    if len(hooks)!=1 or not classes:raise ValueError(name+" uncertain imported stub identity")
    found=[]
    for sec in m.find_sections("__text"):
        vm,size,off=sec["vm"],sec["size"],sec["fileoff"]
        q=collections.deque(maxlen=160)
        for ins in Cs(CS_ARCH_ARM64,CS_MODE_ARM).disasm(m.data[off:off+size],vm):
            if ins.mnemonic in ("bl","b"):
                try:t=int(ins.op_str.removeprefix("#"),16)
                except ValueError:t=-1
                if t in hooks:
                    prior=list(q)
                    def lastarg(reg,limit=18):
                        for x in reversed(prior[-limit:]):
                            z=LIT.fullmatch(x.op_str)
                            if z and int(z.group(1))==reg and x.mnemonic in ("adr","ldr"):
                                return x.mnemonic,int(z.group(2),16)
                        return None
                    selarg=lastarg(1,15)
                    implarg=lastarg(2,15)
                    oldarg=lastarg(3,15)
                    cl=None
                    for index in range(len(prior)-1,-1,-1):
                        x=prior[index]
                        if x.mnemonic not in ("bl","b"):continue
                        try:target=int(x.op_str.removeprefix("#"),16)
                        except ValueError:continue
                        if target not in classes:continue
                        for before in reversed(prior[max(index-10,0):index]):
                            z=LIT.fullmatch(before.op_str)
                            if z and before.mnemonic=="adr" and z.group(1)=="0":
                                try:cl=m.cstr(int(z.group(2),16))
                                except (ValueError,IndexError,KeyError):cl=None
                                break
                        break
                    sel=None
                    if selarg:
                        typ,address=selarg
                        try:sel=m.cstr(m.ptr(address) if typ=="ldr" else address)
                        except (ValueError,IndexError,KeyError):sel=None
                    def fmt(arg):return hex(arg[1]) if arg else None
                    found.append({"pc":hex(ins.address),"class":cl,"selector":sel,
                        "replacement":fmt(implarg),"originalStorage":fmt(oldarg),
                        "classEvidence":"nearest objc_getClass + explicit ADR literal",
                        "selectorEvidence":"nearest before-hook X1 SEL ref" if selarg else "unresolved"})
            q.append(ins)
    return {"originalSHA256":filehash,"sliceSHA256":hashlib.sha256(m.data).hexdigest(),
      "registeredHookCalls":len(found),"resolved":sum(bool(x["class"] and x["selector"]) for x in found),
      "hooks":found}
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--native12",required=True)
    parser.add_argument("--duonavi",required=True)
    parser.add_argument("--out",required=True)
    a=parser.parse_args()
    native=decode(a.native12,"Native12")
    duo=decode(a.duonavi,"DuoNavi")
    fixture=[x for x in native["hooks"] if 0x2c7c54<=int(x["pc"],16)<=0x2c7e04]
    if [(x["class"],x["selector"]) for x in fixture]!=EXPECTED_NATIVE:
        raise RuntimeError("Native12 exact 11 registered method argument test mismatch: "+
                            repr([(x["pc"],x["class"],x["selector"]) for x in fixture]))
    duolock=[x for x in duo["hooks"] if x["class"]=="SBSuspendedUnderLockManager"]
    out=pathlib.Path(a.out);out.mkdir(parents=True,exist_ok=True)
    values={"Native12_Fixture":fixture,"Native12_All":native["registeredHookCalls"],
            "DuoNavi":duo,"DuoNavi_UnderLock_Registered":duolock}
    (out/"EXACT_DUONAVI_REGISTERED_UNDERLOCK_HOOKS.json").write_text(json.dumps(values,indent=2,ensure_ascii=False)+"\n")
    lines=["# Exact original DuoNavi signed under-lock hook registration vs Native12",
      "","This audit reads only original Mach-O + ARM64 argument setup and validates",
      "its own implementation against the 11 previously proven Native12 registered",
      "class/selector pairs before interpreting DuoNavi.","",
      "## Trust boundaries",
      "- Full original signed dylib SHA256 verified; FAT arm64 slice SHA separately recorded.",
      "- Imported MSHookMessageEx located using Mach-O LC_DYSYMTAB indirect symbols.",
      "- Class and selector recovered by direct ARM64 ADR/SEL-ref register provenance.",
      "- A decoded registration implies attempted hook installation, not successful",
      "runtime invocation on iOS16, and is not proof of physical Play fixes.","",
      "## Native12 self-test",
      f"- Exact registration fixture: {len(fixture)} matched to 11 preverified methods",
      f"- Imported hook calls scanned: {native['registeredHookCalls']}","",
      "## DuoNavi signed binary",
      f"- Full original SHA: {duo['originalSHA256']}",
      f"- Arm64 slice SHA: {duo['sliceSHA256']}",
      f"- Imported MSHookMessageEx direct callsites: {duo['registeredHookCalls']}",
      f"- Calls with both resolved class+selector: {duo['resolved']}",
      f"- Confirmed SBSuspendedUnderLockManager registration calls: {len(duolock)}",""]
    for x in duolock:
        lines += [f"- {x['pc']}: `{x['class']} {x['selector']}`; replacement {x['replacement']}, previous IMP storage {x['originalStorage']}"]
    lines += ["","## Caution","If DuoNavi 0 under-lock methods decoded, inspect unresolved hooks/other dispatch before concluding not registered."]
    (out/"EXACT_DUONAVI_UNDERLOCK_REGISTRATION_VERDICT.md").write_text("\n".join(lines)+"\n")
    print("EXACT_DUONAVI_ORIGINAL_HOOK_REGISTRATION_PROVEN",len(duolock),"DuoNavi total",duo["registeredHookCalls"],
          "native fixture",len(fixture))
if __name__=="__main__":main()
