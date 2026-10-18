#!/usr/bin/env python3
"""READ ONLY: actual Native12 Speed8 DEB assets/ARM64 geometry alongside original 1.0.4.

Never execute vendor code, modify DEBs, copy vendor dylibs into QA, package, or deploy.
Class method/selector refs and ARM immediates are STATIC evidence, not CGRect
values or proof of active path on a CarPlay head unit.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile
from bisect import bisect_right
from importlib import import_module

NATIVE_DEB_SHA="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
ORIG_DEB_SHA="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
NATIVE_DASH_SHA="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
ORIG_DASH_SHA="44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"
DASHES={"native12":"DuoFaceDashboard.dylib","original104":"DuoNaviDashboard.dylib"}
TARGETS={
"CBWindow":("createWindows","resizeWindows","show","carPlayContentInsets",
            "carPlayUsableBounds","showAppPickerForSlot:","showLayoutChooser","destroyWindows"),
"CBMultitaskingOverlayView":("initWithFrame:","layoutSubviews","setupCardContent",
            "setupAppPickerCardsInCardW:cardH:contentY:",
            "setupRecentAppsCardsInCardW:cardH:contentY:"),
"CBSlotPillView":("initWithFrame:","layoutSubviews","updateLayout"),
"CBDividerView":("initWithFrame:","layoutSubviews","updateGripLayout",
            "handlePan:","handleMoveButtonLongPress:"),
"CBBridgedSplitApp":("layoutSplitViews","handleDividerPan:isVertical:state:",
            "focusSlot:animated:","restoreSplitAnimated:","configureDividerButtons",
            "handleDividerSwapPressed:","swapSlot:withSlot:"),
"CBBridgedUIAppView":("calculateNativeSizeForSlotRect:","updateLayout",
            "updateSceneSettingsFrame","updateSceneFrame","startInParentViewController:","dismiss"),
}
QA_OWNERS={
"CBWindow":"DFINativeWindowSurface / DFIStart; owns external UIWindow, safe-area",
"CBMultitaskingOverlayView":"DFINativePickerCard + DFINativePickerMenuBar + DFINativePickerCardsController",
"CBSlotPillView":"DFINativeSlotPillView / choose:, zoomPane:",
"CBDividerView":"DFINativeDividerTrack / drag: and DFINativeDividerLogo / swapPanes, moveDividerLogo:",
"CBBridgedSplitApp":"DFV12SplitController / DFIFramesMake, swapPanes, zoomPane:",
"CBBridgedUIAppView":"DFV12SceneHost / attachTo, resizeTo, applySize, close",
}
GEOMETRY=re.compile(r"fmov\s+\w+,\s*#|mov[zk]?\s+\w+,\s*#0x|\b(?:frinta|fcvt|fadd|fsub|fmul|fdiv|scvtf)\b|"
                    r"Objc selector ref: (?:setFrame:|setBounds:|setCornerRadius:|setContentSize:|setPagingEnabled:|"
                    r"setNumberOfPages:|setWindowLevel:|setImage:|setContentMode:|setButton:|safeAreaInsets)|"
                    r"Objc message: (?:setFrame:|setBounds:|setCornerRadius:|setContentSize:)")
SELECTOR=re.compile(r"Objc selector ref: (.+)$|Objc message: (.+)$")
ADDRESS=re.compile(r"^\s*([0-9a-fA-F]+):")
NAME=re.compile(r"^\s*name\s+0x[0-9a-fA-F]+\s+([A-Za-z_][A-Za-z0-9_]*)\s*$")
METHOD=re.compile(r"^\s*name\s+0x[0-9a-fA-F]+\s+\(0x[0-9a-fA-F]+\)\s+(.+?)\s*$")
IMP=re.compile(r"^\s*imp\s+0x[0-9a-fA-F]+\s+\(0x([0-9a-fA-F]+)\)")

def hashfile(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for blk in iter(lambda:f.read(1<<20),b""):h.update(blk)
    return h.hexdigest()

def get_class_methods(meta):
    """Correctly enumerate TARGETS incl overlay, unlike the prior 3-class false negative."""
    found={k:{} for k in TARGETS}
    cls=None;active=False;pending=None
    for l in meta.splitlines():
        m=NAME.match(l)
        if m:
            cls=m.group(1) if m.group(1) in found else None
            active=False;pending=None
            continue
        if cls and re.match(r"^\s*baseMethods\s+0x[0-9a-fA-F]+",l):
            active=not bool(re.match(r"^\s*baseMethods\s+0x0\s*$",l))
            continue
        if active and re.match(r"^\s*baseProtocols\b",l):
            cls=None;active=False;continue
        if not cls or not active:continue
        m=METHOD.match(l)
        if m:pending=m.group(1)
        m=IMP.match(l)
        if m and pending:
            found[cls][pending]=int(m.group(1),16)
            pending=None
    return found

def disasm_index(lines):
    addr=[];rows=[]
    for line in lines.splitlines():
        found=ADDRESS.match(line)
        if found:
            addr.append(int(found.group(1),16));rows.append(line.strip())
    pairs=sorted(zip(addr,rows))
    return [x[0] for x in pairs],[x[1] for x in pairs]

def inspect_methods(meta,asm):
    found=get_class_methods(meta)
    addr,rows=disasm_index(asm)
    result={}
    for cls,selectors in TARGETS.items():
        catalog=found[cls]
        catalog_offsets=sorted(set(catalog.values()))
        results=[]
        for selector in selectors:
            if selector not in catalog:
                results.append(dict(name=selector,present=False,
                     note="Absent from sampled ObjC class metadata (not evidence of absence in all code)"))
                continue
            start=catalog[selector]
            end=next((x for x in catalog_offsets if x>start),start+0x1600)
            end=min(end,start+0x1600)
            l=bisect_right(addr,start-1);h=bisect_right(addr,end-1)
            instr=rows[l:h][:1400]
            sels=[]
            for row in instr:
                match=SELECTOR.search(row)
                if match:
                    sel=match.group(1) or match.group(2)
                    if sel not in sels:sels.append(sel)
            geometry=[{"index":i,"window":instr[max(0,i-4):i+4]}
                for i,line in enumerate(instr) if GEOMETRY.search(line)][:40]
            results.append(dict(name=selector,present=True,imp=hex(start),
                 bounded_end=hex(end),instruction_count=len(instr),
                 selector_refs=sels[:120],geometry_instruction_samples=geometry,
                 **({"full_layout_asm":instr[:650]} if (cls,selector) in {
                    ("CBSlotPillView","layoutSubviews"),
                    ("CBDividerView","updateGripLayout"),
                    ("CBMultitaskingOverlayView","layoutSubviews"),
                    ("CBBridgedSplitApp","layoutSplitViews"),
                 } else {}),
                 **({"sizing_raw":instr[:96]} if selector=="calculateNativeSizeForSlotRect:" else {})))
        result[cls]=dict(class_in_metadata=bool(catalog),
             catalog_methods=len(catalog),catalog_method_names=sorted(catalog.keys()),
             selected=results,
             independent_owner=QA_OWNERS[cls])
    return result

def png_info(path,base):
    raw=path.read_bytes()
    if raw[:8]!=b"\x89PNG\r\n\x1a\n" or raw[12:16]!=b"IHDR":return None
    width,height,depth,kind=struct.unpack_from(">IIBB",raw,16)
    item=dict(path=str(path.relative_to(base)),bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest(),
              width_px=width,height_px=height,bit_depth=depth,png_color_type=kind,
              alpha_channel_in_file=kind in (4,6),pixel_artwork_not_view_pt=True)
    try:
        from PIL import Image
        with Image.open(path) as src:
            im=src.convert("RGBA")
            alpha=im.getchannel("A")
            item["nontransparent_bbox_px"]=list(alpha.getbbox()) if alpha.getbbox() else None
            item["alpha_min"],item["alpha_max"]=alpha.getextrema()
            item["rgba_corners"]=[list(im.getpixel((x,y))) for x,y in
                    ((0,0),(width-1,0),(0,height-1),(width-1,height-1))]
    except ImportError:
        item["alpha_inspection"]="Pillow missing; pixel bbox unavailable"
    return item

def scan_assets(base):
    imgs=[]
    for p in sorted(base.rglob("*.png")):
        item=png_info(p,base)
        if item:imgs.append(item)
    return imgs

def cli():
    p=argparse.ArgumentParser()
    p.add_argument("--native-deb",type=Path,required=True)
    p.add_argument("--original-deb",type=Path,required=True)
    p.add_argument("--out-json",type=Path,required=True)
    p.add_argument("--out-md",type=Path,required=True)
    a=p.parse_args()
    for file,digest in ((a.native_deb,NATIVE_DEB_SHA),(a.original_deb,ORIG_DEB_SHA)):
        got=hashfile(file)
        if got!=digest:raise SystemExit(f"IMMUTABLE_DEB_SHA_MISMATCH {file}: {got} expected {digest}")
    results={}
    with tempfile.TemporaryDirectory(prefix="duoface-ui-readonly-") as d:
        for name,deb in (("native12",a.native_deb),("original104",a.original_deb)):
            root=Path(d)/name
            root.mkdir()
            subprocess.run(["dpkg-deb","-x",str(deb),str(root)],check=True)
            arr=list(root.rglob(DASHES[name]))
            if len(arr)!=1:raise RuntimeError(f"{name} dashboard count={len(arr)}")
            binary=arr[0]
            expected=NATIVE_DASH_SHA if name=="native12" else ORIG_DASH_SHA
            if hashfile(binary)!=expected:raise RuntimeError(f"{name} actual Dashboard SHA mismatch")
            meta=subprocess.run(["xcrun","llvm-objdump","--macho","--objc-meta-data",str(binary)],
                                check=True,capture_output=True).stdout.decode("utf-8","replace")
            dis=subprocess.run(["xcrun","llvm-objdump","--macho","--disassemble",str(binary)],
                               check=True,capture_output=True).stdout.decode("utf-8","replace")
            results[name]=dict(
                 deb_sha256=NATIVE_DEB_SHA if name=="native12" else ORIG_DEB_SHA,
                 dashboard_sha256=expected,
                 dashboard_path=str(binary.relative_to(root)),
                 png_assets=scan_assets(root),
                 classes=inspect_methods(meta,dis))
    result=dict(status="NATIVE12_VS_ORIGINAL104_ACTUAL_DEB_READONLY",
       static_only=True,device_tested=False,qa_interface_modified=False,
       **results)
    a.out_json.parent.mkdir(parents=True,exist_ok=True)
    a.out_md.parent.mkdir(parents=True,exist_ok=True)
    a.out_json.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    native=results["native12"];orig=results["original104"]
    lines=["# Native12 Speed8 HUD vs DuoNavi 1.0.4 — actual DEB static dimension / asset audit",
     "", f"Status: **{result['status']}**. Debs pinned by SHA256.",
     "**Only static artifacts/method samples; neither Objective-C dispatch nor live CarPlay rects are established.**",
     "No vendor binary is embedded in independent QA. Distinguish image pixel dimensions from UIKit point dimensions.",
     "", "## Native12 PNG/logo sources in REAL native DEB", "",
     "| Asset path | Pixels | Alpha nonblank bbox (pixels) | SHA256 |",
     "|---|---:|---|---|"]
    for img in native["png_assets"]:
        lines.append(f"| `{img['path']}` | {img['width_px']}×{img['height_px']} | "
                     f"`{img.get('nontransparent_bbox_px')}` | `{img['sha256']}` |")
    lines+=["","## Original 1.0.4 and Native12 per-class method comparison","",
    "| Class | Original 1.0.4 method entries | Native12 method entries | DuoFace-owned replacement |",
    "|---|---:|---:|---|"]
    for cls in TARGETS:
        lines.append(f"| `{cls}` | {orig['classes'][cls]['catalog_methods']} | "
                     f"{native['classes'][cls]['catalog_methods']} | "
                     f"{QA_OWNERS[cls]} |")
    lines+=["","## Geometric and callback candidate IMPs (static)",""]
    for cls in TARGETS:
        lines.append(f"### {cls}")
        old={x["name"]:x for x in orig["classes"][cls]["selected"]}
        for n in native["classes"][cls]["selected"]:
            o=old.get(n["name"],{})
            lines.append(f"- `{n['name']}`: Native12 "
              f"`{n.get('imp','not in catalog')}`; original104 "
              f"`{o.get('imp','not in catalog')}`. "
              f"Native selector refs: `{', '.join(n.get('selector_refs',[])[:15])}`. "
              f"Arithmetic/control samples: {len(n.get('geometry_instruction_samples',[]))}.")
        lines.append("")
    lines+=["## Interpretation and implementation order","",
      "1. Use actual Native12 PNG hashes/dimensions and approve asset choice. Never infer UIButton size from PNG pixel size.",
      "2. Recover Native12 class-specific layout, hit rectangles and gestures from the bounded disassembly above; prove owner/selector version by version.",
      "3. Map each component to the independent DuoFace owner in the table; test view-tree, menu actions, scene launch and geometry in isolation.",
      "4. Combine source-owned view and scene binding after per-component proof. No copy of original vendor license/classes or postinst.",
      "5. Actual rects, safe area and visual equivalence still require the user's parked CarPlay screenshot/runtime log. No Sileo release from this audit.", ""]
    a.out_md.write_text("\n".join(lines),encoding="utf-8")
    print("NATIVE12_DEB_UI_AUDIT_PASS assets=%d original_assets=%d mapped_classes=%d" %
          (len(native['png_assets']),len(orig['png_assets']),len(TARGETS)))
if __name__=="__main__":cli()
