#!/usr/bin/env python3
"""Read-only native12 metadata and disassembly for CarPlay Add App + prefs.
Do not mutate binary or claim to have tested UI on actual CarPlay."""
import argparse, hashlib, json, re, subprocess, tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64, BINARIES, NATIVE12_SHA

TARGETS={
    "DuoFaceDashboard":{
        "CBMultitaskingOverlayView":["addMoreAppsTapped:","dismissCustomAlert:","setupAppPickerCardsInCardW:cardH:contentY:","appSelected:"],
        "CBDashboardSettings":["init","reload","reloadAppPrefs","bridgedApps","setBridgedApps:"],
        "CBBridgeManager":["handleSettingsChanged","showAppPickerForSlot:","shouldBridge:","trackBridgedBundleID:"],
        "CBBridgeManagerDashboard":["bridgedApps"],
    },
    "DuoFaceUI":{
        "CBGeneralSettingsViewController":["loadPreferences","savePreferences"],
    }
}
def methods(m,clazz):
    cls=m.classes()[clazz]
    items={}
    for symbol,obj in (("-",cls["class_ptr"]),("+",m.ptr(cls["class_ptr"]))):
        if not obj:continue
        ro=m.ptr(obj+32)&~7;head=m.ptr(ro+32)
        if not head:continue
        flags,count=m.p32(head),m.p32(head+4)
        assert count<500
        rel=bool(flags&0x80000000)
        for i in range(count):
            e=head+8+i*(12 if rel else 24)
            if rel:
                adr=e+m.pi32(e);selvm=adr if flags&0x40000000 else m.ptr(adr)
                imp=e+8+m.pi32(e+8)
                typ=e+4+m.pi32(e+4)
            else:
                selvm=m.ptr(e);typ=m.ptr(e+8);imp=m.ptr(e+16)
            items[symbol+m.cstr(selvm)]={"vm":imp,"type":m.cstr(typ)}
    return items

def disassemble(m,start,end):
    cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    lines=[]
    for ins in cs.disasm(m.data[m.map(start):m.map(start)+min(end-start,40000)],start):
        if len(lines)>650:break
        lines.append(f"{ins.address:#x}: {ins.mnemonic} {ins.op_str}")
    return lines

def pref_literals(m):
    result=[]
    for section in m.sections:
        if section["name"] not in ("__cstring","__objc_methname"):continue
        data=m.data[section["fileoff"]:section["fileoff"]+section["size"]]
        for mat in re.finditer(rb"[\x20-\x7e]{5,}\x00",data):
            t=mat.group()[:-1].decode("ascii","replace")
            if len(t)>200:continue
            if re.search(r"bridgedApps|bridged_apps|bridgedapps|appbridge|reloadApp|reloadPref|[Pp]refs|[Ss]ettings[.]plist|[Aa]dd[Mm]ore[Aa]pps|ADD_MORE_APPS|com[.]duoface|com[.]duonavi",t):
                result.append({"vm":hex(section["vm"]+mat.start()),"text":t})
    return result[:180]

def inspect(binary,raw):
    m=MachO(select_arm64(raw));out={}
    for name,selectors in TARGETS[binary].items():
        choices=methods(m,name)
        keys=sorted([(info["vm"],sel) for sel,info in choices.items() if info["vm"]])
        methods_out={}
        for sel in selectors:
            met=choices.get("-"+sel) or choices.get("+"+sel)
            if not met:raise RuntimeError(f"{binary}.{name}.{sel} not found")
            begin=met["vm"]
            end=next((v for v,n in keys if v>begin),begin+1600)
            methods_out[sel]={"imp_vm":hex(begin),"type":met["type"],"limit_vm":hex(end),
                "disasm":disassemble(m,begin,end)}
        out[name]=methods_out
    return {"sha256":hashlib.sha256(raw).hexdigest(),"classes":out,"related_literals":pref_literals(m)}
def main():
    p=argparse.ArgumentParser();p.add_argument("--deb",required=True,type=Path);p.add_argument("--out",required=True,type=Path)
    a=p.parse_args()
    assert hashlib.sha256(a.deb.read_bytes()).hexdigest()==NATIVE12_SHA
    with tempfile.TemporaryDirectory(prefix="df-app-picker-chain-") as t:
        subprocess.run(["dpkg-deb","-x",str(a.deb),t],check=True)
        result={k:inspect(k,(Path(t)/path).read_bytes()) for k,path in BINARIES.items()}
    out={"status":"NATIVE12_CARPLAY_ADD_APP_CHAIN_READONLY",
         "baseline_deb_sha256":NATIVE12_SHA,"debs_mutated":False,"devices_tested":False,
         "binaries":result}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
    for name,b in result.items():
        print("BINARY",name)
        print("LITERALS",[(x["vm"],x["text"]) for x in b["related_literals"][:70]])
        for cl,methods in b["classes"].items():
            for name,data in methods.items():
                selected=[x for x in data["disasm"]
                          if "bl " in x or re.search(r"mov[kzn]? .*, #",x)]
                print("METHOD",cl,name,data["imp_vm"],data["type"],
                      "instructions",len(data["disasm"]),"selected",selected[:23])
if __name__=="__main__":main()
