#!/usr/bin/env python3
"""Read-only exact-string and localization-key scan of the RELEASED native17 DEB.

Purpose: Prove if the Vietnamese 'Dừng xe an toàn...' literal is EMBEDDED
in package bytes or reached via ADD_MORE_APPS_ALERT_MSG lookup. Never edit
binary payloads or infer that a hook is active from static strings.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unicodedata

PACKAGE_SHA = "60f8a4277dd9df912036f93fc8edfd0897a516752f3014863459d5ce89ad5fff"
DASH = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
UI = "var/jb/Applications/DuoFaceUI.app/DuoFaceUI"
PICKER = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceInCarAddApps.dylib"
EXPECTED = {
    DASH: "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
    UI: "cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
    PICKER: "d0246415f4020f353e5ec7373d8d375cbbda868471fd1a467f8e57654c4d01ad",
}
KEYS = ["ADD_MORE_APPS_ALERT_MSG", "ADD_MORE_APPS_ALERT_TITLE", "ADD_MORE_APPS_ALERT_OK",
        "addMoreAppsTapped:", "localizedStringForKey:"]
PHRASES = [
    "Dừng xe an toàn",
    "Dừng xe an toàn và mở DuoFace trên iPhone để chọn thêm ứng dụng",
    "mở DuoFace trên iPhone",
    "Thêm Ứng Dụng",
    "Đã hiểu",
]
def sha(b: bytes) -> str: return hashlib.sha256(b).hexdigest()

def search(data: bytes, pattern: bytes) -> list[int]:
    indexes=[]; offset=0
    while len(indexes)<25:
        i=data.find(pattern,offset)
        if i<0: break
        indexes.append(i);offset=i+1
    return indexes

def probes(data: bytes, term: str, unicode_variants=True) -> list[dict]:
    result=[]
    norms=["NFC","NFD"] if unicode_variants else ["NFC"]
    for form in norms:
        normalized=unicodedata.normalize(form,term)
        for enc in ("utf-8","utf-16-le","utf-16-be"):
            hits=search(data,normalized.encode(enc))
            if hits:result.append({"normalization":form,"encoding":enc,"file_offsets_hex":[hex(v) for v in hits]})
    return result

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--deb",type=Path,required=True)
    parser.add_argument("--out",type=Path,required=True)
    a=parser.parse_args()
    raw=a.deb.read_bytes()
    assert sha(raw)==PACKAGE_SHA, "Refuse unknown DEB version"
    with tempfile.TemporaryDirectory(prefix="duoface-native17-readonly-") as td:
        dest=Path(td)
        subprocess.run(["dpkg-deb","-x",str(a.deb),str(dest)],check=True)
        files=[p for p in dest.rglob("*") if p.is_file()]
        binaries={p:p.read_bytes() for p in files}
        for rel,expected in EXPECTED.items():
            assert sha(binaries[dest/rel])==expected, "Wrong underlying binary "+rel
        report={
            "status":"READONLY_NATIVE17_EMBEDDED_STRING_AND_LOCALIZATION_KEY_AUDIT",
            "package_sha256":PACKAGE_SHA,
            "package_entries_scanned":len(files),
            "verified_host_sha256":EXPECTED,
            "targets":{},
            "native12_original_selector":"CBMultitaskingOverlayView.addMoreAppsTapped:",
            "native12_original_imp_vm":"0xa7f20",
            "source_audit_ref":"audit/payload-migration/NATIVE12_CARPLAY_ADD_APP_CHAIN_READONLY.json",
            "device_tested":False,
            "binary_modified":False,
        }
        for term in KEYS+PHRASES:
            hits=[]
            for path,data in binaries.items():
                matches=probes(data,term,unicode_variants=(term in PHRASES))
                if matches:hits.append({"path":path.relative_to(dest).as_posix(),"patterns":matches})
            report["targets"][term]={"exact_package_byte_matches":hits}
        for key in KEYS[:3]:
            assert any(x["path"]==DASH for x in report["targets"][key]["exact_package_byte_matches"]),\
                "Original native12 dashboard key missing: "+key
        report["has_exact_vietnamese_safety_phrase_bytes"] = bool(
            report["targets"]["Dừng xe an toàn"]["exact_package_byte_matches"])
        report["key_housed_in"] = DASH
        report["meaning"] = ("Found direct UTF-8/UTF-16 Vietnamese bytes in package"
                             if report["has_exact_vietnamese_safety_phrase_bytes"] else
                             "Found localization key in original Dashboard, but exact Vietnamese bytes are absent from native17 DEB; runtime localizer or generated translations require separate investigation.")
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"status":report["status"],
       "package_entries_scanned":report["package_entries_scanned"],
       "has_exact_vietnamese_safety_phrase_bytes":report["has_exact_vietnamese_safety_phrase_bytes"],
       "targets":{k:{"files":[x["path"] for x in v["exact_package_byte_matches"]],
                     "offsets":{x["path"]:x["patterns"] for x in v["exact_package_byte_matches"]}}
                  for k,v in report["targets"].items()},
       "meaning":report["meaning"]},ensure_ascii=False,indent=2))

if __name__=="__main__":
    main()
