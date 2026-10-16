#!/usr/bin/env python3
"""Inspect native17's known original native12 preference selectors and strings.
Pin DEB checksum; read only; no side effects to license, iPhone or Sileo."""
import hashlib,json,subprocess,tempfile,sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_native12_license_class_xrefs import MachO,select_arm64
DEB=Path("dist/payload-migration/native17/com.duoface.independent_0.1.0~native17_iphoneos-arm64.deb")
SHA="60f8a4277dd9df912036f93fc8edfd0897a516752f3014863459d5ce89ad5fff"
HOSTS={
"DuoFaceDashboard":("var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
[0x36f128,0x36f468,0x36f488,0x36f428,0x36f448,0x346148,0x3460a8]),
"DuoFaceUI":("var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
"cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
[0x1000ea548,0x1000ea568,0x1000ea588,0x1000ea5a8,0x1000ea5c8,0x1000ea5e8,0x1000ea608])
}
assert hashlib.sha256(DEB.read_bytes()).hexdigest()==SHA
report={"status":"READONLY_NATIVE17_PREFERENCES_NATIVE12_REAL_BINARY_STRINGS",
        "deb_sha256":SHA,"device_tested":False,"binary_modified":False,"hosts":{}}
with tempfile.TemporaryDirectory() as td:
    subprocess.run(["dpkg-deb","-x",str(DEB),td],check=True)
    for name,(path,expected,addresses) in HOSTS.items():
        raw=(Path(td)/path).read_bytes()
        assert hashlib.sha256(raw).hexdigest()==expected
        m=MachO(select_arm64(raw))
        matches={}
        for addr in addresses:
            try:
                mapping=m.map(addr)
                head=m.data[mapping:mapping+32].hex()
                candidate=m.ptr(addr+16)
                try: value=m.cstr(candidate)
                except Exception: value=""
                matches[hex(addr)]={"raw32":head,"cfstring_data_pointer":hex(candidate),
                                    "as_cstring":m.cstr(addr),
                                    "cfstring_value":value}
            except Exception as exc: matches[hex(addr)]={"error":type(exc).__name__}
        strings=[]
        for sec in m.sections:
            if sec["name"] not in ("__cstring","__objc_methname"): continue
            data=m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
            off=0
            while off<len(data):
                end=data.find(b"\0",off)
                if end<0:break
                s=data[off:end].decode("utf-8","replace")
                if any(word in s.lower() for word in ("prefs", "settings.plist", "bridgedapps", "bridgeapp", "duonavi","carbridge","duoface")):
                    strings.append({"vm":hex(sec["vm"]+off),"value":s[:190]})
                off=end+1
        report["hosts"][name]={"sha256":expected,"original_disassembly_direct_literals":matches,
                              "native_preferences_related_literals":strings[:160]}
print(json.dumps(report,ensure_ascii=False,indent=2))
dest=Path("audit/payload-migration/NATIVE17_NATIVE_PREFERENCE_LITERALS_READONLY.json")
dest.parent.mkdir(exist_ok=True,parents=True)
dest.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
