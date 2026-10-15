#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Native7 STAGED HIDE: user-visible license/subscription copy only.

39 explicitly audited NUL-terminated strings x2 binaries: replace with spaces
of identical byte count, retaining original terminators/pointers/selector/keys.
CarPlay hosts, runtime lifecycle, and every instruction remain untouched.
Native6 remains the immutable rollback; native7 is NOT physical deletion.
"""
from __future__ import annotations
import argparse, hashlib, json, subprocess, tempfile
from pathlib import Path
from build_native5 import FILES, sections, preserve_entitlements_and_resign, sha, cmd
from audit_branding import hits

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"dist/payload-migration/native6/com.duoface.independent_0.1.0~native6_iphoneos-arm64.deb"
EXPECTED="88b0e9358c075e2131ddb9e6ac25689584765d1285120e2e3282ce8a5bb3df15"
AUDIT=ROOT/"audit/payload-migration/NATIVE6_REMAINING_LICENSE_READONLY.json"
VERSION="0.1.0~native7"
# Only whole, visually presentable labels; all data keys, log tags, class names,
# ObjC selectors, synchronization identifiers and CarPlay control copy excluded.
UI_COPY=[
    "Connect to CarPlay to start your %ld-day free trial, or choose a plan below to activate.",
    "Connect to CarPlay for a free trial, or choose a plan below to activate.",
    "OR REDEEM GIFTCODE",
    "%ld-day trial ($0)",
    "Enter giftcode...",
    "Please enter a giftcode before activating.",
    "Giftcode is invalid or already used.",
    "Activated Successfully!",
    "DuoFace Pro license activated. All CarPlay multitasking features are ready to use!",
    "Awaiting Payment",
    "Order Expired",
    "Activate Now",
    "Lifetime license on this device.",
    "Connect to CarPlay to start your %ld-day free trial, or select a plan below.",
    "Connect to CarPlay to start your free trial, or select a plan below.",
    "Resume Pending Payment Page",
    "Enter activation code from your reseller or direct purchase:",
    "Don't have a code? Contact your reseller or support team for quick activation.",
    "Enter activation code...",
    "Reopen Payment Page",
    "Please enter an activation code before continuing.",
    "Activation code is invalid or already used.",
    "License Sync Incomplete",
    "DuoFace Pro license activated successfully. Connect to CarPlay to enjoy multitasking!",
    "Unable to load subscription plans. Please check your network connection and try again.",
    "Loading subscription plans...",
    "License Duration",
    "Licencia no activada",
    "Licencia caducada",
    "Guarda este ID de dispositivo para transferir tu licencia a otro equipo (hasta 10 veces).",
    "Estado de licencia",
    "Entrez le code d'activation de votre revendeur ou du support :",
    "Expiration serveur",
    "Statut de licence",
    "Voer activatiecode van verkoper of ondersteuning in:",
    "Licencja nieaktywna",
    "Licencja nieaktywowana",
    "Okres licencji",
    "Status licencji"
]


def mask_selected(name, before, catalog):
    targets=[x for x in catalog if x["display_literal"] in UI_COPY]
    assert len(targets)==len(UI_COPY)==39, (name,len(targets))
    assert {x["display_literal"] for x in targets}==set(UI_COPY)
    segmap={(seg,sec):(off,off+size) for seg,sec,off,size in sections(before)}
    data=bytearray(before)
    records=[]
    for row in targets:
        start=row["file_offset"]
        size=row["byte_count"]
        stop=start+size
        sec=row["section"]
        assert sec=="__cstring"
        assert any(key[1]==sec and lo<=start<stop<=hi for key,(lo,hi) in segmap.items())
        old=bytes(data[start:stop])
        assert old==row["display_literal"].encode("utf-8")
        assert sha(old)==row["sha256"]
        assert data[stop:stop+1]==b"\x00"
        assert data[start-1:start] in (b"\x00",b"") # whole C string
        replacement=b" "*size
        assert len(old)==len(replacement)
        data[start:stop]=replacement
        records.append({
            "binary":name,"label":row["display_literal"],"file_offset":start,
            "byte_count":size,"native6_sha256":sha(old),
            "native7_sha256":sha(replacement),"section":"__cstring",
            "state":"temporarily_hidden_native7",
        })
    pairs=sorted((x["file_offset"],x["file_offset"]+x["byte_count"]) for x in records)
    assert all(a[1]<=b[0] for a,b in zip(pairs,pairs[1:]))
    return bytes(data),records


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,required=True)
    ap.add_argument("--report",type=Path,required=True)
    args=ap.parse_args()
    assert sha(SOURCE.read_bytes())==EXPECTED
    audit=json.loads(AUDIT.read_text())
    assert audit["native6_sha256"]==EXPECTED and audit["raw_deb_unchanged"]
    assert len(UI_COPY)==len(set(UI_COPY))==39
    records=[]
    signs={}
    with tempfile.TemporaryDirectory(prefix="duoface-native7-") as temp:
        temp=Path(temp)
        stage=temp/"stage"
        cmd("dpkg-deb","-R",SOURCE,stage)
        prior={p.relative_to(stage).as_posix():sha(p.read_bytes())
               for p in stage.rglob("*") if p.is_file() and not p.is_symlink()}
        for name,rel in FILES.items():
            p=stage/rel
            original=p.read_bytes()
            revised,changed=mask_selected(name,original,audit["binaries"][name]["strings"])
            assert len(revised)==len(original)
            p.write_bytes(revised)
            signs[name]=preserve_entitlements_and_resign(p,original,temp,name)
            assert not hits(p.read_bytes())
            records.extend(changed)
        assert len(records)==78
        control=stage/"DEBIAN/control"
        c=control.read_text()
        assert "Package: com.duoface.independent" in c
        assert "Version: 0.1.0~native6" in c
        control.write_text(c.replace("Version: 0.1.0~native6","Version: "+VERSION))
        md5sums=[]
        for p in sorted(stage.rglob("*")):
            if p.is_file() and not p.is_symlink() and p.relative_to(stage).parts[0]!="DEBIAN":
                md5sums.append(hashlib.md5(p.read_bytes()).hexdigest()+"  "+p.relative_to(stage).as_posix())
        (stage/"DEBIAN/md5sums").write_text("\n".join(md5sums)+"\n")
        after={p.relative_to(stage).as_posix():sha(p.read_bytes())
               for p in stage.rglob("*") if p.is_file() and not p.is_symlink()}
        changed_paths=sorted(k for k in prior if prior[k]!=after[k])
        assert prior.keys()==after.keys()
        assert changed_paths==sorted([*FILES.values(),"DEBIAN/control","DEBIAN/md5sums"])
        args.out.parent.mkdir(parents=True,exist_ok=True)
        cmd("dpkg-deb","--build","--root-owner-group",stage,args.out)
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Version"],text=True).strip()==VERSION
    report={
      "status":"NATIVE7_ONLY_STATIC_UI_COPY_STAGED_HIDE_NEEDS_DEVICE_TEST",
      "source_native6_sha256":EXPECTED,"package":"com.duoface.independent",
      "version":VERSION,"presentation_labels_masked":39,
      "presentation_literal_occurrences_masked":len(records),
      "presentation_bytes_masked":sum(x["byte_count"] for x in records),
      "masks":records,"changed_paths":changed_paths,
      "unchanged_all_other_payload_files":len(prior)-len(changed_paths),
      "machine_code_changed":False,"objc_metadata_or_keys_changed":False,
      "carplay_host_and_screen_detection_changed":False,
      "lifecycle_changed":False,"license_full_removal":False,
      "signatures":signs,"native6_rollback_preserved":True,
      "device_tested":False,"sileo_published":False,
      "deb_sha256":sha(args.out.read_bytes()),"deb_size":args.out.stat().st_size}
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps({k:v for k,v in report.items() if k!="masks"},indent=2,ensure_ascii=False))
if __name__=="__main__":main()
