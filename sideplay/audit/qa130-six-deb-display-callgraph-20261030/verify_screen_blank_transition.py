#!/usr/bin/env python3
"""Read-only deterministic test of SIX actually extracted, SHA-pinned DEB results.

Keep 'binary API called' distinct from a live iPhone backlight result and
from the touch/Play application's activation status.
"""
import argparse
import json
from pathlib import Path

a=argparse.ArgumentParser()
a.add_argument("--evidence",type=Path,required=True)
a.add_argument("--output",type=Path,required=True)
v=a.parse_args()
j=json.loads(v.evidence.read_text())
rows=j["scans"]
assert len(rows)==6
want={
"Native12Derived":"2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
"DuoNavi104":"f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
"OmniCar103":"d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd",
"SidePlay104":"7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c",
"DuoDash113Repack":"ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465",
"DuoFaceQA130":"d0573ac14e402dfca450e4b01fd57f898ed03852b354361b0a8acf54a432e24b",
}
for name,pin in want.items():
    assert rows[name]["package_sha256"]==pin,name
def bin_with(name,marker):
    return [x for x in rows[name]["macho"] if marker in x.get("marker_locations",{})]
def sample(name,pc):
    for f in rows[name]["macho"]:
        for site in f.get("literal_callsite_samples",[]):
            if site["pc"]==pc and site.get("marker")=="BKSDisplayServicesSetScreenBlanked":
                return site
    raise AssertionError(name+" missing literal-site "+pc)
def is_calling(site,zero):
    s="\n".join(site["near"])
    assert "BKS" not in s   # binary disassembly, not added notes
    assert f"mov w0, #{zero}" in s,site["pc"]
    assert "blr x8" in s or "br x1" in s,site["pc"]
    return {"at":site["pc"],"symbol_resolved_near":site["marker"],
            "constant_arg":zero,"indirect_branch_observed":True}
result={"status":"static real MachO bounded ARM64 callsite test PASS; NO live scene or display event validated",
        "sha_pinned_six_packages":True,
        "api_presence":{k:bool(bin_with(k,"BKSDisplayServicesSetScreenBlanked")) for k in want},
        "calls":{},
        "phone_glow_or_play_cause":"not established from binary alone",
        "qa130_changes":False}
assert all(result["api_presence"][x] for x in want if x!="DuoFaceQA130")
assert not result["api_presence"]["DuoFaceQA130"]
assert len(bin_with("Native12Derived","setScreenBlankEnabled:"))>=1
assert len(bin_with("DuoNavi104","setScreenBlankEnabled:"))>=1
result["calls"]["Native12Derived"]=[
    is_calling(sample("Native12Derived","0x31af0"),"1"),
    is_calling(sample("Native12Derived","0x31da8"),"0")]
result["calls"]["DuoNavi104"]=[
    is_calling(sample("DuoNavi104","0xae32c"),"0"),
    is_calling(sample("DuoNavi104","0x16169c"),"0"),
    is_calling(sample("DuoNavi104","0x1bf0d0"),"0")]
# In the Omni and repacked DuoDash cases direct references are confirmed,
# but the scan cannot yet prove the whole function/return and call invocation.
result["calls"]["OmniCar103"]={"bks_literal_seen_at":"0x6f54","dynamic_lookup":True,
    "call_after_lookup_confirmed":False}
result["calls"]["DuoDash113Repack"]={"bks_literal_seen_at":["0x24e74","0x52808"],
    "stock_original_identity":False,"call_after_lookup_confirmed":False}
result["calls"]["SidePlay104"]={"bks_literal_in_signed_binary":True,
    "direct_adrp_add_reference_found":False}
result["calls"]["DuoFaceQA130"]={"bks_literal_in_signed_binary":False,
    "system_idle_assertion_present":True,"display_blank_toggling_implemented":False}
v.output.parent.mkdir(parents=True,exist_ok=True)
v.output.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
print("SIX_ORIGINAL_MACHO_BKS_STATIC_ZERO_ONE_XREF_VERIFIED_NO_DEVICE_CAUSE")
