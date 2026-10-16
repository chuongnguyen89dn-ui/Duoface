#!/usr/bin/env python3
"""Read-only forensic audit of Lite / Zingalo ghost cards in exact DuoFace native12.
No modified DEB, no on-device application or preference data is accessible here.
"""
from __future__ import annotations
import argparse, hashlib, json, plistlib, re, subprocess, tempfile
from pathlib import Path
from audit_native12_license_class_xrefs import MachO, select_arm64
from audit_native12_carplay_add_app_chain import methods, disassemble

EXPECTED_DEB = "85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
EXPECTED_BINARY_SHA = {
    "DuoFaceUI": "cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
    "DuoFaceDashboard": "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
}
TARGET_METHODS = {
    "CBMultitaskingOverlayView": (
        "loadInstalledApps",
        "setupAppPickerCardsInCardW:cardH:contentY:",
        "appSelected:",
    ),
    "CBDashboardSettings": ("reloadAppPrefs", "bridgedApps", "setBridgedApps:"),
    "CBBridgeManagerDashboard": ("bridgedApps",),
}
TEXT_CANDIDATE_RE = re.compile(r"\b(lite|zingalo)\b", re.I)
DATA_KEYS = ("bridgedApps", "appSettings", "com.duonavi", "com.duoface")
def sha256(data: bytes) -> str: return hashlib.sha256(data).hexdigest()

def scan_bytes(data: bytes, max_hits: int = 70) -> list[dict]:
    results = []
    for enc, pattern in (
        ("ascii", re.compile(rb"(?<![A-Za-z])(?:lite|zingalo)(?![A-Za-z])", re.I)),
        ("utf16le", re.compile(rb"(?:l\x00i\x00t\x00e\x00|z\x00i\x00n\x00g\x00a\x00l\x00o\x00)", re.I)),
    ):
        for match in pattern.finditer(data):
            lo=max(0,match.start()-50)
            hi=min(len(data),match.end()+50)
            neighborhood=data[lo:hi]
            ctx=neighborhood.decode("utf-16le" if enc=="utf16le" else "utf-8", errors="replace")
            results.append({"encoding":enc, "offset":match.start(), "match":match.group().decode(
                "utf-16le" if enc=="utf16le" else "ascii",errors="replace"), "context":ctx[:120]})
            if len(results)>=max_hits: break
    return results

def inspect_saved_resources(root: Path) -> dict:
    found={}
    relevant={}
    for p in sorted(root.rglob("*")):
        if not p.is_file() or p.is_symlink(): continue
        rel=p.relative_to(root).as_posix()
        if "DEBIAN/" in rel or p.stat().st_size>15_000_000: continue
        data=p.read_bytes()
        hits=scan_bytes(data)
        if hits:found[rel]={"count":len(hits),"hits":hits[:30]}
        if p.suffix.lower()==".plist":
            try:
                obj=plistlib.loads(data)
                s=str(obj)
                if any(k.lower() in s.lower() for k in DATA_KEYS) or "lite" in s.lower() or "zingalo" in s.lower():
                    # Packaged templates/config are public, never device preferences.
                    relevant[rel]={"keys":list(obj.keys())[:40] if isinstance(obj,dict) else [],
                                   "has_bridgedApps":"bridgedApps" in s,
                                   "has_lite":bool(TEXT_CANDIDATE_RE.search(s) and "lite" in s.lower()),
                                   "has_zingalo":"zingalo" in s.lower()}
            except (ValueError,TypeError,plistlib.InvalidFileException):pass
    return {"literal_occurrences_in_packaged_files":found,
            "packaged_plist_references":relevant}

def inspect_dashboard(path:Path) -> dict:
    binary=path.read_bytes()
    actual_digest=sha256(binary)
    assert actual_digest==EXPECTED_BINARY_SHA["DuoFaceDashboard"], "Dashboard SHA differs from signed native12"
    print("DASHBOARD_NATIVE12_BYTE_HASH_VERIFIED",actual_digest)
    m=MachO(select_arm64(binary))
    classes=m.classes()
    result={}
    for cname, selectors in TARGET_METHODS.items():
        assert cname in classes, cname
        all_methods=methods(m,cname)
        entries=sorted((v["vm"],k) for k,v in all_methods.items() if v["vm"])
        for selector in selectors:
            met=all_methods.get("-"+selector) or all_methods.get("+"+selector)
            assert met, (cname,selector)
            start=met["vm"]
            end=next((loc for loc,k in entries if loc>start),start+2400)
            asm=disassemble(m,start,end)
            relevant=[line for line in asm if any(word in line.lower() for word in (
                "app", "bridge", "bundl", "icon", "pref", "name", "identif",
                "proxy", "worksp", "array", "dictionary", "selector", "sort", "filter"))]
            result[f"{cname}.{selector}"]={
                "start":hex(start), "end":hex(end),
                "disassembly_instruction_count":len(asm),
                "selected_instructions":relevant[:120],
                "first_60_instructions":asm[:60],
            }
    return result

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",required=True,type=Path)
    ap.add_argument("--out",required=True,type=Path)
    args=ap.parse_args()
    data=args.deb.read_bytes()
    assert sha256(data)==EXPECTED_DEB,"Not the immutable, user-tested native12"
    assert subprocess.check_output(["dpkg-deb","-f",str(args.deb),"Version"],text=True).strip()=="0.1.0~native12"
    with tempfile.TemporaryDirectory() as td:
        root=Path(td)
        subprocess.run(["dpkg-deb","-x",str(args.deb),str(root)],check=True)
        ui=root/"var/jb/Applications/DuoFaceUI.app/DuoFaceUI"
        dashboard=root/"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
        assert sha256(ui.read_bytes())==EXPECTED_BINARY_SHA["DuoFaceUI"]
        report={
            "status":"NATIVE12_LITE_ZINGALO_GHOST_TILES_READONLY_AUDIT",
            "package":"com.duoface.independent",
            "version":"0.1.0~native12",
            "exact_deb_sha256":sha256(data),
            "device_preferences_read":False,
            "installed_app_inventory_read":False,
            "source_warning":"Static DEB and code only; cannot prove which bundle IDs are in device bridgedApps.",
            "packaged":inspect_saved_resources(root),
            "dashboard_app_list_methods":inspect_dashboard(dashboard)
        }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print("NATIVE12_LITE_ZINGALO_READONLY_DEB_AND_APP_LIST_METHODS_PASS")
    print("PACKAGED_NAME_MATCHING_FILES",list(report["packaged"]["literal_occurrences_in_packaged_files"]))
    for key,m in report["dashboard_app_list_methods"].items():
        print("METHOD",key,m["start"],"instructions",m["disassembly_instruction_count"])
    print("DEVICE_PREFS_NOT_ACCESSED_ONLY_STATIC_AUDIT")
if __name__=="__main__":main()
