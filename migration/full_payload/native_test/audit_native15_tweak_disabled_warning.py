#!/usr/bin/env python3
"""Native15 vs known-working native12: read-only forensic report for the
'TWEAK ĐANG BỊ TẮT' DuoFaceUI screenshot. Does not remove runtime protections,
modify DEBs, assume tweak injection is disabled, or assert device outcome.
"""
import argparse, hashlib, json, pathlib, plistlib, re, subprocess, tempfile
from audit_native12_license_class_xrefs import MachO, select_arm64

NATIVE12="85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
NATIVE15="8d111e638dce357dfb1187c5b10fdf776d7485c95198ad4cf248d6b51d1740e3"
HOSTS=[
 "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
 "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
]
MODULES=["DuoFaceSmartConnection","DuoFaceInCarAddApps"]
FILT_DIR="var/jb/Library/MobileSubstrate/DynamicLibraries/"
TERMS=["tweak", "inject", "jailbreak", "dopamine", "bootstrap", "choicy",
       "respring", "đang bị tắt", "bị chặn", "phát hiện", "duofacesb",
       "springboard", "heartbeat", "handshake", "ping", "daemon",
       "trạng thái"]
METHOD_RE=re.compile(r"(tweak|inject|jailbreak|check|heartbeat|handshake|ping|daemon|bootstrap|detect|monitor|available|run|load|alert|block)",re.I)
ASCII_RE=re.compile(rb"[\x20-\x7e]{5,400}")
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def subprocess_checked(*argv):return subprocess.check_output(argv,stderr=subprocess.STDOUT,text=True).strip()
def scan_binary(raw):
    found=[]
    # ASCII printable segments, with offsets.
    for m in ASCII_RE.finditer(raw):
        s=m.group().decode("ascii")
        if any(x in s.lower() for x in TERMS) and len(s)<300:
            found.append({"offset":hex(m.start()),"encoding":"ascii","text":s})
    # Search UTF16LE keyword occurrences in non-ASCIIZ sections (Vietnamese UI)
    for term in TERMS:
        encoded=term.encode("utf-16-le")
        start=0
        while True:
            i=raw.lower().find(encoded.lower(),start)
            if i<0:break
            before=max(0,i-120);after=min(len(raw),i+len(encoded)+260)
            # align to the matched two-byte offset; decode nearby chars
            b=before+(i-before)%2
            preview=raw[b:after-((after-b)%2)].decode("utf-16-le","replace")
            preview="".join(x for x in preview if (x.isprintable() or x in "\n\t"))
            found.append({"offset":hex(i),"encoding":"utf16le_nearby","term":term,"preview":preview[:180]})
            start=i+len(encoded)
            if len(found)>220:break
    seen=set();dedup=[]
    for v in found:
        k=(v["offset"],v["encoding"])
        if k not in seen:seen.add(k);dedup.append(v)
    return dedup[:250]
def selected_methods(raw):
    m=MachO(select_arm64(raw))
    classes=m.classes()
    result={}
    for name,info in classes.items():
        interesting=[sel for sel in info["methods"] if METHOD_RE.search(sel)]
        if interesting:
            result[name]=interesting[:90]
    return {"classes":len(classes),"interesting_class_methods":result}
def plist_tree(root):
    out=[]
    for p in root.rglob("*"):
        if not p.is_file() or p.stat().st_size>2000000 or p.suffix.lower() not in (".plist",".strings"):
            continue
        if p.name in [m+".plist" for m in MODULES] or "DuoFace" in p.as_posix():
            try:
                blob=p.read_bytes()
                obj=plistlib.loads(blob)
                line=json.dumps(obj,ensure_ascii=False,default=str)
                if any(x in line.lower() for x in TERMS):
                    out.append({"path":str(p.relative_to(root)),"matching_strings":line[:600]})
            except Exception:continue
    return out[:60]
def run():
    a=argparse.ArgumentParser()
    a.add_argument("--native12",required=True,type=pathlib.Path)
    a.add_argument("--native15",required=True,type=pathlib.Path)
    a.add_argument("--out",required=True,type=pathlib.Path)
    p=a.parse_args()
    assert sha(p.native12)==NATIVE12
    assert sha(p.native15)==NATIVE15
    with tempfile.TemporaryDirectory(prefix="df15-injection-audit-") as tmp:
        dirs={}
        for version,deb in (("native12",p.native12),("native15",p.native15)):
            root=pathlib.Path(tmp)/version
            subprocess.run(["dpkg-deb","-x",str(deb),str(root)],check=True)
            dirs[version]=root
        out={
         "status":"NATIVE15_UI_TWEAK_DISABLED_WARNING_READONLY",
         "native12_sha256":NATIVE12,"native15_sha256":NATIVE15,
         "package_diff":{},"warning_evidence":{},"module_filters":{},
         "cannot_confirm_jailbreak_device_tweak_injection":True,
         "debs_changed":False,"device_tested":False
        }
        for name in HOSTS:
            twelve=dirs["native12"]/name
            fifteen=dirs["native15"]/name
            assert twelve.exists() and fifteen.exists()
            out["package_diff"][name]={
             "native12_sha256":sha(twelve),"native15_sha256":sha(fifteen),
             "identical":sha(twelve)==sha(fifteen)}
            raw=fifteen.read_bytes()
            evidence=scan_binary(raw)
            if name.endswith("/DuoFaceUI"):
                meth=selected_methods(raw)
            else:
                meth={}
            out["warning_evidence"][name]={"diagnostic_literals":evidence,
                                          "selected_methods":meth}
        for mod in MODULES:
            fil=dirs["native15"]/(FILT_DIR+mod+".plist")
            bin=dirs["native15"]/(FILT_DIR+mod+".dylib")
            assert fil.is_file() and bin.is_file()
            desc=plistlib.loads(fil.read_bytes())
            out["module_filters"][mod]={
                "plist":desc,"signed_dylib_sha256":sha(bin),
                "dylib_strings":scan_binary(bin.read_bytes())[:35]}
        out["localized_plists"]=plist_tree(dirs["native15"])
    assert all(x["identical"] for x in out["package_diff"].values()),"native15 unexpectedly altered host binaries"
    p.out.parent.mkdir(parents=True,exist_ok=True)
    p.out.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
    print("EXACT_HOSTS_NATIVE12_NATIVE15_IDENTICAL")
    print("MODULE_FILTERS",json.dumps(out["module_filters"],ensure_ascii=False)[:2000])
    for k,v in out["warning_evidence"].items():
        print("UI_DIAGNOSTIC_FILE",k)
        print("LITERALS",json.dumps(v["diagnostic_literals"][:65],ensure_ascii=False))
        if v["selected_methods"]:print("METHODS",json.dumps(v["selected_methods"],ensure_ascii=False)[:5500])
    print("WARNING_REPORT_READONLY_CREATED")
if __name__=="__main__":run()
