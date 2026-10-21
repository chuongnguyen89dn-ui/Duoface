#!/usr/bin/env python3
"""Forensic STRICT-NO-GO full 2-DEB comparison; never executes old binaries.
All original 1385 ObjC methods from pinned method-index, all file bytes,
candidate compiled Mach-O and 25 mandatory feature gates. A same-name
selector is NOT a proven callback, runtime ABI, UI, or scene equivalence.
"""
import argparse,collections,hashlib,json,pathlib,plistlib,subprocess,tempfile
from datetime import datetime,timezone

NATIVE_SHA="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
NEW_SHA="6476498212ede843640a7be305a275981cf639ac963c7d7760631fd7fd4718a7"
INDEX_SHA="efa45df59bc3c16887cc979bf3aedc0c93c92111"
LICENSE=("license","subscription","checkout","vip")
FEATURES=[
("CarPlay native scene/admission",["CBWindow","CBBridgeManagerDashboard"],["DFNativeHostTemplateSceneDelegate","DFFirstPartyAdmission"]),
("Khởi động splash logo ngang và thanh tiến trình",["CBSplitSplashScreenView"],["DFNative12Chrome","DFNative12BasicController"]),
("Bộ chọn app cards/icon/Recent/paging",["CBMultitaskingOverlayView","CBAppPickerViewController"],["DFAppPickerVC","DFAppLibrary"]),
("Host app iPhone bình thường",["CBBridgedUIAppView","CBBridgedUIApp"],["DFSceneHost"]),
("YouTube/video/audio phát không Safe Mode",["CBBridgedUIAppView","CBBridgedUIApp"],["DFSceneHost"]),
("Hiển thị hai app thật độc lập",["CBBridgedSplitApp","CBBridgedUIAppView"],["DFNative12Chrome","DFSceneHost"]),
("Cảm ứng hai app, scroll, player control",["CBBridgedUIAppView"],["DFTouchOwnerProbe","DFSceneHost"]),
("Chia màn và kéo tỷ lệ, nhớ tỷ lệ",["CBBridgedSplitApp","CBDividerView"],["DFNative12Chrome"]),
("Hoán đổi trái-phải, giữ logo",["CBDividerView","CBSlotPillView"],["DFNative12Chrome"]),
("Phóng to một ô, hoàn tác",["CBBridgedSplitApp","DFFullscreenTransport"],["DFNative12Chrome"]),
("Phóng to thật sự ẩn Dock, hoàn tác",["CBBridgeManagerDashboard","CBWindow"],["DFNative12Chrome"]),
("Tám layout, chế độ đa khung Native12",["CBDashboardSettings","CBMultitaskingOverlayView"],["DFNative12Chrome"]),
("Thay app slot/close/restore/atomic state",["CBBridgedSplitApp","CBBridgeManager"],["DFNative12Chrome","DFSceneHost"]),
("Đúng vị trí/timer/hitbox của các pill",["CBSlotPillView"],["DFNative12Chrome"]),
("Viền đỏ khi chạm và tự ẩn",["CBBridgedSplitApp","CBDividerView"],["DFNative12Chrome"]),
("Logo, icon, màu sắc, bo góc và hiệu ứng",["CBMultitaskingOverlayView","CBSplitSplashScreenView"],["DFNative12Chrome","DFAppPickerVC"]),
("Về CarPlay Home ẩn thanh/menu tức thì",["CBWindow","CBBridgeManagerDashboard"],["DFTouchOwnerProbe","DFNativeHostTemplateSceneDelegate"]),
("Reconnect, exitmode, SpringBoard stability",["CBBridgeManager","CBWindow"],["DFSceneHost","DFTouchOwnerProbe"]),
("Dock và geometry nhiều màn CarPlay",["CBWindow","CBBridgeManagerDashboard"],["DFNative12Chrome"]),
("Audio focus và playback video",["CBBridgedUIAppView"],["DFSceneHost"]),
("Bong bóng HUD8 4 nguồn/tự ẩn",["DFSpeedNativeHUD","DFSpeedSplit7Driver","DFOwnerPollingDriver"],["DFTouchOwnerProbe"]),
("Trợ lý nói chuyện/voice mic",["CBAssistantManager","CBBridgedAssistantView"],["DFNativeHostRootController"]),
("Cài đặt app iPhone/preferences",["CBGeneralSettingsViewController","CBSplitViewController","CBAppManager"],["DFNativeHostRootController"]),
("Đồng bộ SpringBoard/CarPlay/app process",["CBBridgeManager","CBBridgeManagerDashboard"],["DFTouchOwnerProbe","DFSceneHost"]),
("Injection filters/entitlement lifecycle",["CBWindow","CBBridgeManager"],["DFFirstPartyAdmission","DFTouchOwnerProbe"])
]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(*args):
    v=subprocess.run(args,capture_output=True,text=True,errors="replace")
    if v.returncode:raise RuntimeError(" ".join(map(str,args))+" "+v.stderr[-1000:])
    return v.stdout
