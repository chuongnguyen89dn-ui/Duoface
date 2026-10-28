#!/usr/bin/env python3
"""Second independent ORIGINAL SidePlay SHA-pinned ARM64 callsite analysis.
LLVM's Mach-O ObjC relocs resolve selectors hidden from the fast Capstone index.
No vendor binary/code, no app runtime write, no license extraction.
"""
import argparse,hashlib,json,os,re,subprocess,tempfile
from pathlib import Path
RAW_SHA="7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c"
IMAGE_SHA="0fc34c6c8e47283d2223d70facfe3e86ed76bd568958786b67a9430127242971"
RANGES={
 "SPPane.orientationForBundleID_idiom":(0x307a0,0x308bc),
 "SPPane.applySceneFrame":(0x313f8,0x31468),
 "SPPane.restoreSceneFrame":(0x31468,0x31500),
 "SPPane.setSceneFrame_orientation":(0x31500,0x31710),
 "SPPane.sceneSettingsBlockInvoke":(0x31768,0x31830),
 "SPPane.loadedOrientationAndWatch":(0x32b68,0x32cb0),
 "SPPane.watchOrientationFor_token":(0x33ac8,0x33bd8),
 "SPPane.watchOrientationDispatchBlock":(0x33bd8,0x33d40),
 "SPPane.sceneViewOrientation":(0x34f70,0x35104)
}
INSTRUCTION=re.compile(r"^\s*(?:0x)?([0-9a-fA-F]+):\s+(.+)$")
NAME=re.compile(r"Objc selector ref:|Objc message:|Objc cfstring ref:|literal pool|symbol stub")
def sha(buf):return hashlib.sha256(buf).hexdigest()
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--sideplay",required=True,type=Path)
 p.add_argument("--out",required=True,type=Path)
 args=p.parse_args()
 if sha(args.sideplay.read_bytes())!=RAW_SHA:raise RuntimeError("SidePlay original DEB pin differs")
 with tempfile.TemporaryDirectory(prefix="duoface-sideplay-llvm-") as td:
  subprocess.run(["dpkg-deb","-x",str(args.sideplay),td],check=True)
  dylib=Path(td)/"var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib"
  raw=dylib.read_bytes()
  if sha(raw)!=IMAGE_SHA:raise RuntimeError("SidePlay original dylib SHA mismatch")
  # Avoid disassembling a default FAT arch with lookalike addresses.
  import sys
  sys.path.insert(0,os.environ["NATIVE_PARSER_DIR"])
  from audit_native12_license_class_xrefs import select_arm64
  thin=select_arm64(raw)
  single=Path(td)/"original-sideplay-arm64"
  single.write_bytes(thin)
  llvm=os.environ.get("OBJDUMP","llvm-objdump-18")
  command=[llvm,"--macho","--disassemble","--no-show-raw-insn",str(single)]
  ret=subprocess.run(command,text=True,capture_output=True,encoding="utf-8",errors="replace")
  if ret.returncode:raise RuntimeError("llvm-objdump failed: "+ret.stderr[-1400:])
  listing={}
  for line in ret.stdout.splitlines():
   match=INSTRUCTION.match(line)
   if match:listing[int(match[1],16)]=match[2].strip()
  if not listing:raise RuntimeError("No original SidePlay arm64 disassembly")
  report={"source":"original SidePlay 1.0.4-1, not DuoFace",
          "original_deb_sha256":RAW_SHA,"original_dylib_sha256":IMAGE_SHA,
          "thin_arm64_sha256":sha(thin),
          "evidence":"LLVM_MACHO_RESOLVED_SELECTOR_CALLS_STATIC_ONLY",
          "runtime_orientation_proven":False,"methods":{}}
  for name,(lo,hi) in RANGES.items():
   instructions=[{"pc":hex(pc),"asm":listing[pc]} for pc in sorted(listing)
                 if lo<=pc<hi]
   assert instructions and int(instructions[0]["pc"],16)==lo,(name,lo)
   report["methods"][name]={
       "first_pc":hex(lo),"last_exclusive":hex(hi),
       "instructions":instructions,
       "annotated_callsites":[x for x in instructions if NAME.search(x["asm"])],
       "precise_method_or_block_body_only":True
   }
   print("ORIGINAL_SIDEPANE",name,"ARM64",len(instructions),
         "refs",len(report["methods"][name]["annotated_callsites"]),flush=True)
 args.out.parent.mkdir(parents=True,exist_ok=True)
 args.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
 print("ORIGINAL_SIDEPANE_LLVM_ORIENTATION_CALLCHAIN_PASS",args.out)
if __name__=="__main__":main()
