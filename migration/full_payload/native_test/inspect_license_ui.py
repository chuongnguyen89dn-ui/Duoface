#!/usr/bin/env python3
"""Read-only audit of user-visible date/license surfaces in original DuoFace UI.

Do not dump license payloads, device identifiers, tokens, URL query strings, or binaries.
Use this report to target only obsolete settings rows without altering split host/UI.
"""
from __future__ import annotations
import argparse, hashlib, json, pathlib, re, subprocess, tempfile

SOURCE_SHA="ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a"
MATCH=re.compile(r"licen[sc]|trial|expir|subscription|activation|activat|remaining|validity|duration|period|entitl|prostatus|giay.phep|thoi.han|ngay.su.dung|con.lai", re.I)
SAFE=re.compile(r"^[\x20-\x7e]{3,145}$")
def run(args: list[str]) -> str:
    p=subprocess.run(args, capture_output=True, text=True, errors="replace")
    if p.returncode!=0:
        raise RuntimeError(f"command failed: {args[0]} ({p.returncode}): {p.stderr[-350:]}")
    return p.stdout
def scan(file: pathlib.Path):
    raw=file.read_bytes()
    groups=[]
    for s in re.findall(rb"[\x20-\x7e]{4,150}",raw):
        t=s.decode("ascii",errors="ignore")
        if MATCH.search(t) and SAFE.fullmatch(t):
            if "://" in t or "token" in t.lower() or "secret" in t.lower() or "uuid" in t.lower():
                continue
            if t not in groups: groups.append(t)
    # Raw Objective-C runtime object metadata; just record names matching the subject.
    met=run(["xcrun","otool","-oV",str(file)])
    metadata=[]
    for line in met.splitlines():
        t=line.strip()
        if MATCH.search(t) and len(t)<200 and "://" not in t:
            if t not in metadata: metadata.append(t)
    classes=list(dict.fromkeys(re.findall(r"_OBJC_CLASS_\$_([A-Za-z_][A-Za-z_0-9]+)",met)))
    # Only target the app's settings and subscription UI. Native CarPlay menus
    # remain out of scope, with unmodified UIViewController classes.
    settings_classes=[n for n in classes if re.search(
        r"settings|home|subscription|license|main|profile|account",n,re.I)]
    details={}
    lines=met.splitlines()
    for cls in settings_classes[:30]:
        positions=[i for i,line in enumerate(lines) if "_OBJC_CLASS_$_"+cls in line]
        if not positions:continue
        anchor=positions[0]
        records=[]
        for line in lines[anchor:anchor+120]:
            t=line.strip()
            if re.match(r"^name\s+0x[0-9a-fA-F]+\s+",t):
                if len(t)<210 and "://" not in t:records.append(t)
        details[cls]=records[:80]
    return {
        "objc_classes":classes,
        "settings_candidate_classes":settings_classes,
        "settings_candidate_method_names":details,
        "sha256":hashlib.sha256(raw).hexdigest(),
        "matching_ascii_strings":groups[:200],
        "matching_objc_metadata_lines":metadata[:180],
        "matching_string_count":len(groups),
        "matching_metadata_line_count":len(metadata),
    }
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=pathlib.Path,required=True)
    ap.add_argument("--output",type=pathlib.Path,required=True)
    args=ap.parse_args()
    assert hashlib.sha256(args.deb.read_bytes()).hexdigest()==SOURCE_SHA
    with tempfile.TemporaryDirectory() as d:
        root=pathlib.Path(d)/"root"
        run(["dpkg-deb","-x",str(args.deb),str(root)])
        base=root/"var/jb"
        result={}
        for r in ("Applications/DuoFaceUI.app/DuoFaceUI",
                  "Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"):
            result[r]=scan(base/r)
    output={
        "status":"READ_ONLY_ORIGINAL_SETTINGS_LICENSE_SURFACE_AUDIT",
        "source_sha256":SOURCE_SHA,
        "binaries":result,
        "source_modified":False,
        "device_tested":False,
        "next":"Use real Objective-C class/selector evidence to remove only license/date UI, never rewrite native CarPlay menu.",
    }
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(output,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps({k:{"strings":v["matching_string_count"],"objc_lines":v["matching_metadata_line_count"]} for k,v in result.items()},indent=2))
if __name__=="__main__":main()
