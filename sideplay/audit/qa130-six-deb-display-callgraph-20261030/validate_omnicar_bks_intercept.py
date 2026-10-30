#!/usr/bin/env python3
"""Validate genuine pinned OmniCar ARM64 BKS interposition and 0/1 forwarding.

Requires the SHA-verified, CI-extracted DEEP_BKS_ARM64.json, not screenshots.
No binary execution, no firmware modification, no assumption that an iPhone
display was actually dim or that a YouTube button accepted touches.
"""
import argparse,json
from pathlib import Path
ap=argparse.ArgumentParser()
ap.add_argument("--input",required=True,type=Path)
ap.add_argument("--out",required=True,type=Path)
arg=ap.parse_args()
src=json.loads(arg.input.read_text())
om=src["packages"]["OmniCar103"]
assert om["deb_sha256"]=="d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd"
reg={x["pc"]:x for x in om["register_bks_dlsym_and_hook"]["instructions"]}
cb={x["pc"]:x for x in om["replacement_callback"]["instructions"]}
unblank={x["pc"]:x for x in om["separate_unblank_original_caller"]["instructions"]}
check={
"0x6f54":("add","x1, x1, #0x3ee"),
"0x6f5c":("bl","#0x245f0"),
"0x6f60":("cbz","x0, #0x6f94"),
"0x6f68":("add","x1, x1, #0x77c"),
"0x6f70":("add","x2, x2, #0xa10"),
"0x6f80":("b","#0x243e0")
}
for pc,(m,oper) in check.items():
 assert reg[pc]["mnemonic"]==m and reg[pc]["op"]==oper,(pc,reg[pc])
# Hook callback condition: requested blank==1 branches to separate control
# check, which MAY call original with 1 and do extra I/O.
checks={
"0x778c":("mov","x19, x0"),
"0x7790":("cmp","w0, #1"),
"0x7794":("b.ne","#0x780c"),
"0x77c0":("cbz","x21, #0x780c"),
"0x77c8":("ldr","x8, [x8, #0xa10]"),
"0x77cc":("mov","w0, #1"),
"0x77d0":("blr","x8"),
"0x7810":("ldr","x1, [x8, #0xa10]"),
"0x7814":("mov","x0, x19"),
"0x7824":("br","x1"),
}
for pc,(m,oper) in checks.items():
 assert cb[pc]["mnemonic"]==m and cb[pc]["op"]==oper,(pc,cb[pc])
# Second function path can explicitly invoke ORIGINAL with blank=0.
for pc,m,oper in [
("0x968c","ldr","x1, [x8, #0xa10]"),
("0x9690","mov","w0, #0"),
("0x9694","br","x1")]:
 assert unblank[pc]["mnemonic"]==m and unblank[pc]["op"]==oper
slot={x["pc"] for x in om["original_pointer_slot_users"]}
assert {"0x6f70","0x77c8","0x7810","0x968c"}.issubset(slot)
result={
 "omni_version":"1.0.3",
 "source_original_deb_sha256":om["deb_sha256"],
 "confirmed_static_direct_installation_path":"dlsym BKS -> replacement 0x777c -> output original pointer 0x3ea10 -> tail branch to hook installer stub 0x243e0",
 "hook_installer_import_identity":"not yet resolved from dyld bind symbols; calling convention consistent with three-argument hook",
 "replacement_when_blank_flag_not_1":"tailcalls original BKS with input flag unchanged; 0x7790/7794 and 0x7814/7824",
 "replacement_when_blank_flag_1":"conditionally invokes original BKS with 1 at 0x77cc/77d0 when secondary predicate at 0x77c0 allows; other cases forward original requested 1",
 "independent_original_unblank_path":"0x968c/0x9690/0x9694 calls original BKS with 0",
 "unknown":"upstream predicate meaning, timing, iOS backlight level/lock state, which car/phone app invokes these paths, and remote YouTube tap/Play receipt",
 "proof_source":"SHA-verified extracted original OmniCar AppBridge ARM64 instructions, not only string occurrences",
 "not_an_installed_phone_test":True,
 "not_a_duoface_fix":True
}
arg.out.parent.mkdir(parents=True,exist_ok=True)
arg.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
print("OMNICAR_ORIGINAL_BKS_HOOK_INTERCEPT_AND_SEPARATE_UNBLANK_ARM64_VERIFIED")
