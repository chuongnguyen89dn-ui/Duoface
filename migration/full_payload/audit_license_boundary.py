#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phân tích ĐỌC-CHỈ ranh giới cấp phép/host từ chính metadata Objective-C v12.

Tận dụng lại scripts/v12_host_recovery.py, KHÔNG viết lại parser Mach-O
và KHÔNG sửa binary. Giới hạn: Objective-C dispatch động không phải call graph
hoàn chỉnh; danh sách IMP không chứng minh được phép cắt code.
"""
from __future__ import annotations
import argparse
from collections import defaultdict
from contextlib import redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import re
import runpy
import sys

EXPECTED_DASH = "bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce"
LICENSE_RE = re.compile(r"licens|trial|expir|watchdog|activation|entitlement", re.I)
HOST_RE = re.compile(r"split|bridge|dashboard|window|picker|layout|scene|slot|restore|focus", re.I)
INTERESTING = {
    "init", "deactivateCurrentApp", "loadNewAppFromCurrentRequest:",
    "switchToSplitWithLeft:right:ratio:", "switchToMultiSplitMode:apps:ratio:",
    "showAppPickerForSlot:", "showLayoutChooser", "focusSlot:animated:",
    "restoreSplitAnimated:", "sendStateToApp:shouldBridge:",
    "stopLicenseWatchdogTimer", "dismissLicenseWarningModal",
    "isLicenseCurrentlyValid", "licenseWatchdogTimerFired:",
}

def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--dashboard",type=Path,required=True)
    parser.add_argument("--report",type=Path,required=True)
    args=parser.parse_args()
    binary=args.dashboard.resolve()
    digest=hashlib.sha256(binary.read_bytes()).hexdigest()
    assert digest==EXPECTED_DASH, f"Dashboard gốc thay đổi! {digest}"
    script=Path(__file__).resolve().parents[2]/"scripts/v12_host_recovery.py"
    original=sys.argv[:]
    try:
        sys.argv=[str(script),str(binary)]
        with redirect_stdout(io.StringIO()):
            scope=runpy.run_path(str(script),run_name="__duoface_read_only_metadata__")
    finally:
        sys.argv=original
    raw_methods=scope["methods"]
    by_owner=defaultdict(list)
    by_imp=defaultdict(list)
    for owner,kind,selector,imp in raw_methods:
        e={"kind":kind,"selector":selector,"imp_hex":hex(imp)}
        by_owner[owner].append(e)
        by_imp[imp].append((owner,kind,selector))
    hits=[]
    for owner,values in sorted(by_owner.items()):
        match=[v for v in values if LICENSE_RE.search(v["selector"])]
        if match: hits.append({"class":owner,"license_related_methods":match})
    bridge=by_owner.get("CBBridgeManager",[])
    bridge_host=[v for v in bridge if HOST_RE.search(v["selector"])]
    bridge_license=[v for v in bridge if LICENSE_RE.search(v["selector"])]
    widget=by_owner.get("CBMultitaskingOverlayView",[])
    split=by_owner.get("CBBridgedSplitApp",[])
    spotlight=[]
    addresses=sorted(set(imp for imp in by_imp if isinstance(imp,int) and imp>0))
    section_base,size,_,_=scope["sections"]["__text"]
    text_end=section_base+size
    arm64=scope["md"]
    slice_bytes=scope["p"]
    for owner,kind,sel,imp in raw_methods:
        if sel not in INTERESTING and not (owner=="CBBridgeManager" and LICENSE_RE.search(sel)):
            continue
        if imp<=0 or not section_base<=imp<text_end: continue
        next_imp=next((value for value in addresses if value>imp),text_end)
        stop=min(next_imp,imp+768,text_end)
        if stop<=imp: continue
        # ARM64 direct edges only; ObjC via objc_msgSend not resolved.
        direct=[]
        for ins in arm64.disasm(slice_bytes[imp:stop],imp):
            if ins.mnemonic=="bl" and ins.operands and ins.operands[0].type==2:
                target=ins.operands[0].imm
                for callee in by_imp.get(target,[]):
                    if callee[0]=="CBBridgeManager" or LICENSE_RE.search(callee[2]):
                        direct.append({"to_class":callee[0],"to_selector":callee[2],
                                       "at":hex(ins.address),"target":hex(target)})
        spotlight.append({
            "class":owner,"kind":kind,"selector":sel,"imp":hex(imp),
            "bounded_disassembly":hex(stop-imp)+" bytes",
            "objc_msgSend_edges_not_resolved":True,
            "direct_calls_within_methods":direct[:30],
        })

    # Một class có cả selector điều khiển host và license KHÔNG chứng minh
    # chúng có thể bị tách riêng bằng cách xóa file/phân đoạn.
    report={
        "source_sha256":digest,
        "method_metadata_source":"scripts/v12_host_recovery.py",
        "method_count":len(raw_methods),
        "objc_class_count":len(by_owner),
        "license_method_owners":hits,
        "cb_bridge_manager_method_count":len(bridge),
        "cb_bridge_manager_host_methods":bridge_host,
        "cb_bridge_manager_license_related_methods":bridge_license,
        "cb_bridged_split_app_method_count":len(split),
        "cb_picker_method_count":len(widget),
        "selected_method_address_and_static_edges":spotlight,
        "known_original_v12_app_license_markers":True,
        "bounded_static_analysis_only":True,
        "dynamic_dispatch_fully_resolved":False,
        "license_subsystem_separable_by_file":False,
        "independent_release_ready":False,
        "status":"BINARY_LICENSE_AND_HOST_BOUNDARY_PARTIAL_NOT_SEPARATED",
        "next":"Phải truy điều kiện khởi tạo/scene và quyết định kiểm tra license theo call graph thực trước khi kết luận khả năng giữ nguyên binary mà không phụ thuộc license. Không sửa/giả giấy phép.",
    }
    assert len(bridge)>10 and len(split)>10 and len(widget)>10, "Metadata thiếu class lõi"
    assert len(hits)>0, "Không tìm thấy phương thức cấp phép, phải kiểm tra lại parser"
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2,ensure_ascii=False,sort_keys=True)+"\n",encoding="utf-8")
    print(json.dumps({
        "status":report["status"],"method_count":len(raw_methods),
        "classes":len(by_owner),"bridge_methods":len(bridge),
        "bridge_license_selectors":[x["selector"] for x in bridge_license],
        "license_class_names":[h["class"] for h in hits],
        "static_edges":sum(len(x["direct_calls_within_methods"]) for x in spotlight),
    },ensure_ascii=False,indent=2))
if __name__=="__main__":
    main()