def macho(f):
    with f.open("rb") as h:b=h.read(4)
    return b.hex() in {"cffaedfe","cefaedfe","cafebabe","bebafeca","cafebabf","bfbafeca"}
def inventory(root):
    files=[];plists={}
    for f in sorted(root.rglob("*")):
        if not f.is_file() or f.is_symlink():continue
        relative=f.relative_to(root).as_posix()
        files.append({"path":relative,"name":f.name,"bytes":f.stat().st_size,
            "sha256":sha(f),"mach_o":macho(f)})
        if f.suffix==".plist":
            try:pl=plistlib.loads(f.read_bytes())
            except (ValueError,TypeError):continue
            if isinstance(pl,dict):
                selected={k:pl[k] for k in ("Filter","CFBundleIdentifier","CFBundleExecutable",
                    "CFBundleDisplayName","UIApplicationSceneManifest","UILaunchStoryboardName")
                    if k in pl}
                if selected:plists[relative]=selected
    return files,plists
def category(cls):
    name=cls.lower()
    if any(x in name for x in LICENSE):return "LICENSE_EXCLUDED"
    if any(x in name for x in ("speed","hud","polling")):return "HUD_SPEED"
    if "assistant" in name:return "VOICE_AUDIO"
    if any(x in name for x in ("picker","multitask","settings","appmanager","splitview")):return "PICKER_SETTINGS"
    if any(x in name for x in ("fullscreen","zoom","hostsnapshot")):return "FULLSCREEN_ZOOM"
    if any(x in name for x in ("bridge","window","scene")):return "BRIDGE_SCENE"
    if any(x in name for x in ("split","divider","slot","splash")):return "SPLIT_UI"
    return "OTHER"
