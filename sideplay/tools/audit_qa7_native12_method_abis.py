#!/usr/bin/env python3
"""Read-only method-level Mach-O audit: actual QA7 versus Native12 + SidePlay.

Extracts all inspectable arm64 ObjC class, metaclass and category selectors,
type encoding, implementation address, LC_FUNCTION_STARTS and nm symbols.
No DEB maintainer scripts or executable code is ever run.
"""
import argparse
import collections
import gzip
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile

ARM=0x0100000c
FEATURES=[
("window/chrome",r"window|dock|chrome|status|carplay|fullscreen|inset|safearea|zoom|screen"),
("scene/bridge",r"bridge|host|scene|activat|connect|retire|terminate|dismiss|invalidate|rootview"),
("pill/menu",r"pill|picker|choose|menu|overlay|slot|button|tap|recent|appselect"),
("divider/split",r"divid|ratio|layout|split|frame|pan|swap|drag|grip|gesture|focus"),
("HUD8/speed",r"speed|hud|bubble|gofa|waze|vietmap|source|limit"),
("styles",r"border|style|blur|tint|splash|label|color|visual|red"),
("settings",r"setting|pref|language|autoopen|restorelast"),
("licensing",r"licens|trial|lease|expir|subscription|payment")
]
IMPORTANT=("CBWindow","CBBridgeManager","CBBridgedSplitApp",
 "CBSlotPillView","CBDividerView","CBMultitaskingOverlayView",
 "CBSplitSplashScreenView","CBDashboardSettings","DFSpeedNativeHUD",
 "DFSpeedSplit7Driver","DFOwnerPollingDriver","SPDash","SPPane",
 "SPCarSceneDelegate","DFSPNativeFrame","DFSPNativeSlotPill",
 "DFSPNative12Host","DFSPNativeAdapter")
def command(*args):
    try:
        p=subprocess.run(args,capture_output=True,timeout=240)
        return p.returncode,p.stdout.decode("utf-8","replace"),p.stderr.decode("utf-8","replace")
    except Exception as ex:return 127,"",str(ex)
def digest(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda:f.read(1024*1024),b""):h.update(b)
    return h.hexdigest()
def thin(b):
    if b[:4] in (b"\xca\xfe\xba\xbe",b"\xca\xfe\xba\xbf",b"\xbe\xba\xfe\xca",b"\xbf\xba\xfe\xca"):
        endian=">" if b[:4] in (b"\xca\xfe\xba\xbe",b"\xca\xfe\xba\xbf") else "<"
        fat64=b[:4] in (b"\xca\xfe\xba\xbf",b"\xbf\xba\xfe\xca")
        n=struct.unpack_from(endian+"I",b,4)[0]
        for i in range(min(n,40)):
            o=8+i*(32 if fat64 else 20)
            if fat64:
                typ,sub,off,size,align,res=struct.unpack_from(endian+"iiQQII",b,o)
            else:
                typ,sub,off,size,align=struct.unpack_from(endian+"iiIII",b,o)
            if typ==ARM and off+size<=len(b):return b[off:off+size]
        raise ValueError("no arm64 slice")
    return b
