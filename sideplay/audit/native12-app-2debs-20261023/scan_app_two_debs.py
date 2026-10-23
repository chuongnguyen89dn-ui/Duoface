#!/usr/bin/env python3
"""Direct, read-only full-payload two-DEB inventory and App mode forensic test.
Original Native12+Speed8 versus signed independent DuoFace 0.0.41.
No binary execution, no vendor code copied, no output deployed.
"""
import argparse
import hashlib
import json
import pathlib
import plistlib
import re
import subprocess
import tempfile

ORIGINAL_SHA = "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
NEW_SHA = "da2275c2a9ef7efe8879a7121677d2771c809b78066b4552a2294d4b8a1715c2"
ORIGINAL_DASHBOARD_SHA = "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
MAGICS = {"cffaedfe", "cefaedfe", "cafebabe", "bebafeca", "cafebabf", "bfbafeca"}
APP_METHODS = [
    "initWithFrame:",
    "loadInstalledApps",
    "setupCardContent",
    "setupAppPickerCardsInCardW:cardH:contentY:",
    "appSelected:",
    "pageControlChanged:",
    "addMoreAppsTapped:",
    "switchToAppPickerMode",
    "showAppPickerForSlot:parentView:",
    "dismissOverlay",
]
APP_SELECTORS = [
    "CBMultitaskingOverlayView", "CBOverlayScrollView", "CBDashboardSettings",
    "CBBridgeManager", "loadInstalledApps", "gridCols", "gridRows",
    "hideIconLabels", "bundleIdentifier", "displayName", "icon",
    "appSelected:", "pageControlChanged:", "addMoreAppsTapped:",
    "switchToAppPickerMode", "showAppPickerForSlot:", "replaceAppInSlot:",
    "swapSlot:withSlot:", "setPagingEnabled:", "setContentOffset:animated:",
    "checkmark.circle.fill", "arrow.left.arrow.right.circle.fill",
    "square.stack.3d.up.slash", "OVERLAY_ADD_APP",
    "DFAppPickerVC", "DFAppLibrary", "LSApplicationWorkspace",
    "allInstalledApplications", "DFIsEligibleAppID", "App",
    "Apps", "Layout", "Recent", "Ứng dụng", "Bố cục", "Đang mở",
]
def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def read_text(p):
    return p.read_text(encoding="utf-8", errors="replace")

def shell(*args):
    cmd=subprocess.run(args, capture_output=True, text=True, errors="replace")
    if cmd.returncode:
        raise RuntimeError("FAILED: "+ " ".join(map(str, args)) + " " + cmd.stderr[-1800:])
    return cmd.stdout

def stat_payload(root):
    entries=[]
    for f in sorted(root.rglob("*")):
        if not f.is_file() or f.is_symlink():
            continue
        h=f.read_bytes()
        item={"path":f.relative_to(root).as_posix(), "bytes":len(h),
              "sha256":hashlib.sha256(h).hexdigest(),
              "macho":h[:4].hex() in MAGICS}
        if len(h)>24 and h.startswith(b"\x89PNG\r\n\x1a\n") and h[12:16]==b"IHDR":
            item["png"]={"width":int.from_bytes(h[16:20],"big"),
                         "height":int.from_bytes(h[20:24],"big"),
                         "color_type":h[25]}
        if f.suffix==".plist":
            try:
                a=plistlib.loads(h)
                if isinstance(a,dict):
                    item["plist"]={str(k):a[k] for k in ["CFBundleIdentifier",
                      "CFBundleExecutable","CFBundleDisplayName","Filter"] if k in a}
            except (TypeError, ValueError): pass
        entries.append(item)
    return entries

def extract_symbols(root):
    allfiles={}
    hits={term:[] for term in APP_SELECTORS}
    for f in sorted(root.rglob("*")):
        if not f.is_file() or f.is_symlink() or f.read_bytes()[:4].hex() not in MAGICS:
            continue
        rel=f.relative_to(root).as_posix()
        output=shell("strings","-a",str(f))
        allfiles[rel]={"bytes":f.stat().st_size, "sha256":digest(f),
                       "string_count":len(output.splitlines())}
        for term in APP_SELECTORS:
            if term in output:
                hits[term].append(rel)
    return allfiles,hits

def source_matrix(root):
    picks=[
        "sideplay/duoface-native-scene-host/DFAppPickerVC.m",
        "sideplay/duoface-native-scene-host/DFAppLibrary.m",
        "sideplay/duoface-native-scene-host/DFAppEligibility.m",
        "sideplay/duoface-native-scene-host/DFNative12Chrome.m",
    ]
    rx=re.compile(r"AppPicker|installedUserApps|installedIconForBundle|"
                  r"nativeModePressed|loadInstalledApps|presentInstalledApps|"
                  r"updateNativeModeButtons|cellForItemAtIndexPath|didSelectItemAtIndexPath|"
                  r"menuAction:|openAppPickerForSlot|source|gridCols|hideIconLabels|"
                  r"card\.icon|cardsPerPage|setTitleColor|modeButtons|"
                  r"alpha:\.96|layer\.cornerRadius=14")
    result={}
    for s in picks:
        file=root/s
        if not file.exists():
            result[s]={"present":False}
            continue
        lines=read_text(file).splitlines()
        hit=[{"line":i,"text":line.strip()} for i,line in enumerate(lines,1) if rx.search(line)]
        result[s]={"present":True,"git_source_sha256":digest(file),
                   "matched_lines":hit[:115]}
    return result

