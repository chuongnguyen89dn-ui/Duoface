#!/usr/bin/env python3
"""Decode raw original Native12 Mach-O data and cross-index App/control ARM64.
READ ONLY; numerical evidence never reused as vendor code or device UI proof.
"""
import argparse
import hashlib
import json
import math
import pathlib
import re
import struct

PIN="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
METHODS=["initWithFrame:","loadInstalledApps","setupAppPickerCardsInCardW:cardH:contentY:","setupCardContent","addMoreAppsTapped:","appSelected:","pageControlChanged:"]
UI_TERMS=("colorWithWhite:alpha:","colorWithRed:green:blue:alpha:","setBackgroundColor:","setTextColor:","setTintColor:","setCornerRadius:","setBorderColor:","setBorderWidth:","setShadowOpacity:","setShadowRadius:","setShadowOffset:","setFrame:","setImage:","setImage:forState:","setAlpha:","setTitleColor:forState:","setFont:","systemFontOfSize:weight:","setContentMode:")
INSTRUCTION=re.compile(r"^\s*([0-9a-f]+):\s+(\S+)\s*(.*)$")
ADRP=re.compile(r"^x(\d+),\s*[0-9]+ ; (0x[0-9a-f]+)$")
LDR=re.compile(r"^([dsq])(\d+),\s*\[x(\d+), #0x([0-9a-f]+)\]")

def segments(data):
    assert struct.unpack_from("<I",data,0)[0]==0xfeedfacf,"not little-endian Mach-O64"
    count=struct.unpack_from("<I",data,16)[0]
    offset=32
    allsegs=[]
    for i in range(count):
        typ,size=struct.unpack_from("<II",data,offset)
        assert size>=8 and offset+size<=len(data)
        if typ==0x19:
            v=struct.unpack_from("<16sQQQQiiII",data,offset+8)
            name=v[0].split(b"\x00")[0].decode("ascii","replace")
            allsegs.append(dict(name=name,vmaddr=v[1],vmsize=v[2],fileoff=v[3],filesize=v[4]))
        offset+=size
    return allsegs

def raw_float(data,segs,virtual_addr,kind):
    n=4 if kind=="s" else 8
    for s in segs:
        if s["vmaddr"]<=virtual_addr and virtual_addr+n<=s["vmaddr"]+s["filesize"]:
            off=s["fileoff"]+virtual_addr-s["vmaddr"]
            raw=data[off:off+n]
            if len(raw)!=n:continue
            num=struct.unpack("<f" if kind=="s" else "<d",raw)[0]
            return dict(address=hex(virtual_addr),segment=s["name"],offset=off,raw=raw.hex(),value=num if math.isfinite(num) else None)
    return dict(address=hex(virtual_addr),error="ADDRESS_NOT_MAPPED")

def decode(rows,data,segs):
    pages={}
    literals=[]
    sites=[]
    for i,line in enumerate(rows):
        m=INSTRUCTION.match(line)
        if not m:continue
        pc=int(m[1],16);op=m[2];arg=m[3]
        ad=ADRP.match(arg) if op=="adrp" else None
        if ad:
            pages[int(ad[1])]=int(ad[2],16)
        elif op in ("mov","movz","movk","movn","add","sub","adr") and re.match(r"^x\d+",arg):
            dest=int(re.match(r"^x(\d+)",arg)[1]);pages.pop(dest,None)
        load=LDR.match(arg) if op=="ldr" else None
        if load:
            kind,num,reg,offset=load.groups()
            base=pages.get(int(reg))
            if base is not None and kind in ("s","d"):
                v=raw_float(data,segs,base+int(offset,16),kind)
                literals.append(dict(pc=hex(pc),instruction=line,destination=kind+num,**v))
        if "Objc selector ref:" in line and any(term in line for term in UI_TERMS):
            sites.append(dict(pc=hex(pc),
                selector=line.split("Objc selector ref:",1)[1].strip(),
                previous_instructions=rows[max(0,i-20):i],
                next_instructions=rows[i+1:i+23],
                recent_literalfloats=[q for q in literals if int(q["pc"],16)>=pc-0x140][-12:]))
    return dict(sites=sites,literal_floats=literals)

def main():
    ap=argparse.ArgumentParser()
    for arg in ("binary","existing-imp","extra-imp","out"):
        ap.add_argument("--"+arg,type=pathlib.Path,required=True)
    a=ap.parse_args()
    data=a.binary.read_bytes()
    assert hashlib.sha256(data).hexdigest()==PIN
    segs=segments(data)
    old=json.loads(a.existing_imp.read_text())
    more=json.loads(a.extra_imp.read_text())
    assert old["dashboard_macho_sha256"]==more["dashboard_macho_sha256"]==PIN
    found={}
    for index in (old,more):
        for x in index["methods"]:
            if x["class"]=="CBMultitaskingOverlayView":
                found[x["selector"]]=x
    scanned={}
    for name in METHODS:
        assert name in found,name
        x=found[name]
        scanned[name]=dict(imp=x["imp"],objc_type=x["objc_type"],insns=len(x["instructions"]),**decode(x["instructions"],data,segs))
    sampled={x["address"]:x["value"] for m in scanned.values() for x in m["literal_floats"]}
    keys=[hex(p) for p in (0x311720,0x311728,0x311738,0x311828)]
    assert all(x in sampled for x in keys),[x for x in keys if x not in sampled]
    assert abs(sampled["0x311720"]-.08)<.001 and abs(sampled["0x311728"]-.52)<.001
    result=dict(kind="ORIGINAL_SHA_VERIFIED_LITERAL_CALLSITE_STATIC_ONLY",
        dashboard_sha256=PIN,segments=segs,keys={x:sampled[x] for x in keys},methods=scanned,
        caveat="Values are raw original binary constants and nearby callsites; branch state, effective UIColor and screenshot pixels are separate proofs.")
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"RAW_APP_LITERALS_AND_CALLSITES.json").write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
    lines=["# Original Native12 App real Mach-O VM literal decoding","",
           "Dashboard SHA256 "+PIN,"","## Color/alpha literals"]
    lines += ["- "+k+" = "+str(v) for k,v in result["keys"].items()]
    for name,e in scanned.items():
        lines+=["","## "+name+" @"+e["imp"]]
        for site in e["sites"]:
            sample=", ".join(x["address"]+"="+str(x.get("value")) for x in site["recent_literalfloats"][-8:])
            lines+=["- "+site["pc"]+" "+site["selector"]+" nearby float literals: "+sample]
    lines+=["","Numerical load is not proof of rendered color in every branch or UI/device parity."]
    (a.out/"ORIGINAL_APP_LITERALS_SUMMARY.md").write_text("\n".join(lines)+"\n")
    print("NATIVE12_APP_ORIGINAL_LITERAL_DATA_PASS",result["keys"],
          {k:len(v["sites"]) for k,v in scanned.items()})
if __name__=="__main__":
    main()
