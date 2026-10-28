#!/usr/bin/env python3
"""Original-only SHA-pinned OmniCar native app scene adoption selector-reference audit.

Reads real ARM64 ObjC selrefs within original method bounds; emits selectors
with exact instruction PCs (not vendor code). A selector use does NOT prove
the runtime took that branch or the view may safely be reparented in DuoFace.
"""
import argparse,hashlib,json,re,struct,subprocess,tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64,CS_MODE_ARM
from audit_omnicar_native_maps_dispatch_20261028 import SHA,arm64_fat,original_methods

SPLIT_SHA="f696b518579266cf99cfd46f85cb54931d18e679c793a563ee2fcc9bf8115754"
TARGETS=("isAdoptableViewController:","adoptViewController:","adopt:slot:",
 "sceneOfViewController:","scene:destroyedForViewController:ownScene:",
 "relayoutAnimated:pushScenes:","pushSceneSizes",
 "verifySceneOfPane:expected:retry:","soloBundle:","appAreaInParent:",
 "openApp:slot:","hostApp:inPane:","detachVC:background:")

def selref(binary,address):
 if not 0<=address<=len(binary)-8:return None
 ptr=struct.unpack_from("<Q",binary,address)[0]&((1<<48)-1)
 if not 0<ptr<len(binary):return None
 end=binary.find(b"\0",ptr,min(ptr+128,len(binary)))
 if end<=ptr:return None
 raw=binary[ptr:end]
 if not re.fullmatch(rb"[A-Za-z_$][A-Za-z0-9_:$]*",raw):return None
 return raw.decode("ascii")

def load_selector(binary,instructions,idx):
    # Find valid ADRP base and optional ADD to resolve actual `__objc_selrefs`
    # pointer. Restrict search to a small block since register state is dynamic.
    i=instructions[idx]
    if i.mnemonic!="ldr":return None
    m=re.fullmatch(r"(x\d+), \[(x\d+)(?:, #(0x[0-9a-f]+))?\]",i.op_str)
    if not m:return None
    destination,base,offset=m.groups()
    if destination!="x1":return None # ObjC selector register convention
    imm=int(offset,16) if offset else 0
    for j in range(idx-1,max(-1,idx-9),-1):
        prev=instructions[j]
        if prev.mnemonic=="adrp":
            x=re.fullmatch(r"(x\d+), #(0x[0-9a-f]+)",prev.op_str)
            if x and x.group(1)==base:
                address=int(x.group(2),16)+imm
                value=selref(binary,address)
                if value:return {"selector":value,"adrp_pc":hex(prev.address),
                                 "load_pc":hex(i.address),"selref_address":hex(address)}
            break
    return None

def stub_target_selector(binary,target,dis):
    # Modern iOS optimized ObjC calls use BL to a method-specific
    # __objc_stubs thunk, not ADRP/LDR(x1) inside the caller itself.
    if target<0 or target+16>len(binary):return None
    ops=list(dis.disasm(binary[target:target+32],target))
    pages={}
    for ins in ops[:8]:
        if ins.mnemonic=="adrp":
            m=re.fullmatch(r"(x\d+), #(0x[0-9a-f]+)",ins.op_str)
            if m:pages[m.group(1)]=int(m.group(2),16)
        if ins.mnemonic=="ldr":
            m=re.fullmatch(r"(x\d+), \[(x\d+)(?:, #(0x[0-9a-f]+))?\]",ins.op_str)
            if m and m.group(1)=="x1" and m.group(2) in pages:
                addr=pages[m.group(2)]+(int(m.group(3),16) if m.group(3) else 0)
                val=selref(binary,addr)
                if val:return {"selector":val,"stub":hex(target),
                                "selref_address":hex(addr)}
    return None

def analyze(original):
 if hashlib.sha256(original.read_bytes()).hexdigest()!=SHA:
    raise RuntimeError("original OmniCar DEB sha mismatch")
 with tempfile.TemporaryDirectory() as tmp:
    subprocess.run(["dpkg-deb","-x",str(original),tmp],check=True,
                   stdout=subprocess.DEVNULL)
    data=(Path(tmp)/"var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib").read_bytes()
    if hashlib.sha256(data).hexdigest()!=SPLIT_SHA:
       raise RuntimeError("original OmniCar split dylib sha mismatch")
    binary=arm64_fat(data)
    methods=original_methods(binary)
    pcs=sorted(set(methods.values()))
    dis=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    output={}
    for name in TARGETS:
        st=methods.get(("SCPCarSplit",name))
        if st is None:raise RuntimeError("Missing original method "+name)
        end=next((x for x in pcs if x>st),len(binary))
        if end<=st or end-st>65536:raise RuntimeError("Method size invalid "+name)
        ins=list(dis.disasm(binary[st:end],st))
        seen=[]
        for n,x in enumerate(ins):
            if x.mnemonic!="ldr":continue
            candidate=load_selector(binary,ins,n)
            if not candidate:continue
            # Keep only evidence of actual selector register loads. A
            # branch/indirect call may follow; runtime dispatch unproven.
            if not any(z["load_pc"]==candidate["load_pc"] for z in seen):
               seen.append(candidate)
        calls=[]
        for insn in ins:
            if insn.mnemonic!="bl":continue
            x=re.fullmatch(r"#(0x[0-9a-f]+)",insn.op_str)
            if not x:continue
            item=stub_target_selector(binary,int(x.group(1),16),dis)
            if item:calls.append({"call_pc":hex(insn.address),**item})
        output[name]={"imp":hex(st),"instruction_count":len(ins),
             "selector_loads":seen,"selector_count":len(seen),
             "resolved_objc_stub_calls":calls,"resolved_stub_count":len(calls),
             "matches_ui_host_controls":[x for x in seen if re.search(
               "addChild|willMove|didMove|removeFromParent|addSubview|"
               "insertSubview|sceneHostView|foregroundScene|backgroundScene|"
               "applicationInfo|sceneHandle|setFrame|layout|presentBase",
               x["selector"],re.I)]}
    return {"kind":"ORIGINAL_OMNICAR_NATIVE_ADOPT_ARM64_SELREF_AUDIT",
            "original_sha256":SHA,"split_dylib_sha256":SPLIT_SHA,
            "target_count":len(TARGETS),"methods":output,
            "limits":["Read-only original method selref addresses, no proprietary body port",
                "Pointer arithmetic/indirect objc_msgSend may use another register path",
                "Selector references are not proof of runtime branch, ownership or safe CPWindow reparent",
                "Cannot assert native map tiles or simultaneous Maps+phone pane from this scan"]}

def main():
 p=argparse.ArgumentParser()
 p.add_argument("--deb",type=Path,required=True)
 p.add_argument("--out",type=Path,required=True)
 args=p.parse_args()
 result=analyze(args.deb)
 args.out.parent.mkdir(parents=True,exist_ok=True)
 args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
 for method,value in result["methods"].items():
    print("OMNICAR_SELREF",method,value["imp"],value["selector_count"],
          "objc_stub_calls",value["resolved_stub_count"],
          ",".join(x["selector"] for x in value["resolved_objc_stub_calls"][:24]))
    if method in ("adopt:slot:","adoptViewController:","pushSceneSizes",
                  "detachVC:background:","scene:destroyedForViewController:ownScene:"):
        print("OMNICAR_OWNER_FULL_CHAIN",method," | ".join(
            x["call_pc"]+":"+x["selector"] for x in value["resolved_objc_stub_calls"]))
 print("OMNICAR_ORIGINAL_NATIVE_ADOPT_SELREF_AUDIT_PASS",result["target_count"])
if __name__=="__main__":main()
