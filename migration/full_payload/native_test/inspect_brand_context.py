#!/usr/bin/env python3
"""Read-only context of the original legacy brand identifiers in native2.

Only displays bounded textual contexts around known static brand names. Results
inform safe renames and distinguish UI strings from internal ABI identifiers.
"""
import argparse
import io
import json
import pathlib
import re
import subprocess
import tarfile
from audit_branding import patterns

def string_context(blob:bytes,offset:int,encoding:str):
    if encoding=="ascii":
        lo=offset
        while lo>0 and blob[lo-1] in range(32,127) and offset-lo<120:lo-=1
        hi=offset
        while hi<len(blob) and blob[hi] in range(32,127) and hi-offset<130:hi+=1
        return blob[lo:hi].decode("utf-8","replace")
    unit_encoding="utf-16-le" if encoding=="utf16-le" else "utf-16-be"
    def get_char(pos):
        if pos<0 or pos+2>len(blob):return None
        ch=blob[pos:pos+2].decode(unit_encoding,"replace")
        return ch if ch.isprintable() and ch!="\ufffd" else None
    left=offset
    for _ in range(85):
        if get_char(left-2) is None:break
        left-=2
    right=offset
    for _ in range(90):
        if get_char(right) is None:break
        right+=2
    return blob[left:right].decode(unit_encoding,"replace")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    args=ap.parse_args()
    raw=subprocess.check_output(["dpkg-deb","--fsys-tarfile",str(args.deb)])
    contexts=[]
    with tarfile.open(fileobj=io.BytesIO(raw)) as tar:
        for entry in tar:
            if not entry.isfile():continue
            blob=tar.extractfile(entry).read()
            for brand,enc,pattern in patterns():
                matches=list(pattern.finditer(blob))
                if not matches:continue
                examples=[]
                seen=set()
                for match in matches:
                    if len(examples)>=22:break
                    val=string_context(blob,match.start(),enc)
                    if not val or val in seen:continue
                    seen.add(val)
                    examples.append({"offset_hex":hex(match.start()),"surrounding_static_string":val[:260]})
                contexts.append({"file":entry.name,"brand":brand,"encoding":enc,
                                 "match_count":len(matches),"distinct_static_contexts":examples})
    obj={"status":"READONLY_NATIVE2_BRAND_CONTEXT","files":contexts}
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+"\n")
    for entry in contexts:
        print(json.dumps({"file":entry["file"],"brand":entry["brand"],
                          "encoding":entry["encoding"],"total":entry["match_count"],
                          "sample_strings":entry["distinct_static_contexts"][:8]},ensure_ascii=False))
if __name__=="__main__":main()
