#!/usr/bin/env python3
"""Evidence-only recovery of CarPlayPro Speed 0.9.97 Objective-C hook targets.

Addresses/selector strings are obtained from original *thin* ARM64 Mach-O bytes
and the independently pinned full-disassembly artifact. No vendor executable
is run or copied into DuoFace. No guessed GOFA field signatures.
"""
from __future__ import annotations
import argparse, bisect, collections, gzip, json, re, struct
from pathlib import Path

ASMLINE=re.compile(r"^([0-9a-f]{16})\t[0-9a-f]{8}\t([^\t]+)\t(.*)$")
PAGE=re.compile(r"^x(\d+), #0x([0-9a-f]+)$")
ADDI=re.compile(r"^x(\d+), x(\d+), #0x([0-9a-f]+)$")
LDR=re.compile(r"^x(\d+), \[x(\d+), #0x([0-9a-f]+)\]$")
BL=re.compile(r"^#0x([0-9a-f]+)$")
# These exact import stub addresses are verified by original Apple otool -Iv.
IMPORTS={"_MSHookMessageEx":0x43628,"_MSHookFunction":0x4361c,
         "_objc_getClass":0x43a18,"_NSClassFromString":0x43634,
         "_NSSelectorFromString":0x43658}
INTERESTING=("gofa","gofa.","GOFA","board","Board","alert","Alert",
             "notification","flutter","Flutter","Speed","Datapoint",
             "camera","Camera","next","Next","direction","Direction")
CALLBACKS=(0x3cfb4,0x3d468,0x3e38c,0x3e93c)

class ThinMachO:
    def __init__(self, data:bytes, loads:dict):
        if data[:4]!=b"\xcf\xfa\xed\xfe":raise ValueError("only original thin ARM64 MachO")
        self.data=data
        self.sections=loads["sections"]
    def section(self,addr):
        for s in self.sections:
            if s["offset"]>=0 and s["addr"]<=addr<s["addr"]+s["size"]:
                return s
        return None
    def raw(self,addr,n):
        sec=self.section(addr)
        if sec is None or addr+n>sec["addr"]+sec["size"]:
            return None
        start=sec["offset"]+addr-sec["addr"]
        if start+n>len(self.data):return None
        return self.data[start:start+n]
    def pointer(self,addr):
        raw=self.raw(addr,8)
        return struct.unpack("<Q",raw)[0] if raw else None
    def text(self,addr,maxlen=145):
        sec=self.section(addr)
        if sec is None or sec["section"] not in ("__cstring","__objc_methname",
                                                  "__objc_classname","__swift5_typeref"):
            return None
        begin=sec["offset"]+addr-sec["addr"]
        end=min(begin+maxlen,sec["offset"]+sec["size"])
        raw=self.data[begin:end].split(b"\0",1)[0]
        try:
            value=raw.decode("utf-8")
        except UnicodeDecodeError:return None
        if not value or any(ord(c)<32 for c in value):return None
        return value
    def cfstring(self,addr):
        sec=self.section(addr)
        if not sec or sec["section"]!="__cfstring":return None
        raw=self.raw(addr,32)
        if not raw:return None
        target=struct.unpack_from("<Q",raw,16)[0]
        # Accept chained-fixup low address only when it resolves to cstring.
        value=self.text(target)
        if value is None:
            target=target & 0xffffffff
            if self.section(target) and self.section(target)["section"]=="__cstring":
                value=self.text(target)
        return {"cfstring_at":hex(addr),"target":hex(target),"text":value}
    def class_or_string(self,addr):
        return self.text(addr) or (self.cfstring(addr) or {}).get("text")
    def selref(self,addr):
        sec=self.section(addr)
        if not sec or sec["section"]!="__objc_selrefs":return None
        p=self.pointer(addr)
        if p is None:return None
        # Chained/authenticated pointers may not store plain VM addresses.
        name=self.text(p)
        decoded=p
        # Original arm64 Mach-O has authenticated chained pointer fixups.
        # Resolve low bits only if they land in tracked __objc_methname.
        if name is None:
            candidate=p & 0xffffffff
            sec=self.section(candidate)
            if sec and sec["section"]=="__objc_methname":
                name=self.text(candidate)
                decoded=candidate
        return {"at":hex(addr),"ptr":hex(p),
                "decoded_name_address":hex(decoded) if name else None,
                "name":name}