class MachO:
    def __init__(self,blob):
        self.b=thin(blob);self.seg=[];self.sec=[];self.fn=None;self.problems=[];self.selmap={}
        if len(self.b)<32 or self.b[:4]!=b"\xcf\xfa\xed\xfe":
            raise ValueError("not arm64 MachO64")
        hdr=struct.unpack_from("<IiiIIIII",self.b,0)
        ncmds=hdr[4];o=32
        for i in range(min(1000,ncmds)):
            if o+8>len(self.b):break
            c,size=struct.unpack_from("<II",self.b,o)
            if size<8 or o+size>len(self.b):break
            if (c&0x7fffffff)==0x19 and size>=72:
                t=struct.unpack_from("<II16sQQQQiiII",self.b,o)
                s={"vm":t[3],"size":t[4],"file":t[5],"file_size":t[6],
                   "name":t[2].split(b"\0")[0].decode("ascii","replace")}
                self.seg.append(s)
                for j in range(min(t[9],150)):
                    q=o+72+j*80
                    if q+80>o+size:break
                    v=struct.unpack_from("<16s16sQQIIIIIIII",self.b,q)
                    self.sec.append({"name":v[0].split(b"\0")[0].decode("ascii","replace"),
                         "addr":v[2],"size":v[3]})
            if (c&0x7fffffff)==0x26 and size>=16:
                off,sz=struct.unpack_from("<II",self.b,o+8)
                if off+sz<=len(self.b):self.fn=self.b[off:off+sz]
            o+=size
        self.base=next((s["vm"] for s in self.seg if s["name"]=="__TEXT"),0)
    def off(self,va,size=1):
        if not va:return None
        for s in self.seg:
            if s["vm"]<=va and va+size<=s["vm"]+s["file_size"]:
                off=s["file"]+(va-s["vm"])
                if off+size<=len(self.b):return off
        return None
    def val(self,va,form):
        n=struct.calcsize("<"+form);p=self.off(va,n)
        return struct.unpack_from("<"+form,self.b,p)[0] if p is not None else None
    def st(self,va):
        p=self.off(va)
        if p is None:return None
        end=self.b.find(b"\0",p,min(len(self.b),p+500))
        if end<0 or end-p>280 or end==p:return None
        raw=self.b[p:end]
        if any(q<32 for q in raw):return None
        return raw.decode("utf-8","replace")
    def ptrs(self,name):
        for s in self.sec:
            if s["name"]!=name:continue
            for i in range(min(50000,s["size"]//8)):
                a=self.val(s["addr"]+i*8,"Q")
                if a and self.off(a,8) is not None:yield a
    def ro(self,cls):
        if not cls or self.off(cls,40) is None:return None
        data=self.val(cls+32,"Q")
        if data is None:return None
        data=data&0x0000fffffffffff8
        nameptr=self.val(data+24,"Q")
        name=self.st(nameptr) if nameptr else None
        mp=self.val(data+32,"Q")
        if name and name[0].isalpha():return name,mp
        return None
    def methods(self,ptr):
        if not ptr or self.off(ptr,8) is None:return []
        hdr=self.val(ptr,"I");count=self.val(ptr+4,"I")
        if hdr is None or count is None or count>15000:return []
        small=bool(hdr&0x80000000);direct=bool(hdr&0x40000000)
        step=hdr&0xffff
        if step not in (12,24) and not (12<=step<256):step=12 if small else 24
        if self.off(ptr+8,max(1,count)*step) is None:return []
        items=[]
        for i in range(count):
            q=ptr+8+i*step
            if small:
                a=self.val(q,"i");b=self.val(q+4,"i");c=self.val(q+8,"i")
                if None in (a,b,c):continue
                selptr=q+a
                if not direct:
                    # Chained dyld fixups can leave SELREF's raw pointer unusable
                    # on disk. otool decodes the __objc_selrefs table faithfully.
                    sel=self.selmap.get(selptr)
                    if not sel:
                        selptr=self.val(selptr,"Q") or selptr
                        sel=self.st(selptr)
                else:
                    sel=self.st(selptr)
                typ=self.st(q+4+b)
                imp=q+8+c
            else:
                selptr=self.val(q,"Q");typeptr=self.val(q+8,"Q")
                sel=self.st(selptr) if selptr else None
                typ=self.st(typeptr) if typeptr else None
                imp=self.val(q+16,"Q")
            if sel:
                items.append({"selector":sel,"type":typ or "","imp":hex(imp) if imp else "",
                              "representation":"relative" if small else "absolute"})
        return items
    def objc(self):
        out=[];seen=set()
        for name in ("__objc_classlist","__objc_nlclslist"):
            for c in self.ptrs(name):
                if c in seen:continue
                seen.add(c);ro=self.ro(c)
                if not ro:continue
                for m in self.methods(ro[1]):out.append({"class":ro[0],"kind":"instance",**m})
                meta=self.val(c,"Q");metaro=self.ro(meta)
                if metaro:
                    for m in self.methods(metaro[1]):
                        out.append({"class":ro[0],"kind":"class",**m})
        for name in ("__objc_catlist","__objc_nlcatlist"):
            for cat in self.ptrs(name):
                catname=self.st(self.val(cat,"Q")) or "anonymous"
                owner=self.val(cat+8,"Q")
                r=self.ro(owner) if owner else None
                classname=r[0] if r else "unknown"
                for methoff,kind in ((16,"instance"),(24,"class")):
                    for m in self.methods(self.val(cat+methoff,"Q")):
                        out.append({"class":classname,"kind":kind,"category":catname,**m})
        return sorted({(x["class"],x["kind"],x["selector"],x.get("category","")):x for x in out}.values(),
                      key=lambda x:(x["class"],x["kind"],x["selector"]))
    def starts(self):
        if self.fn is None:return []
        idx=0;pos=0;result=[]
        while idx<len(self.fn) and len(result)<200000:
            num=0;shift=0
            for _ in range(10):
                if idx==len(self.fn):return result
                c=self.fn[idx];idx+=1;num|=(c&127)<<shift
                if not c&128:break
                shift+=7
            if not num:break
            pos+=num;result.append(hex(self.base+pos))
        return result

def otool_selrefs(raw,mm):
    """Map selref slot virtual address to selector, as resolved by Apple otool."""
    match=re.search(r"Contents of \([^,\n]+,__objc_selrefs\) section\n([\s\S]*?)(?=\nContents of \(|\Z)",raw)
    sec=next((x for x in mm.sec if x["name"]=="__objc_selrefs"),None)
    if not match or not sec:return {}
    lines=re.findall(r"^\s*0x[0-9a-fA-F]+\s+([^\r\n]+)$",match.group(1),re.M)
    if not lines:return {}
    count=min(len(lines),sec["size"]//8)
    return {sec["addr"]+i*8:lines[i].strip() for i in range(count)}

def audit_file(p,out,label):
    mm=MachO(p.read_bytes())
    rc2,raw,err2=command("otool","-ov","-arch","arm64",str(p))
    mm.selmap=otool_selrefs(raw,mm)
    methods=mm.objc();starts=mm.starts()
    rc,nm,err=command("nm","-a",str(p))
    nm_lines=[s for s in nm.splitlines() if s.strip()]
    filekey=label+"-"+re.sub(r"[^a-zA-Z0-9._-]","_",p.name)
    with gzip.open(out/(filekey+".otool.gz"),"wt") as f:
        f.write(raw);f.write("\nSTDERR: "+err2)
    return {"filename":p.name,"sha256":digest(p),"objc_methods":methods,
            "method_count":len(methods),"class_count":len({m["class"] for m in methods}),
            "lc_function_starts":starts,"nm_symbols":nm_lines,
            "otool_bytes":len(raw),"otool_rc":rc2,"selrefs_decoded":len(mm.selmap),
            "objc_sections":[x for x in mm.sec if "objc" in x["name"]]}

def run(args):
    result={}
    with tempfile.TemporaryDirectory(prefix="duoface-method-") as tmp:
        for label in ("qa7","native12","sideplay104"):
            deb=Path(getattr(args,label));expected=getattr(args,label+"_sha256")
            if digest(deb)!=expected:raise RuntimeError(label+" SHA mismatch")
            root=Path(tmp)/label
            rc,out,err=command("dpkg-deb","-x",str(deb),str(root))
            if rc:raise RuntimeError("dpkg-deb failed "+err)
            found=[]
            for p in sorted(root.rglob("*")):
                if not p.is_file():continue
                magic=p.open("rb").read(4)
                if magic in (b"\xcf\xfa\xed\xfe",b"\xca\xfe\xba\xbe",b"\xca\xfe\xba\xbf"):
                    found.append(p)
            if not found:raise RuntimeError(label+" no Mach-O")
            result[label]=[audit_file(p,args.out,label) for p in found]
    summary=["# Bảng phương thức Mach-O — QA7 đang dùng vs Native12/HUD8, SidePlay",
      "",
      "Extraction: pinned SHA256 DEBs; all discovered arm64 ObjC class/metaclass/category",
      "methods with type encoding and IMP, plus LC_FUNCTION_STARTS + nm symbols.",
      "Raw complete otool -ov is stored as compressed build artifacts.",
      "ABI/method presence DOES NOT prove matching UI behavior or live CarPlay bar.",
      "",
      "| Runtime | Mach-O | ObjC methods | Classes with methods | Function start offsets |",
      "|---|---:|---:|---:|---:|"]
    for label,bins in result.items():
        summary.append("| "+label+" | "+str(len(bins))+" | "+
              str(sum(b["method_count"] for b in bins))+" | "+
              str(sum(b["class_count"] for b in bins))+" | "+
              str(sum(len(b["lc_function_starts"]) for b in bins))+" |")
    summary.extend(["","## Tất cả Mach-O đã duyệt",""])
    for label,bins in result.items():
        summary.append("### "+label)
        for b in bins:
            counts=collections.Counter(m["class"] for m in b["objc_methods"])
            summary.append("- "+b["filename"]+": "+str(b["method_count"])+" methods, "+
                str(len(counts))+" classes, "+
                str(len(b["lc_function_starts"]))+" LC_FUNCTION_STARTS; "+
                str(b["otool_bytes"])+" raw metadata bytes.")
            summary.append("  Classes: "+", ".join(k+" ("+str(v)+")" for k,v in sorted(counts.items())))
        summary.append("")
    summary.extend(["## Các nhóm hàm theo keyword (chỉ số phân loại, không phải tỷ lệ parity)","",
       "| Nhóm | QA7 | Native12 | SidePlay |","|---|---:|---:|---:|"])
    for family,pat in FEATURES:
        vals=[]
        for label,bins in result.items():
            vals.append(sum(bool(re.search(pat,m["class"]+" "+m["selector"],re.I))
                for b in bins for m in b["objc_methods"]))
        summary.append("| "+family+" | "+str(vals[0])+" | "+str(vals[1])+" | "+str(vals[2])+" |")
    summary.extend(["","## Từng hàm/IMP của các class lõi (không giới hạn số hàm)",""])
    for cls in IMPORTANT:
        summary.append("### "+cls)
        for label,bins in result.items():
            for b in bins:
                for m in b["objc_methods"]:
                    if m["class"]!=cls:continue
                    summary.append("- "+label+"/"+b["filename"]+"  "+
                        ("+" if m["kind"]=="class" else "-")+"["+cls+" "+m["selector"]+
                        "] type="+m["type"]+" imp="+m["imp"])
        summary.append("")
    summary.extend(["## Phân biệt đã thay và chưa thay",
       "",
       "- Source QA7 SPDash hooks vẫn gọi %orig; nhận dữ liệu thật của app/scene từ SidePlay.",
       "- QA7 chỉ hide chipView/layoutButton/placeholder khi overlay mount thành công. Header/Style/picker SidePlay vẫn có thể vẽ.",
       "- App và Style trên QA7 còn gọi showPickerForPane: và layoutChooser của SidePlay.",
       "- QA7 không có owner riêng cho CarPlay system chrome/bar: applyNormal chỉ đổi content root và windowLevel, fallback left 64pt. User đã xác nhận thanh bar chưa hiện.",
       "- Native12 Dashboard/FullscreenBridge/VisualHook/LogoGrip/SpeedHUD/SpeedOwner và iPhone UI không nằm trong QA7 addon.",
       "- Tất cả selector metadata nằm ở method-index.json. Raw otool.gz dùng để đánh giá sai khác của parser; còn thiếu thử nghiệm trực tiếp trên thiết bị.",
       ""])
    (args.out/"METHOD_AUDIT.md").write_text("\n".join(summary)+"\n",encoding="utf-8")
    (args.out/"method-index.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    small={k:[{"filename":b["filename"],"method_count":b["method_count"],"class_count":b["class_count"],
             "fn_starts":len(b["lc_function_starts"]),"otool_bytes":b["otool_bytes"]} for b in v] for k,v in result.items()}
    (args.out/"summary.json").write_text(json.dumps(small,ensure_ascii=False,indent=2)+"\n")
    for label,bins in result.items():
        count=sum(b["method_count"] for b in bins)
        print("METHOD_SCAN_"+label.upper()+"_METHODS="+str(count))
        if count==0:raise RuntimeError(label+" parse zero methods; inspect raw otool instead")
    classes={m["class"] for b in result["sideplay104"] for m in b["objc_methods"]}
    if "SPDash" not in classes:raise RuntimeError("SPDash missing: full selector coverage cannot be claimed")
    print("QA7_NATIVE12_SIDEPLAY_METHOD_SCAN_PASS")
if __name__=="__main__":
    p=argparse.ArgumentParser()
    for n in ("qa7","native12","sideplay104"):
        p.add_argument("--"+n,required=True)
        p.add_argument("--"+n+"-sha256",required=True)
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True);run(a)
