#!/usr/bin/env python3
"""Decode original CarPlayPro Speed 0.9.97 GOFA event names from Mach-O literals.

Original ARM64 at 0x3ce1c iterates __objc_arrayobj at 0x64568 and registers
NSNotificationCenter observers using ObjC stub 0x440a0 (proven
addObserverForName:object:queue:usingBlock:). Another registration uses the
CFString at 0x63968. This only recovers literal *names*, not GOFA event
payload data, ABI, producer status or CarPlay warnings on device.
"""
from __future__ import annotations
import argparse,json
from pathlib import Path
from resolve_carplaypro_hook_sources import ThinMachO

ORIGINAL_ARRAY=0x64568
ADDITIONAL_CFSTRING=0x63968

def decode(macho):
    words=[macho.pointer(ORIGINAL_ARRAY+i*8) for i in range(3)]
    out={"original_objc_array_object_address":hex(ORIGINAL_ARRAY),
         "array_raw_words":[hex(x) if x is not None else None for x in words],
         "static_additional_notification_cfstring_address":hex(ADDITIONAL_CFSTRING),
         "static_additional_notification":macho.cfstring(ADDITIONAL_CFSTRING),
         "array_members":[],"source":"original on-disk arm64 SpeedAlerts.dylib",
         "live_goFA_event_verified":False}
    # Apple __objc_arrayobj has an ISA word, count and authenticated pointer
    # into the __objc_arraydata constant pool on this original Mach-O.
    count=words[1]
    data_ptr=words[2]
    if count is not None and data_ptr is not None:
        candidate=data_ptr & 0xffffffff
        sec=macho.section(candidate)
        if 0<count<=32 and sec and sec["section"]=="__objc_arraydata":
            for i in range(count):
                word=macho.pointer(candidate+8*i)
                if word is None:continue
                element=word & 0xffffffff
                out["array_members"].append({
                    "index":i,"word_address":hex(candidate+8*i),
                    "raw_pointer":hex(word),"decoded_object_address":hex(element),
                    "cfstring":macho.cfstring(element),
                    "direct_cstring":macho.text(element)})
        out["candidate_element_count"]=count
        out["candidate_arraydata_pointer"]=hex(candidate)
    return out

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--thin",required=True,type=Path)
    p.add_argument("--loads",required=True,type=Path)
    p.add_argument("--out",required=True,type=Path)
    a=p.parse_args()
    obj=decode(ThinMachO(a.thin.read_bytes(),json.loads(a.loads.read_text())))
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"ORIGINAL_GOFA_NOTIFICATION_NAMES.json").write_text(json.dumps(obj,indent=2)+"\n")
    lines=["# Original GOFA source event notification names — byte-accurate static trace",
      "","Original function 0x3ce1c registers observers with the",
      "**proven** `addObserverForName:object:queue:usingBlock:` selector,",
      "using array object 0x64568 and fixed CFString at 0x63968.",
      "The original callback block target addresses 0x3cfb4 (alert) and",
      "0x3d468 (speed) were verified from chained-fixup bytes.",
      "This does NOT determine the event payload schema or confirm device delivery.",
      "",
      "## Decoded static array",
      f"- array words: `{obj['array_raw_words']}`",
      f"- candidate count: `{obj.get('candidate_element_count')}`",
      f"- candidate element-pointer array: `{obj.get('candidate_arraydata_pointer')}`"]
    for entry in obj["array_members"]:
        value=(entry.get("cfstring") or {}).get("text") or entry.get("direct_cstring")
        lines.append("- member "+str(entry["index"])+": `"+str(value)+"` at `"+entry["decoded_object_address"]+"`")
    lines+=["","## Separate original Speed notification subscription"]
    lines.append("- `0x63968`: `"+str((obj["static_additional_notification"] or {}).get("text"))+"`")
    lines+=["","## Functionality boundary",
      "The original app may generate these notifications only while GOFA/route",
      "is active. Neither a logged string nor an original notification means",
      "DuoFace has live traffic alerts, camera distances, or next-turn instructions."]
    (a.out/"ORIGINAL_GOFA_NOTIFICATION_NAMES.md").write_text("\n".join(lines)+"\n")
    print("QA166_ORIGINAL_NOTIFICATION_ARRAY_EXTRACTED",len(obj["array_members"]))
if __name__=="__main__":
    main()