def write(path,value):path.write_text(json.dumps(value,indent=2,ensure_ascii=False)+"\n")
def main():
    ap=argparse.ArgumentParser()
    for x in ("native12","new","index","out"):ap.add_argument("--"+x,required=True,type=pathlib.Path)
    a=ap.parse_args()
    for p,expected in ((a.native12,NATIVE_SHA),(a.new,NEW_SHA)):
        if sha(p)!=expected:raise SystemExit("SHA PIN FAILED: "+str(p))
    if run("git","hash-object",str(a.index)).strip()!=INDEX_SHA:raise SystemExit("Original method index SHA pin FAILED")
    records=json.loads(a.index.read_text())["native12"]
    assert len(records)==8
    assert sum(len(r["objc_methods"]) for r in records)==1385
    with tempfile.TemporaryDirectory() as td:
        o=pathlib.Path(td)/"original";n=pathlib.Path(td)/"new"
        o.mkdir();n.mkdir()
        run("dpkg-deb","-x",str(a.native12),str(o))
        run("dpkg-deb","-x",str(a.new),str(n))
        original,original_plists=inventory(o);new,new_plists=inventory(n)
        oldbin=[x for x in original if x["mach_o"]]
        newbin=[x for x in new if x["mach_o"]]
        assert len(oldbin)==8, "not all 8 reference Mach-O files"
        assert len(new)==34, "unexpected new merged package file count"
        foundbins={p.name:p for p in o.rglob("*") if p.is_file() and macho(p)}
        for r in records:
            assert r["filename"] in foundbins
            assert sha(foundbins[r["filename"]])==r["sha256"]
        newtexts={}
        for item in newbin:
            f=n/item["path"]
            newtexts[item["path"]]=set(run("strings","-a",str(f)).splitlines())
        allmethods=[]
        clsmap=collections.defaultdict(list)
        for r in records:
            for m in r["objc_methods"]:
                candidates=[path for path,strings in newtexts.items() if m["selector"] in strings]
                row={"native_binary":r["filename"],"native_class":m["class"],
                     "native_selector":m["selector"],"native_kind":m["kind"],
                     "native_type_encoding":m.get("type"),"native_imp":m["imp"],
                     "category":category(m["class"]),"new_selector_string_only":candidates,
                     "runtime_caller_receiver_and_lifecycle_verified":False,
                     "verdict":"KHONG_DAT"}
                allmethods.append(row);clsmap[m["class"]].append(row)
        assert len(allmethods)==1385
        categories=collections.Counter(x["category"] for x in allmethods)
        oldby=collections.defaultdict(list);newby=collections.defaultdict(list)
        for x in original:oldby[x["name"]].append(x)
        for x in new:newby[x["name"]].append(x)
        same=[]
        for name,old in oldby.items():
            for x in old:
                for y in newby[name]:
                    if x["sha256"]==y["sha256"]:
                        same.append({"name":name,"original_path":x["path"],
                          "new_path":y["path"],"sha256":x["sha256"]})
        gates=[]
        for name,classes,candidates in FEATURES:
            m=[method for cls in classes for method in clsmap.get(cls,[])]
            new_classes={cls:[file for file,texts in newtexts.items() if cls in texts] for cls in candidates}
            gates.append({"feature":name,"native12_method_count":len(m),
              "native12_classes_present":[x for x in classes if x in clsmap],
              "candidate_names_present_as_strings":new_classes,
              "source_or_binary_similarity_is_not_proof":True,
              "full_functional_parity_proven":False,"result":"KHONG_DAT"})
        summary={"scope":"ONLY_NATIVE12_VS_NEW_DUOFACE_NO_DUONAVI",
          "native12_sha256":NATIVE_SHA,"new_duoface_sha256":NEW_SHA,
          "original_method_index_blob":INDEX_SHA,"time_utc":datetime.now(timezone.utc).isoformat(),
          "original_files":len(original),"new_files":len(new),
          "original_macho":len(oldbin),"new_macho":len(newbin),
          "original_objc_methods":len(allmethods),"original_classes":len(clsmap),
          "original_selectors":len(set(x["native_selector"] for x in allmethods)),
          "original_method_selector_text_seen_in_new":sum(bool(x["new_selector_string_only"]) for x in allmethods),
          "byte_identical_basenames":len(same),"feature_gates":len(gates),
          "feature_gates_pass":0,"feature_gates_fail":len(gates),
          "groups":dict(categories),"verdict":"KHONG_DAT",
          "no_false_positive_rule":"Same selector, bytes or UI art are NOT ABI or runtime equivalence",
          "limitation":"Complete original ObjC method inventory, not all C/static/helper indirect call sites; native12 1087 uncertain stubs. Original-to-new runtime edges and video playback unverified."}
        classes=[{"class":cls,"methods":len(rows),"selector_string_matches":sum(bool(r["new_selector_string_only"]) for r in rows),
                  "category":category(cls),"functional_parity_proven":False} for cls,rows in sorted(clsmap.items())]
        a.out.mkdir(parents=True,exist_ok=True)
        write(a.out/"SUMMARY.json",summary)
        write(a.out/"FILE_INVENTORY.json",{"original":original,"new":new,"identical_by_name_and_sha256":same,
              "original_plists":original_plists,"new_plists":new_plists})
        write(a.out/"ALL_NATIVE12_1385_METHODS.json",{"methods":allmethods})
        write(a.out/"CLASSES_AND_NEW_MACHO.json",{"original_classes":classes,"new_macho":newbin})
        write(a.out/"FEATURE_GATES.json",gates)
        md=["# Native12 gốc ↔ DuoFace mới — TOÀN BỘ file và 1.385 method",
           "","**KẾT LUẬN: KHÔNG ĐẠT tương đồng Native12.**",
           "","Bản gốc: "+NATIVE_SHA,"Bản mới: "+NEW_SHA,
           "","## Kiểm kê bytecode",
           f"- Native12: {len(original)} file, {len(oldbin)} Mach-O, {len(clsmap)} ObjC classes, {len(allmethods)} ObjC methods.",
           f"- DuoFace mới: {len(new)} file, {len(newbin)} Mach-O.",
           f"- Tên selector gốc còn xuất hiện trong ít nhất một Mach-O mới: {summary['original_method_selector_text_seen_in_new']}/{len(allmethods)} (chỉ dấu chữ, KHÔNG phải hàm tương đương).",
           f"- File trùng basename và toàn bộ bytes: {len(same)}. Tính năng giao diện KHÔNG tự đạt nhờ trùng logo.",
           "","## 25 cổng tương đồng — tất cả KHÔNG ĐẠT",
           "| Nhóm | Method Native12 gốc | Kết quả |","|---|---:|---|"]
        md.extend(f"| {g['feature']} | {g['native12_method_count']} | **KHÔNG ĐẠT** |" for g in gates)
        md.extend(["","## Các tệp kết quả",
          "- FILE_INVENTORY.json: đầy đủ từng file, SHA-256, Info.plist, tweak filters, ảnh byte-identical.",
          "- ALL_NATIVE12_1385_METHODS.json: đầy đủ selector, type encoding, IMP, lớp, binary và tên nào có mặt trên binary mới.",
          "- CLASSES_AND_NEW_MACHO.json: đủ lớp gốc, mọi Mach-O mới.",
          "- FEATURE_GATES.json: 25 chức năng chưa chứng minh parity.",
          "- SUMMARY.json: thống kê và NO-GO.",
          "","**Không có DuoNavi.** Không đánh dấu PASS bằng cách so chữ tên hàm. Phải chứng minh callback/receiver/ABI/scene lifecycle và kiểm tra trên xe. Không copy/bypass license bên thứ ba.",
          "","Ghi chú: 2.509 function starts của original bao gồm hàm C, optimized objc stubs; không được hiểu 1.385 ObjC methods là mọi function trong mọi binary.",""])
        (a.out/"REPORT.md").write_text("\n".join(md))
        print("NATIVE12_VS_NEW_ALL_1385_METHODS_AND_EVERY_FILE_AUDITED")
        print(json.dumps(summary,ensure_ascii=False))
if __name__=="__main__":main()
