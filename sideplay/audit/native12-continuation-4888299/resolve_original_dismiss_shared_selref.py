#!/usr/bin/env python3
"""Resolve ONE shared ORIGINAL Native12 dismiss selector ref by source Mach-O VM bytes.

Both 0xaf0fc (appController.view) and 0xaf1a4 (a second bridge-owned
view/ivar) use the SAME x22 + #0xb28 ref. Disassembler's two different
automatic ObjC annotations must not be treated as separate verified selectors.
"""
import argparse,hashlib,json,pathlib,runpy,re
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[2]
DASH_SHA="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
ORIGINAL_DEB_SHA="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
SELREF=0x37d000+0xb28
def main():
  a=argparse.ArgumentParser()
  a.add_argument("--binary",required=True,type=pathlib.Path)
  a.add_argument("--out",required=True,type=pathlib.Path)
  args=a.parse_args()
  binary=args.binary
  sha=hashlib.sha256(binary.read_bytes()).hexdigest()
  if sha!=DASH_SHA:raise ValueError("Wrong ORIGINAL Native12 Mach-O SHA")
  prior=json.loads((HERE/"gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json").read_text())
  method=next(m for m in prior["methods"] if m["class"]=="CBBridgedUIAppView" and m["selector"]=="dismiss" and m["imp"]=="0xaf01c")
  lines={int(z.split(":",1)[0],16):z for z in method["instructions"]}
  expected={0xaf064:"adrp\tx22, 718 ; 0x37d000",
            0xaf0f8:"ldr\tx1, [x22, #0xb28]",
            0xaf1a0:"ldr\tx1, [x22, #0xb28]"}
  for pc,part in expected.items():
    if part not in lines.get(pc,""):
      raise ValueError("Original disassembly mismatch "+hex(pc))
  parser=runpy.run_path(str(ROOT/"tools/native12_objc_stub_decoder.py"))
  sections,read_va=parser["sections_for_binary"](binary)
  raw=read_va(SELREF,8)
  if not raw or len(raw)!=8:raise ValueError("Missing original selector reference bytes")
  tagged=int.from_bytes(raw,"little")
  name_pc=tagged & ((1<<48)-1)
  txt=None
  for n in (128,64,32,16,8):
    txt=read_va(name_pc,n)
    if txt:break
  if not txt:raise ValueError("Selector string address not mapped: "+hex(name_pc))
  name=txt.split(b"\0",1)[0].decode("utf-8","strict")
  if not re.fullmatch(r"[\x20-\x7e]{1,128}",name):raise ValueError("Unverified non-ASCII selref")
  out={"original_native12_deb_sha256":ORIGINAL_DEB_SHA,
       "dashboard_macho_sha256":sha,"source_class":"CBBridgedUIAppView",
       "source_method":"dismiss","source_imp":"0xaf01c",
       "adrp_pc":"0xaf064","callsite_pcs":["0xaf0f8","0xaf1a0"],
       "shared_selref_vm":hex(SELREF),"raw_pointer_hex":raw.hex(),
       "selector_name_vm":hex(name_pc),"exact_selector":name,
       "receiver_at_first_call":"appController.view",
       "receiver_at_second_call":"second-original-bridge-ivar-unresolved",
       "runtime_receiver_equivalence_proven":False,
       "vendor_binary_included":False,"device_verified":False}
  args.out.mkdir(parents=True,exist_ok=True)
  path=args.out/"ORIGINAL_DISMISS_SHARED_SELECTOR.json"
  path.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
  print("ORIGINAL_NATIVE12_DISMISS_SHARED_SELECTOR_SOURCE_VERIFIED",name,hex(SELREF))
if __name__=="__main__":main()
