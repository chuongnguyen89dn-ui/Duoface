#!/usr/bin/env python3
"""SHA-pinned, read-only original DuoNavi 1.0.4 versus signed DuoFace .118
CarPlay display-geometry callsite crosswalk. License code is never copied.
Uses verified first-party MachO parser from previous DuoFace audits.
"""
import argparse
import bisect
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ORIGINAL_SHA="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
ORIGINAL_DYLIB_SHA="44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"
CURRENT_SHA="4b566ea40727df0acfd7baab8268dac2bfc8ada2779ad5ec6964b43f7b6793fb"
METHODS={
 "CBWindow":[
  "carPlayContentInsets","carPlayUsableBounds","carPlayScreenBounds",
  "carPlayUIScreen","carPlayScreenScale","getCarPlayDisplay",
  "resetCachedBounds","createWindows","resizeWindows","initWithAppFrame:"],
 "CBBridgedSplitApp":["layoutSplitViews","updateBoundsSize","setSplitRatio:"],
 "CBBridgeManager":["receivedMetricsUpdatedNotification:","renderSizeForBundleID:"],
 "CBBridgedUIAppView":["layoutSubviews","updateLayout","refreshSceneLayout","updateSceneSettingsFrame"],
}
INTEREST=("carPlayContentInsets","carPlayUsableBounds","carPlayScreenBounds",
 "safeAreaInsets","rootWindow","activeCarPlayWindow","UIEdgeInsetsFromString",
 "setFrame:","setBounds:","setTransform:","layoutSplitViews","resizeWindows",
 "setContentReferenceSize:","refreshSceneLayout","setNeedsLayout",
 "layoutIfNeeded","setWindowLevel:","setHidden:","setClipsToBounds:",
 "setUserInteractionEnabled:","dispatch_after","dispatch_async")

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--original-deb",required=True)
    p.add_argument("--current-deb",required=True)
    p.add_argument("--parser-dir",required=True)
    p.add_argument("--out",required=True)
    p.add_argument("--source-root",required=True)
    args=p.parse_args()
    assert sha(args.original_deb)==ORIGINAL_SHA,"wrong original DuoNavi .deb"
    assert sha(args.current_deb)==CURRENT_SHA,"wrong signed independent .118 .deb"
    assert subprocess.check_output(["dpkg-deb","-f",args.original_deb,"Package"],text=True).strip()=="com.duonavi.app"
    assert subprocess.check_output(["dpkg-deb","-f",args.current_deb,"Package"],text=True).strip()=="com.duoface.jb.embedded"
    assert subprocess.check_output(["dpkg-deb","-f",args.current_deb,"Version"],text=True).strip()=="0.0.118~dock-rollback1"
    out=Path(args.out);out.mkdir(parents=True,exist_ok=True)
    orig=out/"original";curr=out/"current"
    for deb,place in ((args.original_deb,orig),(args.current_deb,curr)):
        subprocess.run(["dpkg-deb","-x",deb,str(place)],check=True)
    dylib=orig/"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib"
    assert sha(dylib)==ORIGINAL_DYLIB_SHA
    current_touch=curr/"var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib"
    current_host=curr/"var/jb/Applications/DuoFaceNativeHost.app/DuoFaceNativeHost"
    assert current_touch.is_file() and current_host.is_file(),"no current signed executable/geometry library"
    sys.path.insert(0,args.parser_dir)
    from audit_native12_license_class_xrefs import MachO,select_arm64
    from audit_native12_carplay_add_app_chain import methods,disassemble
    mach=MachO(select_arm64(dylib.read_bytes()))
    classes=mach.classes()
    methods_by_class={}
    begins=set()
    for c in classes:
        try:
            d=methods(mach,c)
            methods_by_class[c]=d
            begins.update(x["vm"] for x in d.values() if x.get("vm"))
        except (ValueError,KeyError,IndexError,AssertionError):pass
    all_starts=sorted(begins)
    extraction={"original_DEB_sha256":ORIGINAL_SHA,"original_Dashboard_sha256":ORIGINAL_DYLIB_SHA,
      "current_DEB_sha256":CURRENT_SHA,"original_objc_classes":len(classes),"methods":[],"missing":[]}
    lines=[
      "# Original DuoNavi 1.0.4 vs signed DuoFace .118: CarPlay Dock and pane geometry",
      "",
      "**Read-only binary verification. This is not a device measurement or a proved no-gap correction.**",
      "",
      "- Original signed source: `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`",
      "- Original DEB SHA256: `"+ORIGINAL_SHA+"`",
      "- Original `DuoNaviDashboard.dylib` SHA256: `"+ORIGINAL_DYLIB_SHA+"`",
      "- Current immutable signed DuoFace `0.0.118~dock-rollback1` SHA256: `"+CURRENT_SHA+"`",
      "- Current real signed binary includes `DFTouchOwnerProbe.dylib` and `DuoFaceNativeHost`.",
      "- Original extracted IMPs and disassembly in `ORIGINAL_DUONAVI104_DOCK_IMP.json`.",
      "",
      "## Original binary: geometry owner and callsites",
      "",
    ]
    for cl,targets in METHODS.items():
        byname=methods_by_class.get(cl,{})
        for sel in targets:
            method=byname.get("+"+sel) or byname.get("-"+sel)
            if not method:
                extraction["missing"].append(cl+"."+sel)
                lines.append("- NOT FOUND in ObjC metadata: `"+cl+"."+sel+"`")
                continue
            vm=method["vm"]
            k=bisect.bisect_right(all_starts,vm)
            limit=min(all_starts[k] if k<len(all_starts) else vm+0x3000,vm+0x3000)
            ins=disassemble(mach,vm,limit)
            obj={"class":cl,"selector":sel,"imp":hex(vm),"next_limit":hex(limit),
                 "instruction_count":len(ins),"objc_type":method.get("type"),
                 "instructions":ins}
            extraction["methods"].append(obj)
            calls=[s for s in ins if any(t in s for t in INTEREST)]
            lines.append("### `"+cl+"."+sel+"` @"+hex(vm))
            lines.append("ARM64 instructions: "+str(len(ins))+". Exact relevant callsites:")
            lines.extend("- `"+x.replace("`","'")[:270]+"`" for x in calls[:70])
            if not calls:lines.append("- No labeled matching callsite in bounded function; inspect full instructions.")
            if len(calls)>70:lines.append("- Truncated at 70 callsites; see full immutable JSON.")
            lines.append("")
    # Guard against mistaking a different Duonavi vendor version or dylib.
    assert "CBWindow" in methods_by_class, "DuoNavi root window owner class missing"
    assert any(m["selector"]=="layoutSplitViews" for m in extraction["methods"]), "no original split layout"
    assert any(m["selector"]=="carPlayUsableBounds" for m in extraction["methods"]), "no original usable geometry"
    out.joinpath("ORIGINAL_DUONAVI104_DOCK_IMP.json").write_text(
        json.dumps(extraction,indent=2,ensure_ascii=False)+"\n")
    root=Path(args.source_root)
    proxy=(root/"sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m").read_text()
    host=(root/"sideplay/duoface-native-scene-host/DFNativeHostAppDelegate.m").read_text()
    chrome=(root/"sideplay/duoface-native-scene-host/DFNative12Chrome.m").read_text()
    current_checks={
      "CPWindow_delegate_uses_safeAreaLayoutGuide.layoutFrame":
        "safe=w.safeAreaLayoutGuide.layoutFrame" in host,
      "delegate_uses_entire_CPWindow_bounds_if_safe_empty":
        "if(CGRectIsEmpty(safe))safe=w.bounds;" in host,
      "host_sends_ContentRect":
        '"ContentRect":NSStringFromCGRect(content)' in host,
      "SpringBoard_second_left_floor_MAX_42_or_8_2_percent":
        "MAX(42,screen.size.width*.082)" in proxy,
      "SpringBoard_clamps_valid_ContentRect_again":
        "CGFloat x=MAX(region.origin.x,safeLeft);" in proxy,
      "SpringBoard_fabricates_rail_if_ContentRect_invalid":
        "region=CGRectMake(safeLeft,screen.origin.y" in proxy,
      "Chrome_positions_panels_from_contentRect_origin":
        "CGRect cr=self.contentRect;" in chrome and
        "cr.origin.x" in chrome,
    }
    assert all(current_checks.values()),"current source/claimed signed 118 mismatch: "+str(current_checks)
    current_summary={
      "archive":"signed independent .118 source commit e9501ec1e5b441095a22b78b255c8c8b932bb383",
      "source_code_contracts":current_checks,
      "touch_binary_size":current_touch.stat().st_size,
      "host_binary_size":current_host.stat().st_size,
      "no_on_car_geometry_readback":True
    }
    lines.extend(["## Current DuoFace .118 — exact signed source geometry chain",""])
    for k,v in current_checks.items():lines.append("- "+k+": "+("YES" if v else "NO"))
    lines.extend([
      "",
      "The current iPhone CPWindow computes `ContentRect` from `frame + safeAreaLayoutGuide.layoutFrame`, with an **unconditional fallback to the entire CPWindow bounds when layoutFrame is empty**. The SpringBoard owner then applies a **second independent left boundary floor** `MAX(42pt, 8.2% screen width)` to that content rectangle, or invents a region with the same floor when content is invalid. The independent Chrome places all app panes in the resulting rectangle.",
      "",
      "**Not equivalent to proving a literal physical gap.** We have not captured the current screen's measured rootWindow.safeAreaInsets, actual Apple Dock frame, or `ContentRect` before and after the clamp. Neither binary's static geometry can supply those device-dependent values. A derived example is not a measurement.",
      "",
      "**Do not copy** proprietary vendor methods/gestures/license, invent another 42pt/64pt constant, crop native Dock, or publish a new DEB solely from this static diff. First isolate `native-root-window safeAreaInsets` vs `CPWindow safeAreaLayoutFrame` and resulting `pane origin` at runtime. Protect .118 Dock, .90 player orientation and .92 divider.",
    ])
    out.joinpath("DUONAVI104_VS_SIGNED_DUOFACE118_DOCK_VERDICT.md").write_text("\n".join(lines)+"\n")
    out.joinpath("CURRENT118_SIGNED_SOURCE_CONTRACT.json").write_text(
        json.dumps(current_summary,indent=2)+"\n")
    print("DUONAVI_ORIGINAL_VS_SIGNED_118_GEOMETRY_SHA_PINNED_PASS",len(extraction["methods"]),
          "origclasses",len(classes),"missing",len(extraction["missing"]))
if __name__=="__main__":
    main()
