#!/usr/bin/env python3
"""Read-only forensic inventory of archived rootless DEBs.

Three-way audit: installed SidePlay runtime, QA8 overlay addon, and approved
Native12+Speed8 Compact. Never executes package maintainer scripts/binaries.
Writes SHA-256 for EVERY extracted regular file and extracts symbol/ObjC/asset
evidence for an auditable comparison. macOS runner: dpkg-deb, file, otool, lipo,
strings, nm. Does not claim runtime functionality or source equivalence.
"""
from __future__ import annotations
import argparse
import collections
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile

PREFIXES=("CB","DF","SP","DuoFace","SidePlay")
KEYS=("carplay","dashboard","window","scene","split","divider","ratio",
      "pill","picker","layout","hud","speed","zoom","dock","overlay",
      "bridge","menu","style","license","trial","expiry","gesture")
EXCLUDE_UI_FILES=(".DS_Store",)
META_FIELDS=("Package","Version","Architecture","Depends","Conflicts",
             "Replaces","Provides","Description","Name","Maintainer")

def cmd(*args,timeout=120):
    try:
        p=subprocess.run([str(x) for x in args],capture_output=True,
                         text=True,errors="replace",timeout=timeout)
        return {"returncode":p.returncode,"stdout":p.stdout[:300000],
                "stderr":p.stderr[:4000]}
    except (OSError,subprocess.TimeoutExpired) as e:
        return {"returncode":127,"stdout":"","stderr":str(e)}

def hashfile(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda:f.read(1024*1024),b""):h.update(b)
    return h.hexdigest()

def select_symbols(text):
    tokens=set()
    for line in text.splitlines():
        if "OBJC_CLASS_$_" in line or "OBJC_METACLASS_$_" in line:
            for token in re.findall(r"OBJC_(?:META)?CLASS_\$_[A-Za-z_$][\w$]{2,110}",line):
                tokens.add(token.split("_$_",1)[-1])
    return sorted(tokens)

def strings_analysis(path):
    results=cmd("strings","-a",path)
    records=set(); kinds=collections.Counter()
    for line in results["stdout"].splitlines():
        value=line.strip()
        if not 4<=len(value)<=130 or not value.isascii():continue
        if not re.fullmatch(r"[A-Za-z_+\-][\w.$:/+\-\[\] ()]{3,129}",value):
            continue
        lo=value.lower()
        if value.startswith(PREFIXES) or any(k in lo for k in KEYS):
            records.add(value)
            kinds["class_prefix" if value.startswith(PREFIXES) else "topic"]+=1
    # The raw limited string list is forensic evidence, not decompiled code.
    return {"sampled_strings":sorted(records)[:1800],
            "selected_count":len(records),"counts":dict(kinds),
            "strings_tool_rc":results["returncode"]}

def native_binary_info(path):
    info={"file":cmd("file","-b",path)["stdout"].strip(),
          "lipo_archs":cmd("lipo","-archs",path)["stdout"].strip(),
          "linked_libraries":[],"objc_class_exports":[]}
    linked=cmd("otool","-L",path)
    if linked["returncode"]==0:
        info["linked_libraries"]=[x.strip() for x in linked["stdout"].splitlines()[1:]]
    nm=cmd("nm","-a",path)
    info["objc_class_exports"]=select_symbols(nm["stdout"])
    info["nm_rc"]=nm["returncode"]
    info.update(strings_analysis(path))
    return info

def file_type(path):
    with path.open("rb") as f:magic=f.read(8)
    if magic[:4] in (bytes.fromhex("feedfacf"),bytes.fromhex("cffaedfe"),
                     bytes.fromhex("cafebabe"),bytes.fromhex("bebafeca"),
                     bytes.fromhex("cafebabf"),bytes.fromhex("bfbafeca")):
        return "macho"
    lo=path.name.lower()
    if lo.endswith(".png"):return "png"
    if lo.endswith(".plist"):return "plist"
    if lo.endswith((".jpg",".jpeg",".webp",".heic")):return "image"
    if lo.endswith((".sh",".md",".py",".xm",".m",".h")):return "text"
    return "other"

def scan(label,deb,dest):
    deb=Path(deb)
    allroot=dest/label
    data=allroot/"payload"
    control=allroot/"control"
    data.mkdir(parents=True,exist_ok=True)
    control.mkdir(parents=True,exist_ok=True)
    a=cmd("dpkg-deb","-x",deb,data)
    b=cmd("dpkg-deb","-e",deb,control)
    if a["returncode"] or b["returncode"]:
        raise RuntimeError(label+" dpkg-deb: "+a["stderr"]+b["stderr"])
    fields={}
    for key in META_FIELDS:
        r=cmd("dpkg-deb","-f",deb,key)
        if r["returncode"]==0:fields[key]=r["stdout"].strip()
    files=[]; binary={}; plist={}
    kinds=collections.Counter()
    for path in sorted(data.rglob("*")):
        rel=path.relative_to(data).as_posix()
        if path.is_symlink():
            files.append({"path":rel,"type":"symlink",
                          "target":os.readlink(path)})
        elif path.is_file():
            kind=file_type(path)
            record={"path":rel,"type":kind,
                    "size":path.stat().st_size,"sha256":hashfile(path)}
            files.append(record);kinds[kind]+=1
            if kind=="macho":
                binary[rel]=native_binary_info(path)
            if kind=="plist":
                try:
                    v=plistlib.loads(path.read_bytes())
                    plist[rel]={"format":"apple-plist","keys":sorted(v) if isinstance(v,dict) else [],
                                "bundle":str(v.get("CFBundleIdentifier","")) if isinstance(v,dict) else ""}
                except Exception:
                    raw=path.read_text(errors="replace")
                    plist[rel]={"format":"openstep-or-unknown",
                                "filter_springboard":"com.apple.springboard" in raw,
                                "filter_uikit":"com.apple.UIKit" in raw,
                                "excerpt":raw[:400]}
    control_files={}
    for p in sorted(control.rglob("*")):
        if p.is_file():
            content=p.read_text(errors="replace")
            control_files[p.relative_to(control).as_posix()]={
                "sha256":hashfile(p),
                "size":p.stat().st_size,
                "header_lines":content.splitlines()[:12] if p.name=="control" else [],
                "maintainer_script_present":p.name in ("postinst","prerm","preinst","postrm")}
    report={"label":label,"source_deb":deb.name,"deb_size":deb.stat().st_size,
            "deb_sha256":hashfile(deb),"dpkg_fields":fields,
            "file_count":len(files),"type_counts":dict(kinds),
            "files":files,"binaries":binary,
            "plists":plist,"control_files":control_files}
    return report

