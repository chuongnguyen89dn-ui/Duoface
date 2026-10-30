#!/usr/bin/env python3
"""DuoNavi1.0.4 original dynamic BKS1 -> GCD -> callback BKS0 trace.

Real signed SHA-pinned original DEB; read-only. This is *not* a live device
trace and contains no vendor implementation copied to independent runtime.
"""
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path
from audit_native12_license_class_xrefs import MachO,select_arm64
from resolve_omnicar_bks_imports_and_callbacks import imports,stub_import
from audit_native12_duonavi_screenblank_preferences import block
PIN="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
REL="var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib"
STUBS=(0x3135c4,0x3135d0,0x3135dc,0x313780,0x3137b0,0x3137e0,0x3137bc,0x313798)
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--deb",required=True,type=Path)
 p.add_argument("--out",required=True,type=Path)
 a=p.parse_args()
 data=a.deb.read_bytes()
 digest=hashlib.sha256(data).hexdigest()
 if digest!=PIN:raise RuntimeError("DuoNavi original 1.0.4 DEB SHA invalid "+digest)
 with tempfile.TemporaryDirectory() as tmp:
  subprocess.run(["dpkg-deb","-x",str(a.deb),tmp],check=True)
  raw=(Path(tmp)/REL).read_bytes()
  m=MachO(select_arm64(raw))
  imp=imports(m.data)
  results={
    "original_deb_sha256":digest,
    "original_dylib_sha256":hashlib.sha256(raw).hexdigest(),
    "instrumented_on_phone":False,
    "code_executed_on_device":False,
    "import_symbols":{hex(vm):stub_import(m,imp["bindings"],vm) for vm in STUBS},
    "bks_blank1_original_conditional":{
      "source_symbol_resolver":"0x192e68..0x192e80",
      "caller":"0x192ec0 mov w0,#1; 0x192ec4 blr x22",
      "context":block(m,0x192ec0,0x94,0xec)},
    "possible_delayed_block":{
      "context":block(m,0x192ef4,0x2c,0x7c),
      "callback_candidate":"0x1a636c",
      "callback_instructions":block(m,0x1a636c,0,0x110),
      "original_unblank_neighbor_0x1a63b0":block(m,0x1a63b0,0,0x54)
    },
    "known_other_unblank_sites":{
      hex(vm):block(m,vm,0x1c,0x30)
      for vm in (0xae33c,0x1616ac,0x1bf0e0)},
    "note":"Static branch and imports; conditional event/time/controller and physical screen dim are NOT proven until complete CFG and user test."
  }
  a.out.parent.mkdir(parents=True,exist_ok=True)
  a.out.write_text(json.dumps(results,ensure_ascii=False,indent=2)+"\n")
  print("DUONAVI_DEB_SHA256_PASS",digest)
  for pc,x in results["import_symbols"].items():
   k=x.get("pointer_binding") or x.get("binding") or {}
   print("DUONAVI_FUNCTION_IMPORT",pc,k.get("name"))
  print("DUONAVI_NATIVE_BKS1_CALLBACK_ARM64_READ_ONLY")
if __name__=="__main__":main()
