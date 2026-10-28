#!/usr/bin/env python3
"""Read-only SHA-pinned original DEB versus actual signed DuoFace .83 orientation ABI."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import shutil

P=pathlib.Path
TARGETS={
 "duoface083":("ced5f42db8b9a3285ccf159386f25e8e5ea0fa976e14c3b35ea24dd625534c9b",("DFTouchOwnerProbe.dylib","DFCarPlayDockOwner.dylib")),
 "native12":("2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",("DuoFaceDashboard.dylib",)),
 "sideplay104":("7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c",("SidePlay.dylib",)),
 "duonavi104":("f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",("DuoNaviDashboard.dylib",)),
 "omnicar103":("d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd",("OmniCarAppBridge.dylib",)),
}
TOKENS=[
 "setInterfaceOrientation:",
 "interfaceOrientation",
 "setContentReferenceSize:withInterfaceOrientation:",
 "setContentReferenceSize:withContentOrientation:andContainerOrientation:",
 "_mainSceneSupportsInterfaceOrientation:",
 "supportsInterfaceOrientation:forBundleID:",
 "setSceneFrame:orientation:",
 "effectiveOrientation:",
 "updateSettingsWithBlock:",
 "setBridgeState:width:height:orientation:",
]
def sh(*args):
 return subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True).stdout
def sha(p):
 return hashlib.sha256(p.read_bytes()).hexdigest()
def select(root,basename):
 files=list(root.rglob(basename))
 if len(files)!=1:
  raise RuntimeError(f"{basename}: expected one, found {len(files)}")
 return files[0]
def scan_binary(path):
 raw=path.read_bytes()
 # The ObjC selector name itself is meaningful even in a stripped Mach-O.
 entries={}
 for token in TOKENS:
  positions=[m.start() for m in re.finditer(re.escape(token.encode()),raw)]
  entries[token]={"present":bool(positions),"occurrences":len(positions),
                  "first_byte_offsets":positions[:5]}
 return {"sha256":sha(path),"byte_size":len(raw),"selector_bytes":entries}
def audit(repo,inputs,out):
 results={"status":"EXACT_DEB_BYTES_SCANNED_STATIC_ONLY_NOT_DEVICE_PROOF",
   "source_commit":"2a6a92b38f559dcd1e20dccb0a5422b6db9afe2b",
   "inputs":{},"comparison":{},"limits":[]}
 for name,(expected,dl) in TARGETS.items():
  deb=P(getattr(inputs,name))
  observed=sha(deb)
  if observed!=expected:
   raise RuntimeError(f"{name} DEB hash mismatch expected {expected} got {observed}")
  payload=out/name
  payload.mkdir(parents=True,exist_ok=True)
  sh("dpkg-deb","-x",str(deb),str(payload))
  meta=sh("dpkg-deb","-f",str(deb),"Package","Version","Architecture").decode("utf8","replace")
  dylibs={}
  for dylib in dl:
   dll=select(payload,dylib)
   dylibs[dylib]=scan_binary(dll)
  # Also scan all actual .83 dylibs so a second injector is not overlooked.
  if name=="duoface083":
   for dll in sorted(payload.rglob("*.dylib")):
    dylibs.setdefault(dll.name,scan_binary(dll))
  results["inputs"][name]={"package_sha256":observed,"metadata":meta.strip(),
                             "dylibs":dylibs}
 cur=results["inputs"]["duoface083"]["dylibs"]["DFTouchOwnerProbe.dylib"]["selector_bytes"]
 native=results["inputs"]["native12"]["dylibs"]["DuoFaceDashboard.dylib"]["selector_bytes"]
 omni=results["inputs"]["omnicar103"]["dylibs"]["OmniCarAppBridge.dylib"]["selector_bytes"]
 side=results["inputs"]["sideplay104"]["dylibs"]["SidePlay.dylib"]["selector_bytes"]
 original=results["inputs"]["duonavi104"]["dylibs"]["DuoNaviDashboard.dylib"]["selector_bytes"]
 results["comparison"]={
  "duoface083_current_owned_scene_setInterfaceOrientation_selector":cur["setInterfaceOrientation:"]["present"],
  "duoface083_current_all_dylibs_with_setInterfaceOrientation_selector":[
    k for k,v in results["inputs"]["duoface083"]["dylibs"].items()
    if v["selector_bytes"]["setInterfaceOrientation:"]["present"]],
  "native12_original_orientation_support_hook":native["_mainSceneSupportsInterfaceOrientation:"]["present"],
  "native12_original_content_reference_2_and_3":
     native["setContentReferenceSize:withInterfaceOrientation:"]["present"] and
     native["setContentReferenceSize:withContentOrientation:andContainerOrientation:"]["present"],
  "omnicar_original_scene_orientation_setter":omni["setInterfaceOrientation:"]["present"],
  "sideplay_original_frame_and_orientation_selector":side["setSceneFrame:orientation:"]["present"],
  "duonavi_original_two_reference_selectors":
     original["setContentReferenceSize:withInterfaceOrientation:"]["present"] and
     original["setContentReferenceSize:withContentOrientation:andContainerOrientation:"]["present"],
 }
 # Static ARM64 direct replacement IMPs for orientation-related Native12 hooks.
 # Address ranges are from the verified MSHookMessageEx registration in
 # sideplay/audit/native12-082-transaction-20261028/TRANSACTION_ARM64.json.
 tool=shutil.which("llvm-objdump")
 ranges={
   "native12_content_reference_2arg":("0x2c895c","0x2c8a50"),
   "native12_content_reference_3arg":("0x2c8a50","0x2c8b4c"),
   "native12_mainSceneSupportsInterfaceOrientation":("0x2c8b4c","0x2c8ca8"),
 }
 hook_disassembly={}
 for label,(start,stop) in ranges.items():
  if tool:
   cmd=[tool,"--macho","--arch=arm64","--disassemble",
        "--start-address="+start,"--stop-address="+stop,
        str(select(out/"native12","DuoFaceDashboard.dylib"))]
   done=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
   lines=done.stdout.decode("utf8","replace").splitlines()
   # LLVM Mach-O ignores --start-address in some versions and begins
   # at 0x10000. Filter again by parsed address to prevent unrelated
   # original code/assets from entering the audit report.
   low,high=int(start,16),int(stop,16)
   code=[]
   for line in lines:
    match=re.match(r"^\s*(?:0x)?([0-9a-fA-F]+):\s",line)
    if match and low<=int(match.group(1),16)<high:
     code.append(line.strip())
   hook_disassembly[label]={"status":"PASS" if done.returncode==0 and code else "EMPTY",
                            "start":start,"stop":stop,"instructions":code[:180],
                            "error":done.stderr.decode("utf8","replace")[:300]}
  else:
   hook_disassembly[label]={"status":"LLVM_OBJDUMP_UNAVAILABLE","instructions":[]}
 results["orientation_hook_arm64"]=hook_disassembly
 print("EXACT_ORIGINAL_HOOK_ARM64",
       json.dumps({k:[v["status"],len(v["instructions"])] for k,v in hook_disassembly.items()}))
 # Compare method-proven ARM64 original with source of exact .83 build,
 # not merely strings that could belong to dead code or comments.
 source=(repo/"sideplay/duoface-native-scene-host/DFSceneHost.m").read_text()
 chrome=(repo/"sideplay/duoface-native-scene-host/DFNative12Chrome.m").read_text()
 lifecycle=(repo/"sideplay/duoface-native-scene-host/DFSceneLifecycle.m").read_text()
 results["comparison"]["duoface083_source"]={
  "host_setInterfaceOrientation":'NSSelectorFromString(@"setInterfaceOrientation:")' in source,
  "host_explicit_size_2x":'round(size.width*2)' in source,
  "host_content_reference_portrait":'UIInterfaceOrientationPortrait' in source,
  "host_scene_frame_setter":'NSSelectorFromString(@"setFrame:")' in source,
  "chrome_pane_focus_change":'self.focus=(self.focus==slot)?-1:slot;' in chrome,
  "chrome_host_zoom_change":'applyHostFullscreenToScreenBoundsAfterDockAck:' in chrome,
  "scope_manual_observer_preserved":'DFIsOwnedManualSceneObserver' in lifecycle,
 }
 results["limits"]=[
  "Selector bytes in exact binaries prove symbols/strings, not that runtime executes branch.",
  "Native12 original reference orientation Portrait=1 differs from external CarPlay screen orientation.",
  "Without iPhone video/scene logs cannot distinguish 90 vs 180, app-own player fullscreen vs pane/host Zoom.",
  "Do not alter .83 scoped SpringBoard crash fix, Dock, or content reference policy based only on string diff.",
  "DuoDash repack has preserved ARM64 selector evidence but is not falsely labeled stock or used as input here.",
 ]
 assert results["comparison"]["duoface083_source"]["scope_manual_observer_preserved"]
 report=out/"BINARY_DIRECT_083_VS_ORIGINAL.json"
 report.write_text(json.dumps(results,ensure_ascii=False,indent=2)+"\n")
 print("DIRECT_BINARY_AUDIT_VERIFIED_DEB_SHA_COUNT",len(TARGETS))
 print("DIRECT_BINARY_ORIENTATION_COMPARISON",json.dumps(results["comparison"],ensure_ascii=False))
 print("DIRECT_BINARY_REPORT",report)
def main():
 a=argparse.ArgumentParser()
 for name in TARGETS:a.add_argument("--"+name,required=True)
 a.add_argument("--repo",default=".")
 a.add_argument("--out",required=True)
 args=a.parse_args()
 repo=P(args.repo).resolve();out=P(args.out).resolve()
 out.mkdir(parents=True,exist_ok=True)
 audit(repo,args,out)
if __name__=="__main__":main()
