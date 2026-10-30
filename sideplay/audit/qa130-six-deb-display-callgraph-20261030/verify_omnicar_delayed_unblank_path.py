#!/usr/bin/env python3
"""Independent exact ARM64/ObjC proof of OmniCar original delayed BKS unblank.

Consumes three SHA-pinned CI-generated read-only forensics JSON, never executes
vendor binary, never makes phone backlight or third-party app Play assertions.
"""
import argparse
import json
from pathlib import Path

ap=argparse.ArgumentParser()
for k in ("imports","methods","deep"):
    ap.add_argument("--"+k,required=True,type=Path)
ap.add_argument("--out",required=True,type=Path)
args=ap.parse_args()

im=json.loads(args.imports.read_text())
methods=json.loads(args.methods.read_text())
deep=json.loads(args.deep.read_text())
sha="d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd"
assert im["original_deb_sha256"]==methods["source_deb_sha256"]==deep["packages"]["OmniCar103"]["deb_sha256"]==sha
assert im["original_dylib_sha256"]==methods["source_dylib_sha256"]

def symbol(pc):
    stub=im["stub_imports"][pc]
    return (stub.get("pointer_binding") or stub.get("binding") or {}).get("name")
assert symbol("0x243e0")=="_MSHookFunction"
assert symbol("0x245f0")=="_dlsym"
assert symbol("0x245cc")=="_dispatch_time"
assert symbol("0x24548")=="_dispatch_after"
assert im["dispatch_queue_ref_at_0x34290_classic_import"]["name"]=="__dispatch_main_q"

names={x["class"]:x for x in methods["ABHost"]}
assert "ABHost" in names
host=names["ABHost"]
def method(entry,selector):
    found=[m for m in host[entry]["methods"] if m.get("selector")==selector]
    assert len(found)==1,(entry,selector,found)
    return found[0]
assert method("instance","count")["imp_vm"]=="0xaaa0"
assert method("class_methods","shared")["imp_vm"]=="0xa9e8"
assert method("instance","panes")["imp_vm"]=="0x16724"
assert methods["ABHost_count_accessor"]["selector"]=="panes"
check=[x for x in methods["focused_methods"] if x.get("class")=="ABHost" and x.get("selector")=="count"]
assert len(check)==1
assert "0xaaac bl #0x26580" in check[0]["instructions"]
assert "0xaabc bl #0x25420" in check[0]["instructions"]

block=methods["function_pointer_0x9688_block_candidate"]["possible_blocks"]
assert len(block)==1
block=block[0]
assert block["candidate_literal_base"]=="0x347d0"
assert block["qword2_invoke"]=="0x10000000009688"
assert block["isa_chained_import_candidate"]=="__NSConcreteGlobalBlock"
assert block["objc_block_flags_candidate"]=="0x50000000"
assert block["descriptor_reserved_size_qwords"]==["0x0","0x20"]
assert any(x["producer_pc"]=="0x77f0"
           for x in methods["block_literal_address_code_producers"]["0x347d0"])

callback=deep["packages"]["OmniCar103"]["replacement_callback"]["instructions"]
cb={x["pc"]:(x["mnemonic"],x["op"]) for x in callback}
expect={
"0x7790":("cmp","w0, #1"),"0x7794":("b.ne","#0x780c"),
"0x77b0":("bl","#0x25420"),"0x77c0":("cbz","x21, #0x780c"),
"0x77cc":("mov","w0, #1"),"0x77d0":("blr","x8"),
"0x77d4":("mov","x0, #0"),
"0x77d8":("mov","w1, #0xca00"),
"0x77dc":("movk","w1, #0x3b9a, lsl #16"),
"0x77e0":("bl","#0x245cc"),
"0x77f0":("add","x2, x2, #0x7d0"),
"0x77f4":("bl","#0x24548"),
"0x7814":("mov","x0, x19"),"0x7824":("br","x1")
}
for pc,item in expect.items():
    assert cb[pc]==item,(pc,cb.get(pc),item)
delay_ns=0xca00+(0x3b9a<<16)
assert delay_ns==1_000_000_000

unblank=deep["packages"]["OmniCar103"]["separate_unblank_original_caller"]["instructions"]
ub={x["pc"]:(x["mnemonic"],x["op"]) for x in unblank}
assert ub["0x968c"]==("ldr","x1, [x8, #0xa10]")
assert ub["0x9690"]==("mov","w0, #0")
assert ub["0x9694"]==("br","x1")

result={
 "result":"ORIGINAL_OMNICAR_BKS_BLANK1_DISPATCH_AFTER_1S_UNBLANK0_ARM64_STATIC_PROVEN",
 "source_deb_sha256":sha,
 "source_dylib_sha256":im["original_dylib_sha256"],
 "hook":"dlsym BKS then MSHookFunction; replacement PC 0x777c",
 "branch":"BKS blank==1 and ABHost.shared.count!=0 only",
 "count_owner":"ABHost -count at 0xaaa0 -> -panes then -count, and class +shared at 0xa9e8",
 "original_blank_call_pc":"0x77d0",
 "dispatch_time_pc":"0x77e0",
 "dispatch_after_pc":"0x77f4",
 "dispatch_delay_nanoseconds":delay_ns,
 "queue":"__dispatch_main_q",
 "global_dispatch_block_vm":"0x347d0",
 "global_block_invoke_vm":"0x9688",
 "global_block_import":"__NSConcreteGlobalBlock",
 "original_unblank0_tailcall_pc":"0x9694",
 "what_this_proves":"In original code, when screen blank=1 and bridged panes exist, original BKS(1) is called, then dispatch_after schedules a global block for +1s that tailcalls saved original BKS(0).",
 "what_it_does_not_prove":[
   "Main iPhone display brightness/glow or lock-state observed on user's device",
   "Whether this code causes or fixes YouTube/Gofa remote Play/touch",
   "Whether callbacks fire without a bridge pane or when CarPlay is disconnected",
   "Safe behavior if vendor runtime implementation were copied (do not copy)"
 ],
 "phone_test":False,"new_duoface_deb":False,"sileo_publish":False
}
args.out.parent.mkdir(parents=True,exist_ok=True)
args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
print(result["result"])