def classify(name,part):
    x=name.lower()
    if any(s in x for s in ("speed","hud","bubble","gofa","waze","vietmap")):return "speed/HUD"
    if any(s in x for s in ("dock","chrome","fullscreen","zoom")):return "CarPlay chrome/zoom"
    if any(s in x for s in ("divider","grip","split","ratio")):return "divider/layout"
    if any(s in x for s in ("picker","pill","menu","chooser")):return "picker/pill/menu"
    if any(s in x for s in ("scene","bridge","host","dashboard")):return "app/scene host"
    if "license" in x or "lease" in x:return "license/lease"
    return "other"

def summarize(reports):
    lines=["# QA8 / Native12 HUD8 / SidePlay — static DEB byte inventory",
           "",
           "**Scope:** immutable DEB payloads from GitHub; EVERY regular file hashed.",
           "No executable code or maintainer scripts run. Mach-O introspection is",
           "class/symbol/linked-library/selected printable-string evidence only;",
           "it is NOT a full disassembly, runtime UI test or Native12 functional parity.",
           "", "## Identity and byte coverage", "",
           "| Name | Package / Version | Bytes | Extracted files | Mach-O | PNG | SHA-256 |",
           "|---|---|---:|---:|---:|---:|---|"]
    for label,r in reports.items():
        f=r["dpkg_fields"];k=r["type_counts"]
        lines.append(f"| {label} | `{f.get('Package','?')} {f.get('Version','?')}` | "
                     f"{r['deb_size']:,} | {r['file_count']} | {k.get('macho',0)} | "
                     f"{k.get('png',0)} | `{r['deb_sha256']}` |")
    lines+=["","## Three-way architecture distinction","",
            "QA8 is a separate SpringBoard overlay package and its control",
            "still Depends on com.sideplay. Native12 Speed8 Compact contains",
            "its own compiled DuoFace runtime payload. Package size and path",
            "differences alone are NOT proof a specific visible widget is removed.",
            "Legacy SidePlay payload is part of the actual QA8 installation;",
            "it must be included in any ownership/overlap assessment.","",
            "## Per binary, file paths and source-owned owner modules",""]
    for label,r in reports.items():
        lines.append(f"### {label}")
        lines.append("")
        for p,meta in r["binaries"].items():
            classes=meta["objc_class_exports"]
            candidate=[v for v in meta["sampled_strings"]
                       if v.startswith(PREFIXES) and " " not in v]
            lines.append(f"- `{p}` — {meta['file']}; archs `{meta['lipo_archs']}`; "
                         f"ObjC class exports {len(classes)}, relevant strings {meta['selected_count']}.")
            if classes:lines.append("  - class exports: "+", ".join("`"+c+"`" for c in classes[:30]))
            if candidate:lines.append("  - string examples: "+", ".join("`"+c+"`" for c in candidate[:35]))
        lines.append("")
        lines.append("Plist filters and packaging scripts: "+
                     ", ".join("`"+p+"`" for p in r["plists"]) + ".")
        lines.append("")
    lines+=["## Machine-readable evidence","",
            "- `qa8.json`, `native12.json`, `sideplay104.json`: full file path/size/hash manifest, Mach-O linked libs/class exports/relevant string samples, plist summaries and maintainer script hash/presence.",
            "- No conclusions about live CarPlay chrome, pane input dispatch, or jailbreak injection without a device log.",
            "- Do not merge/publish any binary because this comparison exists.",
            ""]
    return "\n".join(lines)

def main():
    ap=argparse.ArgumentParser()
    for label in ("qa8","native12","sideplay104"):
        ap.add_argument("--"+label,required=True)
        ap.add_argument("--"+label+"-sha256",required=True)
    ap.add_argument("--out",required=True)
    a=ap.parse_args();out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
    reports={}
    with tempfile.TemporaryDirectory(prefix="duoface-deb-audit-") as temp:
        for label in ("qa8","native12","sideplay104"):
            p=Path(getattr(a,label));expected=getattr(a,label+"_sha256")
            got=hashfile(p)
            if got!=expected:raise RuntimeError(f"{label}: SHA mismatch expected {expected} got {got}")
            r=scan(label,p,Path(temp))
            reports[label]=r
            (out/(label+".json")).write_text(json.dumps(r,indent=2,ensure_ascii=False)+"\n")
    (out/"REPORT.md").write_text(summarize(reports))
    print("DEB_AUDIT_ALL_3_CHECKSUMS_AND_FILE_MANIFESTS_PASS")
    for label,r in reports.items():
        print(label,r["dpkg_fields"].get("Package"),r["dpkg_fields"].get("Version"),
              r["deb_size"],r["file_count"],r["type_counts"],
              r["deb_sha256"])

if __name__=="__main__":main()
