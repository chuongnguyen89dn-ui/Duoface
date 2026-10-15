#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Byte-level DuoFace brand audit of an actual DEB.

Search ALL archive members, control scripts, binary bytes, symlink targets and
tar entry names. Track both ASCII and UTF-16 LE/BE; no unsafe execution.
The matcher deliberately does not assume GNU strings can see every occurrence.
"""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import io
import json
import pathlib
import re
import subprocess
import tarfile

BRANDS=(("duonavi","DuoNavi"),("airaw","Airaw"))
LICENSE_TERMS=(b"license",b"licence",b"expiry",b"expiration",b"trial",b"subscription",b"duoface pro",b"activation")
ENCODINGS=("ascii","utf16-le","utf16-be")

def patterns():
    for target,name in BRANDS:
        for encoding in ENCODINGS:
            b=target.encode({"ascii":"ascii","utf16-le":"utf-16-le","utf16-be":"utf-16-be"}[encoding])
            # Full ASCII case-insensitivity and UTF16 case-insensitivity
            # through alternation between ASCII letters; avoid decode errors.
            chunks=[]
            for ch in target:
                opts=bytes((ord(ch.lower()),ord(ch.upper()))) if ch.isalpha() else bytes((ord(ch),))
                if encoding=="ascii":
                    chunks.append(b"["+re.escape(opts)+b"]")
                elif encoding=="utf16-le":
                    chunks.append(b"["+re.escape(opts)+b"]\\x00")
                else:
                    chunks.append(b"\\x00["+re.escape(opts)+b"]")
            yield name,encoding,re.compile(b"".join(chunks),re.DOTALL)

def hits(data:bytes,limit=80):
    matches=[]
    for name,encoding,regex in patterns():
        total=0
        offsets=[]
        for m in regex.finditer(data):
            total+=1
            if len(offsets)<limit:offsets.append(m.start())
        if total:
            matches.append({"brand":name,"encoding":encoding,"count":total,"offsets_hex":[hex(o) for o in offsets],
                            "offsets_truncated":total>limit})
    return matches

def inspect_tar(data:bytes,kind:str):
    files=[]
    with tarfile.open(fileobj=io.BytesIO(data),mode="r:") as tar:
        for m in tar:
            if m.name in (".","./"):continue
            entry={"path":m.name,"kind":"file" if m.isfile() else "symlink" if m.issym() else "dir" if m.isdir() else "other",
                   "size":m.size,"mode":oct(m.mode),"brand_hits_in_name":hits(m.name.encode("utf-8"))}
            if m.issym() or m.islnk():
                entry["target"]=m.linkname
                entry["brand_hits_in_target"]=hits(m.linkname.encode("utf-8"))
            if m.isfile():
                fh=tar.extractfile(m)
                if fh is None:raise ValueError(f"Cannot read {kind}: {m.name}")
                content=fh.read()
                entry["sha256"]=hashlib.sha256(content).hexdigest()
                entry["brand_hits_in_bytes"]=hits(content)
                if kind=="data":
                    entry["license_keyword_counts"]={t.decode():len(re.findall(re.escape(t),content,re.IGNORECASE))
                                                     for t in LICENSE_TERMS if t in content.lower()}
            files.append(entry)
    return files

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--deb",type=pathlib.Path,required=True)
    parser.add_argument("--out",type=pathlib.Path,required=True)
    args=parser.parse_args()
    if not args.deb.exists():raise FileNotFoundError(args.deb)
    result={"source_deb":str(args.deb),"sha256":hashlib.sha256(args.deb.read_bytes()).hexdigest(),
            "source_bytes":args.deb.stat().st_size}
    for kind,arg in (("data","--fsys-tarfile"),("control","--ctrl-tarfile")):
        blob=subprocess.check_output(["dpkg-deb",arg,str(args.deb)])
        result[kind+"_entries"]=inspect_tar(blob,kind)
    result["deb_control"]={key:subprocess.check_output(["dpkg-deb","-f",str(args.deb),key],text=True).strip()
                           for key in ("Package","Version","Architecture")}
    totals=Counter()
    affected=[]
    license_affected=[]
    for k in ("data_entries","control_entries"):
        for entry in result[k]:
            hits_here=[]
            for hkey in ("brand_hits_in_name","brand_hits_in_target","brand_hits_in_bytes"):
                for h in entry.get(hkey,[]):
                    totals[f'{h["brand"]} ({h["encoding"]})']+=h["count"]
                    hits_here.append({"place":hkey,**h})
            if hits_here:
                affected.append({"section":k,"path":entry["path"],"matches":hits_here,
                                 "size":entry["size"],"sha256":entry.get("sha256")})
            if entry.get("license_keyword_counts"):
                license_affected.append({"section":k,"path":entry["path"],
                                         "counts":entry["license_keyword_counts"]})
    report={
        "status":"NATIVE_DEB_FULL_BYTE_BRAND_AUDIT",
        "sha256":result["sha256"],"source_bytes":result["source_bytes"],
        "control":result["deb_control"],
        "data_entries":len(result["data_entries"]),
        "control_entries":len(result["control_entries"]),
        "total_detected_by_brand_encoding":dict(totals),
        "affected_paths":affected,
        "license_keyword_audit":license_affected,
        "all_data_path_sha256":{x["path"]:x["sha256"] for x in result["data_entries"] if x.get("sha256")},
        "all_control_path_sha256":{x["path"]:x["sha256"] for x in result["control_entries"] if x.get("sha256")},
        "strict_byte_level_zero_matches":not affected,
        "scope":"all DEB tar entries names, symlink targets, file contents, ASCII and UTF16 LE/BE",
        "not_claimed":"String rename does not prove absence of code behaviors/dependencies without testing",
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,ensure_ascii=False,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print(json.dumps({
        "status":report["status"],"source":str(args.deb),
        "totals":report["total_detected_by_brand_encoding"],
        "affected_paths":[x["path"] for x in affected],
        "strict_zero":report["strict_byte_level_zero_matches"],
    },ensure_ascii=False,indent=2))
if __name__=="__main__":main()
