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
        cfstrings=[]
        for section in m.sections:
            if section["name"]!="__cfstring":continue
            for off in range(section["fileoff"],section["fileoff"]+section["size"],32):
                if off+32>len(m.data): break
                address=section["vm"]+off-section["fileoff"]
                try:
                    target=m.ptr(address+16)
                    value=m.cstr(target)
                    important=("bridgedapps", "appslist", "userapps", "preferences",
                         "prefs", "appsettings", "plist", "appenabled", "allowedapps",
                         "enabledapps","userappsdefaultinitialized","cbdashboardsettings",
                         "cfpreferences", "duoface.", "carbridge.", "duonavi.", "mobilesubstrate",
                         "notification", "bridgeapps")
                    if value and any(word in value.lower() for word in important):
                        cfstrings.append({"vm":hex(address),"value":value[:160]})
                except Exception:pass
        # Native12's original reloadAppPrefs uses lazy owner path global
        # [0x3812b0] and once initializer descriptor 0x344928. Trace the
        # actual pointers instead of inventing a Preferences filename.
        lazy={}
        if name=="DuoFaceDashboard":
            for addr in (0x3812b0,0x3812b8,0x344908,0x344918,0x344928,
                         0x344930,0x344938,0x344948,0x344958,0x3449a8):
                try:
                    val=m.ptr(addr)
                    try: valstr=m.cstr(val)
                    except Exception: valstr=""
                    lazy[hex(addr)]={"word64":hex(val),
                                     "raw32":m.data[m.map(addr):m.map(addr)+32].hex(),
                                     "points_to_cstring":valstr[:100]}
                except Exception as err: lazy[hex(addr)]={"error":str(err)[:100]}
        decoded_native_settings_owner=None
        if name=="DuoFaceDashboard":
            # Read-only equivalent of native12 lazy initializer 0x3822c.
            # It constructs a 49-byte NSString from obfuscated __TEXT data
            # at 0x30fb6f, then stores it in global slot 0x3812b0.
            # Preserve only the filename in evidence, not any user data.
            seed=m.data[m.map(0x30fb6f):m.map(0x30fb6f)+0x31]
            assert len(seed)==0x31
            decoded=bytearray()
            for ix,b in enumerate(seed):
                n=(ix%5)+1
                # x0 = ((i ^ -0x5b) | seed)*2 - ((i ^ -0x5b) + seed)
                #    = (i ^ -0x5b) XOR seed  (then narrowed to uint8)
                mixed=(b ^ ((ix ^ -0x5b) & 0xff)) & 0xff
                rotated=((mixed >> n) | (mixed << (8-n))) & 0xff
                transform=((ix*0x2b+0x83)&0xff)^rotated
                decoded.append((transform-0x5d)&0xff)
            decoded_native_settings_owner=decoded.decode("utf-8")
        lazy_instruction_map={}
        if name=="DuoFaceDashboard":
            from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
            cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
            for start in (0x3822c,0x380b0,0x37dac,0x36874):
                try:
                    offset=m.map(start)
                    instr=list(cs.disasm(m.data[offset:offset+512],start))
                    lines=[]
                    for ins in instr:
                        lines.append(hex(ins.address)+": "+ins.mnemonic+" "+ins.op_str)
                        if ins.mnemonic=="ret": break
                    lazy_instruction_map[hex(start)]=lines[:130]
                except Exception as error:lazy_instruction_map[hex(start)]=["ERROR: "+str(error)[:160]]
        report["hosts"][name]={"sha256":expected,"original_disassembly_direct_literals":matches,
                              "native_preferences_related_literals":strings[:160],
                              "native_cfstring_constants":cfstrings[:400],
                              "lazy_preference_global_probe":lazy,
                              "native12_obfuscated_config_owner_path":decoded_native_settings_owner,
                              "lazy_preference_initializer_disassembly":lazy_instruction_map,
                              "near_appSettings_cfstrings":[
                                  {"vm":hex(sec["vm"]+offset),"value":m.cstr(m.ptr(sec["vm"]+offset+16))}
                                  for sec in m.sections if sec["name"]=="__cfstring"
                                  for offset in range(0,sec["size"],32)
                                  if ((name=="DuoFaceDashboard" and 0x36f000<=sec["vm"]+offset<0x36f500)
                                      or (name=="DuoFaceUI" and 0x1000e9000<=sec["vm"]+offset<0x1000e9c00))
                              ]}
print(json.dumps(report,ensure_ascii=False,indent=2))
dest=Path("audit/payload-migration/NATIVE17_NATIVE_PREFERENCE_LITERALS_READONLY.json")
dest.parent.mkdir(exist_ok=True,parents=True)
dest.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
