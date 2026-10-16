#!/usr/bin/env python3
"""Read-only arm64 native19 UI preference lazy initializer discovery."""
import hashlib,json,subprocess,tempfile
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
SRC=Path("dist/payload-migration/native19/com.duoface.independent_0.1.0~native19_iphoneos-arm64.deb")
SHA="91feda0a7ff24bd7759b7448303d61fe774b16184e383fc11b6839186fa1ae1d"
assert hashlib.sha256(SRC.read_bytes()).hexdigest()==SHA
with tempfile.TemporaryDirectory() as t:
 subprocess.run(["dpkg-deb","-x",str(SRC),t],check=True)
 raw=(Path(t)/"var/jb/Applications/DuoFaceUI.app/DuoFaceUI").read_bytes()
 m=MachO(select_arm64(raw))
 report={"status":"NATIVE19_UI_PREFERENCES_LAZY_OWNER_READONLY","sha256":hashlib.sha256(raw).hexdigest(),"sections":[{"name":s["name"],"vm":hex(s["vm"]),"size":s["size"]} for s in m.sections if s["name"] in ("__const","__cstring","__cfstring")],"probes":{}}
 cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
 for addr in (0x1000e8490,0x1000e8450,0x1000e84b0,0x10011ce10,0x10011ce18,0x10011ce28):
  try:
   off=m.map(addr)
   sample=m.data[off:off+72]
   report["probes"][hex(addr)]={"hex":sample.hex(),"ptr":hex(m.ptr(addr)),"ascii":m.cstr(addr)}
  except Exception as e:report["probes"][hex(addr)]={"error":str(e)}
 for entry in (0x1000109b4,0x1000106d8,0x100010b30):
  try:
   off=m.map(entry)
   report["probes"][hex(entry)]={"disasm":[hex(i.address)+": "+i.mnemonic+" "+i.op_str for i in cs.disasm(m.data[off:off+1024],entry)][:170]}
  except Exception as e:report["probes"][hex(entry)]={"error":str(e)}
 dest=Path("audit/payload-migration/NATIVE19_UI_OWNER_READONLY.json")
 dest.parent.mkdir(parents=True,exist_ok=True)
 dest.write_text(json.dumps(report,indent=2)+"\n")
 print(json.dumps(report,indent=2))