def rows_from_asm(src,starts):
    starts=sorted(set(starts))
    rows=[]
    for raw in src.splitlines():
        m=ASMLINE.match(raw)
        if not m:continue
        pc=int(m[1],16)
        i=bisect.bisect_right(starts,pc)-1
        rows.append({"addr":pc,"start":starts[i] if i>=0 else None,
                     "op":m[2],"arg":m[3],"line":raw})
    return rows

def reg_address(records,upto,reg,window=16):
    """Conservative nearby ADRP+(ADD/LDR) literal recovery, no cross-BL propagation."""
    low=max(0,upto-window)
    for i in range(upto-1,low-1,-1):
        x=records[i]
        if x["op"]=="add" and (m:=ADDI.match(x["arg"])) and int(m[1])==reg:
            base=int(m[2]);imm=int(m[3],16)
            for j in range(i-1,low-1,-1):
                p=records[j]
                if p["op"]=="adrp" and (q:=PAGE.match(p["arg"])) and int(q[1])==base:
                    return {"at":hex(int(q[2],16)+imm),"origin":[hex(p["addr"]),hex(x["addr"])]}
        if x["op"]=="ldr" and (m:=LDR.match(x["arg"])) and int(m[1])==reg:
            base=int(m[2]);imm=int(m[3],16)
            for j in range(i-1,low-1,-1):
                p=records[j]
                if p["op"]=="adrp" and (q:=PAGE.match(p["arg"])) and int(q[1])==base:
                    return {"at":hex(int(q[2],16)+imm),"origin":[hex(p["addr"]),hex(x["addr"])],"indirect":True}
    return None

def candidate_selector_from_mov(ins,index,macho):
    # The evidence below is one linear local window, not inter-block SSA.
    for k in range(index-1,max(-1,index-8),-1):
        row=ins[k]
        if row["op"]!="mov":continue
        found=re.fullmatch(r"x1, x(\\d+)",row["arg"])
        if not found:continue
        origin=int(found[1])
        if origin==0:
            for h in range(k-1,max(-1,k-12),-1):
                if ins[h]["op"]=="bl" and ins[h]["arg"]=="#0x43658":
                    input_addr=reg_address(ins,h,0,window=8)
                    if input_addr:
                        literal=macho.cfstring(int(input_addr["at"],16))
                        if literal and literal.get("text"):
                            return {"method":literal["text"],"source":"preceding_NSSelectorFromString_cfstring",
                                    "candidate":True,"sourceAddr":literal["cfstring_at"],
                                    "callsite":hex(ins[h]["addr"])}
        else:
            v=reg_address(ins,k,origin,window=85)
            if v and v.get("indirect"):
                desc=macho.selref(int(v["at"],16))
                if desc and desc.get("name"):
                    return {"method":desc["name"],"source":"prior_objc_selref_through_register",
                            "candidate":True,"sourceAddr":desc["at"]}
    return None

def hooks(rows,macho):
    result=[];byfunc=collections.defaultdict(list)
    for row in rows:byfunc[row["start"]].append(row)
    for fn,ins in byfunc.items():
        if fn is None:continue
        for i,x in enumerate(ins):
            if x["op"]!="bl" or not (m:=BL.match(x["arg"])):continue
            target=int(m[1],16)
            name=next((n for n,a in IMPORTS.items() if a==target),None)
            if name is None:continue
            call={"callsite":hex(x["addr"]),"function":hex(fn),"import":name}
            for reg in (0,1,2,3):
                r=reg_address(ins,i,reg,window=14 if reg in (1,2,3) else 24)
                if not r:continue
                at=int(r["at"],16)
                out={**r}
                if r.get("indirect"):
                    out["pointer"]=hex(macho.pointer(at)) if macho.pointer(at) is not None else None
                    if reg==1:
                        out["selector"]=macho.selref(at)
                else:
                    out["literal"]=macho.text(at)
                    out["cfstring"]=macho.cfstring(at)
                call[f"x{reg}_candidate"]=out
            if name=="_MSHookMessageEx":
                direct=call.get("x1_candidate",{}).get("selector")
                if direct and direct.get("name"):
                    call["selector_evidence"]={"method":direct["name"],
                        "source":"original_authenticated_objc_selref","candidate":False}
                else:
                    possible=candidate_selector_from_mov(ins,i,macho)
                    if possible:call["selector_evidence"]=possible
            # Locate *nearby* class lookup candidates; because register x0 is
            # volatile these are not asserted to be the exact receiver class.
            names=[]
            for k in range(max(0,i-90),i):
                row=ins[k]
                if row["op"]=="bl" and row["arg"] in ("#0x43a18","#0x43634"):
                    r=reg_address(ins,k,0,window=6)
                    if r:
                        raw=macho.class_or_string(int(r["at"],16))
                        if raw:names.append({"className":raw,"classLookupCall":hex(row["addr"]),
                                                "classLookupKind":"objc_getClass" if row["arg"]=="#0x43a18" else "NSClassFromString"})
            if names:call["nearby_class_lookups"]=names[-8:]
            result.append(call)
    return [x for x in result if x["import"] in ("_MSHookMessageEx","_MSHookFunction")]

