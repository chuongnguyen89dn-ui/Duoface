#!/usr/bin/env python3
"""Static, read-only, lossless Debian/arm64 Mach-O inventory for CarPlayPro 0.9.97.
No installed tweak code is executed; maintainer scripts are inspected, never run.
Derived reports and unpacked payload are saved only in this project repository.
"""
from __future__ import annotations
import argparse, collections, gzip, hashlib, json, os, plistlib, re, shutil, stat, struct, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEB = ROOT / "sideplay/audit/com.carplaypro.speed_0.9.97_iphoneos-arm64.deb"
DEST = ROOT / "sideplay/audit/carplaypro-0.9.97"
EXPECTED_GIT_SHA = "30f366a8bed8630c88935cac7146c86b875f0851"
def sha256(x):
    h=hashlib.sha256()
    with open(x,"rb") as f:
        for buf in iter(lambda:f.read(1024*1024),b""): h.update(buf)
    return h.hexdigest()
def put(path, value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(value,encoding="utf-8")
def js(path,value):
    put(path,json.dumps(value,indent=2,ensure_ascii=False,sort_keys=True)+"\n")
def cmd(args, out):
    proc=subprocess.run(args,capture_output=True,text=True,errors="replace",check=False)
    put(out,proc.stdout+(("\nSTDERR:\n"+proc.stderr) if proc.stderr else ""))
    if proc.returncode: raise RuntimeError("COMMAND_FAILED "+repr(args)+" rc="+str(proc.returncode))
    return proc.stdout
def safe(v,key=""):
    # No credentials or secrets persisted in decoded report, original DEB remains canonical.
    if re.search(r"(?i)(password|passphrase|secret|private.?key|access.?token|bearer|cookie|authorization|activation.?code)",key):
        return "[REDACTED:credential-value]"
    if isinstance(v,bytes):
        return {"bytes":len(v),"sha256":hashlib.sha256(v).hexdigest(),"data_preview":"[BINARY_NOT_EMBEDDED]"}
    if isinstance(v,plistlib.UID): return {"UID":v.data}
    if isinstance(v,(datetime,)):return v.isoformat()
    if isinstance(v,dict):return {str(k):safe(x,str(k)) for k,x in v.items()}
    if isinstance(v,(list,tuple)):return [safe(x,key) for x in v]
    return v
def redacted_line(line):
    if re.search(r"(?i)(bearer\s+[a-z0-9_./+=-]{10,}|(token|password|secret|private.?key|cookie|authorization)[=:]\s*\S{6,})",line):
        return "[REDACTED:potential-credential] sha256="+hashlib.sha256(line.encode(errors="replace")).hexdigest()
    return line
def info_strings(data):
    for m in re.finditer(rb"[\x20-\x7e]{4,}",data):
        yield m.start(), "ascii",redacted_line(m.group().decode("ascii","replace"))
    # UTF16LE unicode or ASCII: at least four printable characters.
    for m in re.finditer(rb"(?:[\x20-\x7e]\x00){4,}",data):
        yield m.start(),"utf16le",redacted_line(m.group().decode("utf-16-le","replace"))
def macho_slices(data):
    """Enumerate every universal Mach-O architecture; offsets inside slice are relative."""
    magic=data[:4]
    if magic not in (b"\xca\xfe\xba\xbe",b"\xbe\xba\xfe\xca",b"\xca\xfe\xba\xbf",b"\xbf\xba\xfe\xca"):
        return [({"slice_index":0,"arch":"thin","slice_offset":0,"slice_size":len(data)},data)]
    endian=">" if magic in (b"\xca\xfe\xba\xbe",b"\xca\xfe\xba\xbf") else "<"
    fat64=magic in (b"\xca\xfe\xba\xbf",b"\xbf\xba\xfe\xca")
    count=struct.unpack_from(endian+"I",data,4)[0]
    if count<1 or count>64:raise ValueError("invalid fat Mach-O architecture count")
    entry_size=32 if fat64 else 20
    out=[]
    for i in range(count):
        at=8+i*entry_size
        if at+entry_size>len(data):raise ValueError("truncated universal arch table")
        cpu,sub=struct.unpack_from(endian+"II",data,at)
        if fat64:off,length,align=struct.unpack_from(endian+"QQI",data,at+8)
        else:off,length,align=struct.unpack_from(endian+"III",data,at+8)
        if length<32 or off+length>len(data):raise ValueError("universal slice out of bounds")
        arch=("arm64e" if cpu==0x100000c and (sub&0xff)==2 else
              "arm64" if cpu==0x100000c else "cpu"+hex(cpu)+"sub"+hex(sub))
        out.append(({"slice_index":i,"arch":arch,"cpu":cpu,"subtype":sub,
                     "slice_offset":off,"slice_size":length,"align_log2":align},data[off:off+length]))
    return out

def codesign_metadata(data,signature):
    if not signature:return {"status":"no_signature"}
    off,size=signature["offset"],signature["size"]
    if off+size>len(data):return {"status":"out_of_bounds"}
    blob=data[off:off+size]
    ret={"status":"present","sha256":hashlib.sha256(blob).hexdigest(),"bytes":len(blob),"slots":[]}
    if len(blob)<12:return ret
    magic,length,count=struct.unpack_from(">III",blob,0)
    ret["magic"]=hex(magic)
    if magic!=0xfade0cc0 or length>len(blob) or count>200:return ret
    for i in range(count):
        typ,entry_offset=struct.unpack_from(">II",blob,12+i*8)
        if entry_offset+8>len(blob):continue
        kind,blen=struct.unpack_from(">II",blob,entry_offset)
        if blen<8 or entry_offset+blen>len(blob):continue
        content=blob[entry_offset+8:entry_offset+blen]
        rec={"type":typ,"magic":hex(kind),"bytes":blen,"sha256":hashlib.sha256(content).hexdigest()}
        if kind==0xfade7171:
            try:rec["entitlements"]=safe(plistlib.loads(content))
            except Exception as ex:rec["entitlements_parse_error"]=type(ex).__name__
        ret["slots"].append(rec)
    return ret

def macho(data):
    if len(data)<32:return None
    magic=data[:4]
    if magic not in (b"\xcf\xfa\xed\xfe",b"\xce\xfa\xed\xfe",b"\xfe\xed\xfa\xcf",b"\xfe\xed\xfa\xce",b"\xca\xfe\xba\xbe",b"\xbe\xba\xfe\xca"):
        return None
    if magic in (b"\xca\xfe\xba\xbe",b"\xbe\xba\xfe\xca"):return {"kind":"fat_macho","note":"multiple slices: scan via lipo if available","magic":magic.hex()}
    endian="<" if magic in (b"\xcf\xfa\xed\xfe",b"\xce\xfa\xed\xfe") else ">"
    is64=magic in (b"\xcf\xfa\xed\xfe",b"\xfe\xed\xfa\xcf")
    cputype,cpusubtype,filetype,ncmds,sizeofcmds,flags=struct.unpack_from(endian+"IIIIII",data,4)
    header=32 if is64 else 28
    ret={"kind":"macho64" if is64 else "macho32","endian":endian,"cputype":cputype,"cpusubtype":cpusubtype,"filetype":filetype,"flags":flags,"ncmds":ncmds,"sizeofcmds":sizeofcmds,"dylibs":[],"rpaths":[],"segments":[],"sections":[],"load_commands":[],"uuid":[],"build_versions":[],"code_signature":None,"symbols":[],"function_starts":[]}
    off=header
    for i in range(min(ncmds,5000)):
        if off+8>len(data):ret["error"]="load_commands_truncated";break
        cc,sz=struct.unpack_from(endian+"II",data,off)
        if sz<8 or off+sz>len(data):ret["error"]="bad_load_command_at_"+str(off);break
        base=cc&0x7fffffff
        detail={"index":i,"offset":off,"cmd":hex(cc),"size":sz}
        if base in (0xc,0xd,0x18,0x1f,0x20,0x23,0x24,0x25,0x26) and sz>=24:
            p=struct.unpack_from(endian+"I",data,off+8)[0]
            if 0<p<sz:
                name=data[off+p:off+sz].split(b"\0",1)[0].decode("utf-8","replace")
                ret["dylibs"].append({"command":hex(cc),"name":name})
                detail["name"]=name
        if base==0x1c and sz>=12:
            p=struct.unpack_from(endian+"I",data,off+8)[0]
            if 0<p<sz:
                name=data[off+p:off+sz].split(b"\0",1)[0].decode("utf-8","replace")
                ret["rpaths"].append(name);detail["rpath"]=name
        if base==0x1b and sz>=24:ret["uuid"].append(data[off+8:off+24].hex())
        if base==0x32 and sz>=24:
            platform,minos,sdk,nt=struct.unpack_from(endian+"IIII",data,off+8)
            ret["build_versions"].append({"platform":platform,"minos_raw":minos,"sdk_raw":sdk,"tools":nt})
        if base in (0x24,0x25,0x2f,0x30) and sz>=16:
            detail["version_raw"]=struct.unpack_from(endian+"I",data,off+8)[0]
        if base in (0x1,0x19):
            name=data[off+8:off+24].split(b"\0",1)[0].decode("utf-8","replace")
            if base==0x19 and sz>=72:
                vmaddr,vmsize,fileoff,filesize=struct.unpack_from(endian+"QQQQ",data,off+24)
                nsects=struct.unpack_from(endian+"I",data,off+64)[0]
                sec_start=off+72;sec_len=80
            elif base==0x1 and sz>=56:
                vmaddr,vmsize,fileoff,filesize=struct.unpack_from(endian+"IIII",data,off+24)
                nsects=struct.unpack_from(endian+"I",data,off+48)[0]
                sec_start=off+56;sec_len=68
            else:nsects=0;vmaddr=vmsize=fileoff=filesize=0;sec_start=off;sec_len=0
            ret["segments"].append({"name":name,"vmaddr":vmaddr,"vmsize":vmsize,"fileoff":fileoff,"filesize":filesize,"nsects":nsects})
            for si in range(min(nsects,5000)):
                so=sec_start+si*sec_len
                if so+sec_len>off+sz:ret["error"]="section_table_truncated";break
                sn=data[so:so+16].split(b"\0",1)[0].decode("utf-8","replace")
                sg=data[so+16:so+32].split(b"\0",1)[0].decode("utf-8","replace")
                if is64:addr,size=struct.unpack_from(endian+"QQ",data,so+32);f_off=struct.unpack_from(endian+"I",data,so+48)[0]
                else:addr,size,f_off=struct.unpack_from(endian+"III",data,so+32)
                ret["sections"].append({"segment":sg,"section":sn,"addr":addr,"size":size,"offset":f_off})
        if base==0x2 and sz>=24:
            symoff,nsyms,stroff,strsize=struct.unpack_from(endian+"IIII",data,off+8)
            ret["symtab"]={"symoff":symoff,"nsyms":nsyms,"stroff":stroff,"strsize":strsize}
        if base==0x1d and sz>=16:
            co,cs=struct.unpack_from(endian+"II",data,off+8)
            ret["code_signature"]={"offset":co,"size":cs,"sha256":hashlib.sha256(data[co:co+cs]).hexdigest() if co+cs<=len(data) else "invalid_bounds"}
        if base==0x26 and sz>=16:
            fo,fs=struct.unpack_from(endian+"II",data,off+8);ret["function_starts_record"]={"offset":fo,"size":fs}
        ret["load_commands"].append(detail);off+=sz
    st=ret.get("symtab")
    if st and st["stroff"]+st["strsize"]<=len(data):
        for i in range(min(st["nsyms"],300000)):
            off=st["symoff"]+i*(16 if is64 else 12)
            if off+(16 if is64 else 12)>len(data):break
            strx=struct.unpack_from(endian+"I",data,off)[0]
            if strx>=st["strsize"]:continue
            name=data[st["stroff"]+strx:st["stroff"]+st["strsize"]].split(b"\0",1)[0].decode("utf-8","replace")
            ntype,nsect,desc=struct.unpack_from("BB"+endian+"H" if False else endian+"BBH",data,off+4)
            value=struct.unpack_from(endian+("Q" if is64 else "I"),data,off+8)[0]
            ret["symbols"].append({"name":name,"value":value,"type":ntype,"section":nsect,"desc":desc})
    ft=ret.get("function_starts_record")
    if ft and ft["offset"]+ft["size"]<=len(data):
        raw=data[ft["offset"]:ft["offset"]+ft["size"]];v=p=0
        while p<len(raw):
            delta=0;shift=0
            while p<len(raw):
                c=raw[p];p+=1;delta|=(c&0x7f)<<shift;shift+=7
                if not c&0x80:break
            if not delta:break
            v+=delta;ret["function_starts"].append(v)
    return ret
def disasm_arm64(data,sec,target):
    try:
        from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
    except ImportError:
        return {"status":"capstone_unavailable","count":0}
    off=sec["offset"];end=off+sec["size"]
    if off<0 or end>len(data):return {"status":"section_out_of_bounds"}
    dis=Cs(CS_ARCH_ARM64,CS_MODE_ARM);counter=0
    target.parent.mkdir(parents=True,exist_ok=True)
    with gzip.open(target,"wt",encoding="utf-8") as f:
        for ins in dis.disasm(data[off:end],sec["addr"]):
            f.write(f"{ins.address:016x}\t{ins.bytes.hex()}\t{ins.mnemonic}\t{ins.op_str}\n")
            counter+=1
    return {"status":"ok","instructions":counter,"output":str(target.relative_to(DEST))}
def main():
    parser=argparse.ArgumentParser();parser.add_argument("--replace",action="store_true");args=parser.parse_args()
    if not DEB.exists():raise SystemExit("MISSING_SOURCE_DEB "+str(DEB))
    if DEST.exists():
        if not args.replace:raise SystemExit("AUDIT_ALREADY_EXISTS use --replace to rebuild only this audit")
        shutil.rmtree(DEST)
    if not all(shutil.which(t) for t in ("dpkg-deb","ar","file")):raise SystemExit("MISSING_TOOLS")
    DEST.mkdir(parents=True)
    root=DEST/"unpacked/rootfs";ctrl=DEST/"unpacked/control"
    root.mkdir(parents=True);ctrl.mkdir(parents=True)
    cmd(["dpkg-deb","-I",str(DEB)],DEST/"package-info.txt")
    cmd(["dpkg-deb","-f",str(DEB)],DEST/"control-fields.txt")
    cmd(["dpkg-deb","-c",str(DEB)],DEST/"archive-file-list.txt")
    cmd(["ar","t",str(DEB)],DEST/"archive-members.txt")
    # ONLY unpack. Never dpkg -i, sudo installation or maintainer script execution.
    subprocess.run(["dpkg-deb","-x",str(DEB),str(root)],check=True)
    subprocess.run(["dpkg-deb","-e",str(DEB),str(ctrl)],check=True)
    inv=[];machos=[];plists=[];images=[];allhashes=[]
    script_paths=[];bytype=collections.Counter()
    for base,scope in ((root,"rootfs"),(ctrl,"control")):
        for path in sorted(base.rglob("*"),key=lambda p:str(p)):
            rel=path.relative_to(base).as_posix()
            mode=stat.S_IMODE(path.lstat().st_mode)
            item={"scope":scope,"path":rel,"mode":oct(mode)}
            if path.is_symlink():item.update(type="symlink",target=os.readlink(path))
            elif path.is_dir():item.update(type="directory")
            elif path.is_file():
                data=path.read_bytes();item.update(type="file",size=len(data),sha256=hashlib.sha256(data).hexdigest(),
                    mime=subprocess.run(["file","-b",str(path)],capture_output=True,text=True).stdout.strip())
                allhashes.append(f'{item["sha256"]}  {scope}/{rel}')
                if scope=="control" and rel in ("postinst","prerm","preinst","postrm","config","triggers"):
                    script_paths.append({"path":rel,"sha256":item["sha256"],"executable":bool(mode&0o111)})
                try: pldata=plistlib.loads(data) if (data.startswith(b"bplist00") or data.lstrip().startswith(b"<?xml") or path.suffix.lower()==".plist") else None
                except Exception as ex:
                    pldata=None
                    if path.suffix.lower()==".plist":plists.append({"path":scope+"/"+rel,"error":type(ex).__name__})
                if pldata is not None:plists.append({"path":scope+"/"+rel,"decoded":safe(pldata),"format":"binary" if data.startswith(b"bplist") else "xml"})
                if data[:8]==b"\x89PNG\r\n\x1a\n" and len(data)>=24:
                    width,height=struct.unpack_from(">II",data,16)
                    images.append({"path":scope+"/"+rel,"format":"PNG","width":width,"height":height})
                if data[:3] in (b"\xff\xd8\xff",):
                    images.append({"path":scope+"/"+rel,"format":"JPEG","dimensions":"unknown"})
                if data[:4] in (b"\xca\xfe\xba\xbe",b"\xbe\xba\xfe\xca",b"\xca\xfe\xba\xbf",b"\xbf\xba\xfe\xca",
                                b"\xcf\xfa\xed\xfe",b"\xce\xfa\xed\xfe",b"\xfe\xed\xfa\xcf",b"\xfe\xed\xfa\xce"):
                    universal=macho_slices(data)
                    for meta,binary in universal:
                        mi=macho(binary)
                        if not mi:raise RuntimeError("KNOWN_MACHO_COULD_NOT_BE_PARSED "+rel)
                        ident=f"{len(machos)+1:03d}-{path.name}-{meta['arch']}"
                        safe_ident=re.sub(r"[^a-zA-Z0-9._-]","_",ident)
                        mi["path"]=scope+"/"+rel
                        mi["slice"]=meta
                        mi["size"]=len(binary)
                        mi["sha256"]=hashlib.sha256(binary).hexdigest()
                        mi["fat_container_sha256"]=item["sha256"]
                        mi["codesign_analysis"]=codesign_metadata(binary,mi.get("code_signature"))
                        syms=mi.pop("symbols",[])
                        starts=mi.pop("function_starts",[])
                        js(DEST/"macho"/(safe_ident+".load-commands.json"),mi)
                        js(DEST/"macho"/(safe_ident+".symbols.json"),syms)
                        js(DEST/"macho"/(safe_ident+".function-starts.json"),starts)
                        strings=list(info_strings(binary))
                        with gzip.open(DEST/"macho"/(safe_ident+".strings.txt.gz"),"wt",encoding="utf-8") as f:
                            for at,enc,value in strings:f.write(f"{at:08x}\t{enc}\t{value}\n")
                        secstrings={}
                        for sec in mi.get("sections",[]):
                            secname=sec["section"]
                            if secname in ("__objc_methname","__objc_classname","__objc_methtype","__objc_propname","__cstring","__swift5_reflstr","__swift5_typeref"):
                                offset,length=sec["offset"],sec["size"]
                                if offset+length<=len(binary) and length<=10*1024*1024:
                                    secstrings[secname]=[redacted_line(q.decode("utf-8","replace")) for q in binary[offset:offset+length].split(b"\0") if len(q)>=2]
                        js(DEST/"macho"/(safe_ident+".section-strings.json"),secstrings)
                        capstones=[]
                        if mi.get("cputype")==0x100000c:
                            for sec in mi.get("sections",[]):
                                if sec["section"]=="__text" and sec["segment"]=="__TEXT":
                                    capstones.append(disasm_arm64(binary,sec,DEST/"disassembly"/(safe_ident+".arm64.txt.gz")))
                        mi_summary={"path":mi["path"],"name":safe_ident,"size":len(binary),"sha256":mi["sha256"],
                            "arch":meta["arch"],"slice":meta,
                            "cputype":mi.get("cputype"),"filetype":mi.get("filetype"),"ncmds":mi.get("ncmds"),
                            "dylibs":mi.get("dylibs"),"symbol_count":len(syms),"function_start_count":len(starts),
                            "string_count":len(strings),"objc_classes":len(secstrings.get("__objc_classname",[])),
                            "objc_methods":len(secstrings.get("__objc_methname",[])), "code_signature":mi.get("codesign_analysis"),
                            "disassembly":capstones}
                        machos.append(mi_summary)
            else:item.update(type="other")
            bytype[item["type"]]+=1;inv.append(item)
    js(DEST/"inventory.json",inv)
    js(DEST/"macho-summary.json",machos)
    js(DEST/"plists-decoded.json",plists)
    js(DEST/"images.json",images)
    put(DEST/"SHA256SUMS.txt",f"{sha256(DEB)}  {DEB.relative_to(ROOT).as_posix()}\n"+"\n".join(allhashes)+"\n")
    summary={"source_repository":"chuongnguyen89dn-ui/Duoface","source_branch":"main",
      "source_path":DEB.relative_to(ROOT).as_posix(),"source_size":DEB.stat().st_size,
      "source_sha256":sha256(DEB),"source_git_blob_sha":"verified separately via GitHub tree",
      "scanned_utc":datetime.now(timezone.utc).isoformat(),
      "total_files":len(inv),"types":dict(bytype),"root_files":sum(1 for x in inv if x["scope"]=="rootfs" and x["type"]=="file"),
      "control_files":sum(1 for x in inv if x["scope"]=="control" and x["type"]=="file"),
      "macho_slice_count":len(machos),"macho_count":len(set(x["path"] for x in machos)),"plist_count":len(plists),"images_count":len(images),
      "maintainer_scripts":script_paths,"tests":{"static_inspection":True,"installation":False,"device_test":False,"scripts_executed":False},
      "limitations":["Static inspection, not reconstruction of original source or runtime behavior.",
                     "Symbols and strings may be obfuscated or stripped; disassembly covers on-disk __TEXT,__text arm64 instructions.",
                     "No license bypass or patching; sensitive credential-like string values redacted in derived text; original DEB unmodified."]}
    js(DEST/"summary.json",summary)
    summary_text=(f"# CarPlayPro Speed 0.9.97 — complete static DEB inventory\n\n"
      f"Original: \`{summary['source_path']}\` on \`Duoface/main\`. SHA256: \`{summary['source_sha256']}\`.\n\n"
      f"Extracted {summary['root_files']} regular payload files and {summary['control_files']} control files; "
      f"{len(set(x['path'] for x in machos))} Mach-O binaries / {len(machos)} arm64(+arm64e) architecture slices; {len(plists)} decoded plists; {len(images)} identified images.\n\n"
      "The \`unpacked/\` tree preserves all package payload and Debian control file bytes. "
      "\`inventory.json\` and \`SHA256SUMS.txt\` record every file, mode, symlink and digest. "
      "\`macho/\` holds every recognized binary's load commands, imported dylibs, RPATHs, segments, sections, UUID, "
      "symbol table, function starts, section strings (including ObjC methods/classes), and full offset-tagged ASCII/UTF16 strings in gzip. "
      "\`disassembly/\` contains full static arm64 \`__text\` instruction listings when Capstone available. "
      "\`plists-decoded.json\`, \`images.json\`, \`archive-members.txt\`, \`control-fields.txt\` and "
      "\`package-info.txt\` preserve other machine-readable evidence.\n\n"
      "**Important:** read-only static audit. No installer scripts run; no iPhone/CarPlay device proof; no proprietary source recovered; "
      "no license/copy-protection alterations. Runtime-only behavior, encrypted code and stripped symbols cannot be guaranteed exhaustively.\n\n"
      "Regenerate from root: \`python3 -m pip install capstone==5.0.6 && python3 sideplay/tools/audit_carplaypro_0997.py --replace\`.\n")
    put(DEST/"README.md",summary_text)
    print(json.dumps(summary,ensure_ascii=False,sort_keys=True,indent=2))
if __name__=="__main__":main()