def main():
    p=argparse.ArgumentParser()
    for s in ("native12","new","original-imp","new-imp","repo-root","out"):
        p.add_argument("--"+s,required=True,type=pathlib.Path)
    a=p.parse_args()
    for path,expected in ((a.native12,ORIGINAL_SHA),(a.new,NEW_SHA)):
        actual=digest(path)
        if actual!=expected:
            raise SystemExit("ABORT: SHA256 failed "+str(path)+" "+actual)
    a.out.mkdir(parents=True,exist_ok=True)
    original_dis=json.loads(read_text(a.original_imp))
    extended=json.loads(read_text(a.new_imp))
    assert original_dis["dashboard_macho_sha256"]==ORIGINAL_DASHBOARD_SHA
    assert extended["dashboard_macho_sha256"]==ORIGINAL_DASHBOARD_SHA
    assert len(original_dis["methods"])>=14
    methods={}
    for group in (original_dis, extended):
        for x in group["methods"]:
            if x["class"]=="CBMultitaskingOverlayView":
                methods[x["selector"]]=x
    with tempfile.TemporaryDirectory() as tmp:
        base=pathlib.Path(tmp)
        old=base/"original";new=base/"independent"
        old.mkdir();new.mkdir()
        shell("dpkg-deb","-x",str(a.native12),str(old))
        shell("dpkg-deb","-x",str(a.new),str(new))
        inventories={"native12_original":stat_payload(old),
                     "duoface_0_0_41":stat_payload(new)}
        assert len(inventories["native12_original"])==43
        assert len(inventories["duoface_0_0_41"])==30
        oldb,olds=extract_symbols(old)
        newb,news=extract_symbols(new)
        original_dashboard=next((old/z for z in oldb if z.endswith("/DuoFaceDashboard.dylib")),None)
        assert original_dashboard and digest(original_dashboard)==ORIGINAL_DASHBOARD_SHA
        coverage={}
        for s in APP_SELECTORS:
            coverage[s]={"original_macho":olds[s],"independent_macho":news[s],
                         "same_string_not_proof_of_equivalent_behavior":True}
        method_audits=[]
        for sel in APP_METHODS:
            m=methods.get(sel)
            if m is None:
                method_audits.append({"selector":sel,"status":"NOT_EXTRACTED"})
                continue
            rows=m["instructions"]
            hints=[r for r in rows if ("Objc selector ref:" in r or "Objc cfstring ref:" in r)
                   and any(k in r for k in ["gridCols","gridRows","hideIconLabels",
                        "bundleIdentifier","displayName","icon","addMoreAppsTapped:",
                        "appSelected:","pageControlChanged:","setContentOffset:",
                        "checkmark.circle.fill","arrow.left.arrow.right.circle.fill",
                        "UIColor","setBackgroundColor:","setBorderColor:",
                        "setCornerRadius:","systemImageNamed:","setImage:"])]
            method_audits.append({"selector":sel,"imp":m["imp"],"end":m["end"],
                                  "objc_type":m["objc_type"],"arm64_insns":len(rows),
                                  "control_flow_branches":len(m.get("branch_sites",[])),
                                  "app_relevant_callsites":hints[:130]})
        summary={
           "classification":"READ_ONLY_TWO_ACTUAL_SIGNED_DEB_BINARY_SCAN_NOT_DEVICE_UI",
           "native12_deb_sha256":ORIGINAL_SHA,
           "independent_deb_sha256":NEW_SHA,
           "original_dashboard_sha256":ORIGINAL_DASHBOARD_SHA,
           "original_payload_file_count":len(inventories["native12_original"]),
           "independent_payload_file_count":len(inventories["duoface_0_0_41"]),
           "original_macho_count":len(oldb),
           "independent_macho_count":len(newb),
           "app_original_methods_extracted":len([x for x in method_audits if "imp" in x]),
           "original_4_5_6_grid_columns":"a40c0-a40cc preserves 4/5/6; others fallback4",
           "original_real_app_icon_name_bundle":True,
           "current_app_collections_read_from_LSApplicationWorkspace":True,
           "current_app_icon_from_optional_private_UIImage_API":True,
           "missing_current_original_badges":True,
           "current_tab_selected_background_blue_sourced":True,
           "current_tab_inactive_wrong_white_sourced":True,
           "original_card_RGB_and_icon_point_size_fully_proven":False,
           "original_menu_pixel_parity_proven":False,
           "original_app_functional_parity_proven":False,
           "real_device_test_done":False,
           "verdict":"NOT_100_PERCENT_PARITY"
        }
        (a.out/"FULL_DEB_PAYLOAD_INVENTORIES.json").write_text(json.dumps(inventories,indent=2,ensure_ascii=False)+"\n")
        (a.out/"APP_BINARY_MARKERS.json").write_text(json.dumps({
            "original_macho":oldb,"independent_macho":newb,"string_presence_only":coverage
           },indent=2,ensure_ascii=False)+"\n")
        (a.out/"ORIGINAL_APP_CALLSITES.json").write_text(json.dumps(
            method_audits,indent=2,ensure_ascii=False)+"\n")
        (a.out/"CURRENT_SOURCE_APP_WIRING.json").write_text(json.dumps(
            source_matrix(a.repo_root),indent=2,ensure_ascii=False)+"\n")
        (a.out/"APP_SUMMARY.json").write_text(json.dumps(summary,indent=2,ensure_ascii=False)+"\n")
        print("TWO_ACTUAL_DEBS_SHA_VERIFIED_ALL_FILES_EXTRACTED_AND_APP_BINARY_TEST",json.dumps(summary,ensure_ascii=False))
if __name__=="__main__":
    main()