def scan_pointer_refs(macho):
    matches=[]
    for sec in macho.sections:
        if sec["segment"] not in ("__DATA","__DATA_CONST"):continue
        if sec["section"] in ("__bss","__common"):continue
        for addr in range(sec["addr"],sec["addr"]+sec["size"]-7,8):
            value=macho.pointer(addr)
            if value in CALLBACKS:
                matches.append({"section":sec["section"],"location":hex(addr),
                                "callback":hex(value)})
    return matches

def main():
    p=argparse.ArgumentParser()
    for flag in ("thin","load_commands","function_starts","full_disassembly","out"):
        p.add_argument("--"+flag.replace("_","-"),type=Path,required=True)
    a=p.parse_args()
    macho=ThinMachO(a.thin.read_bytes(),json.loads(a.load_commands.read_text()))
    ins=rows_from_asm(gzip.decompress(a.full_disassembly.read_bytes()).decode(),
                      json.loads(a.function_starts.read_text()))
    calls=hooks(ins,macho)
    roots=scan_pointer_refs(macho)
    result={"provenance":"Original on-disk CarPlayPro Speed 0.9.97 arm64 SpeedAlerts.dylib (static)",
            "no_runtime_events":True,"no_goFA_field_map":True,
            "method_hook_calls":len([x for x in calls if x["import"]=="_MSHookMessageEx"]),
            "function_hook_calls":len([x for x in calls if x["import"]=="_MSHookFunction"]),
            "hook_import_calls":calls,"raw_pointer_refs_to_four_callbacks":roots}
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"ORIGINAL_OBJC_HOOK_TARGETS.json").write_text(json.dumps(result,indent=2)+"\n")
    lines=["# Original CarPlayPro Speed hook targets: source-by-source",
           "","**Static binary only**. Exact class/selector pointer resolution may be absent",
           "for chained fixups or Swift fields. Nearby class lookups are not ABI proof.",
           "No private GOFA values nor license data are read or generated.",
           "",f"- Original MSHookMessageEx callsites: {result['method_hook_calls']}",
           f"- Original MSHookFunction callsites: {result['function_hook_calls']}",
           f"- Raw pointer references to exported GOFA callbacks: {len(roots)}",
           "","## Hook registrations with recovered selector and exact callback address"]
    for call in calls:
        line=f"- `{call['callsite']}` (`{call['function']}`) {call['import']}"
        sel=call.get("selector_evidence")
        if sel:
            line+=f" selector=`{sel.get('method')}` ({sel['source']})"
        replacement_reg="x2_candidate" if call["import"]=="_MSHookMessageEx" else "x1_candidate"
        target=call.get(replacement_reg,{})
        if target and not target.get("indirect"):
            line+=f" replacementCandidate=`{target['at']}`"
        if call.get("nearby_class_lookups"):
            line+=" candidateClass="+", ".join("`"+v["className"]+"`" for v in call["nearby_class_lookups"][-3:])
        lines.append(line)
    lines+=["","## Explicit source-specific evidence gates",
       "The probe is NOT a GOFA speed-limit, camera, or turn decoder.",
       "Any selector/class must be validated in the running GOFA process.",
       "Do not use unverified method signatures, offsets or synthetic alerts."]
    (a.out/"ORIGINAL_OBJC_HOOK_TARGETS.md").write_text("\n".join(lines)+"\n")
    print("QA166_ORIGINAL_HOOK_TARGET_MAP_GENERATED",len(calls),"calls",len(roots),"raw_callback_pointers")
if __name__=="__main__":main()
