#!/usr/bin/env python3
"""Independent static provenance gate: two original screen-blank configurations.

Checks original ARM64 instruction addresses against SHA-verifiable binary
forensic outputs. This is not a live phone/runtime or UI acceptance test.
"""
import argparse,json
from pathlib import Path

p=argparse.ArgumentParser()
for name in ("prefs","duonavi"):
 p.add_argument("--"+name,required=True,type=Path)
p.add_argument("--out",required=True,type=Path)
a=p.parse_args()
prefs=json.loads(a.prefs.read_text())
duo=json.loads(a.duonavi.read_text())

assert prefs["packages"]["Native12Derived"]["package_sha256"]=="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
assert prefs["packages"]["DuoNavi104"]["package_sha256"]==duo["original_deb_sha256"]=="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
assert duo["original_dylib_sha256"]=="44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"

def dashboard(name):
 files=prefs["packages"][name]["machos_with_screenblank_method"]
 hits=[f for f in files if f["file"].endswith("Dashboard.dylib")]
 assert len(hits)==1,(name,len(hits))
 return hits[0]
def instructions(method):
 return {q["pc"]:(q["mnemonic"],q["op"]) for q in method["first_100_instructions"]}
def method(d,clazz,name):
 hits=[x for x in d["dashboard_settings_init_and_reload"][clazz] if x["selector"]==name]
 assert len(hits)==1
 return hits[0]
def assertlines(actual,expected):
 for addr,expected_ins in expected.items():
  assert actual.get(addr)==expected_ins,(addr,expected_ins,actual.get(addr))

native=dashboard("Native12Derived")
duod=dashboard("DuoNavi104")
ninit=instructions(method(native,"CBDashboardSettings","init"))
dinit=instructions(method(duod,"CBDashboardSettings","init"))
nget=instructions(method(native,"CBDashboardSettings","screenBlankEnabled"))
dget=instructions(method(duod,"CBDashboardSettings","screenBlankEnabled"))
assertlines(ninit,{"0x360e0":("mov","w8, #0x100"),"0x360e8":("str","w8, [x19, #8]")})
assertlines(dinit,{"0x2d574":("mov","w20, #0x100"),"0x2d578":("strh","w20, [x19, #8]")})
assertlines(nget,{"0x37ec0":("ldrb","w0, [x0, #9]")})
assertlines(dget,{"0x2f48c":("ldrb","w0, [x0, #9]")})
# In little-endian, writing 0x0100 to offset+8 sets byte +9 to 0x01.
# This establishes constructor initialized value, *not persisted preference state*.

nsites={x["site"]:{z["pc"]:(z["mnemonic"],z["op"]) for z in x["bounded_instructions"]} for x in native["bks_literal_sites"]}
assertlines(nsites["0x31af0"],{"0x31b04":("mov","w0, #1"),"0x31b08":("blr","x8")})
assertlines(nsites["0x31da8"],{"0x31dbc":("mov","w0, #0"),"0x31dc0":("blr","x8")})
dsites={x["site"]:{z["pc"]:(z["mnemonic"],z["op"]) for z in x["bounded_instructions"]} for x in duod["bks_literal_sites"]}
assertlines(dsites["0x1bf0d0"],{"0x1bf0e0":("mov","w0, #0"),"0x1bf0e4":("blr","x8")})
def checkimp(key,expected):
 k=duo["import_symbols"][key]
 assert (k.get("pointer_binding") or k.get("binding"))["name"]==expected,key
checkimp("0x31354c","_dispatch_after")
checkimp("0x3135c4","_dispatch_time")
checkimp("0x3135d0","_dlopen")
checkimp("0x3135dc","_dlsym")
assert duo["callback_guard_selector"]["literal"]=="isUIAppBridging"
assert duo["dispatch_queue_got_0x370168"]["name"]=="__dispatch_main_q"
# Use actual native code fields, not inferred screen glow.
code={z["pc"]:(z["mnemonic"],z["op"]) for z in duo["bks_blank1_original_conditional"]["context"]}
allafter=duo["possible_delayed_block"]["conditional_other_branch_0x192f30"]
second={z["pc"]:(z["mnemonic"],z["op"]) for z in allafter}
assertlines(code,{"0x192ec0":("mov","w0, #1"),"0x192ec4":("blr","x22"),
                 "0x192ecc":("mov","w1, #0x6500"),
                 "0x192ed0":("movk","w1, #0x1dcd, lsl #16"),
                 "0x192ed4":("bl","#0x3135c4"),
                 "0x192ef4":("adr","x8, #0x1a636c"),
                 "0x192f20":("bl","#0x31354c")})
assertlines(second,{"0x192f30":("mov","w0, #0"),"0x192f34":("blr","x22"),
                 "0x192f3c":("mov","w1, #0xa300"),
                 "0x192f40":("movk","w1, #0x11e1, lsl #16"),
                 "0x192f44":("bl","#0x3135c4"),
                 "0x192f68":("adr","x8, #0x1a63b0"),
                 "0x192f90":("bl","#0x31354c"),
                 "0x192fa0":("mov","w1, #0x800"),
                 "0x192fa4":("movk","w1, #0x2faf, lsl #16"),
                 "0x192fa8":("bl","#0x3135c4"),
                 "0x192fc0":("adr","x8, #0x1a6400"),
                 "0x192fe0":("bl","#0x31354c")})
first={z["pc"]:(z["mnemonic"],z["op"]) for z in duo["possible_delayed_block"]["callback_instructions"]}
assertlines(first,{"0x1a6388":("bl","#0x313780"),
                  "0x1a638c":("cbz","w0, #0x1a63a4"),
                  "0x1a6394":("mov","w0, #0"),
                  "0x1a63a0":("br","x1"),
                  "0x1a63ec":("mov","w0, #0"),
                  "0x1a63f4":("br","x1"),
                  "0x1a643c":("mov","w0, #0"),
                  "0x1a6444":("br","x1")})
delays={
 "0x192ed0/0x192ed4":0x1dcd6500,
 "0x192f40/0x192f44":0x11e1a300,
 "0x192fa4/0x192fa8":0x2faf0800
}
assert list(delays.values())==[500000000,300000000,800000000]
result={
 "status":"NATIVE12_DUONAVI_ORIGINAL_BKS_INITIAL_TRUE_AND_GATED_UNBLANK_TIMERS_STATIC_PASS",
 "native12_ref_package_sha":prefs["packages"]["Native12Derived"]["package_sha256"],
 "duonavi_original_package_sha":duo["original_deb_sha256"],
 "initial_screenBlankEnabled":True,
 "native12_constructor_proof":"0x360e0/0x360e8 writes 0x100 at instance+8, getter 0x37ec0 reads +9",
 "duonavi_constructor_proof":"0x2d574/0x2d578 writes 0x100 at instance+8, getter 0x2f48c reads +9",
 "user_persisted_preference_default_proven":False,
 "native12_bks":["BKS(1) 0x31b08","BKS(0) 0x31dc0"],
 "duonavi_scheduled_delay_ns":{"BKS1_branch":500000000,"BKS0_or_after_branch":300000000,"additional_common":800000000},
 "duonavi_callbacks":[hex(x) for x in (0x1a636c,0x1a63b0,0x1a6400)],
 "duonavi_conditional_selector":"isUIAppBridging",
 "duonavi_deactivation_bks0_pc":"0x1bf0e4",
 "no_live_carplay":True,"no_sileo_build_or_deploy":True
}
a.out.parent.mkdir(parents=True,exist_ok=True)
a.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
print(result["status"])
