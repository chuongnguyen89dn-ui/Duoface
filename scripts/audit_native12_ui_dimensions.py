#!/usr/bin/env python3
"""Source dimensional inventory. This is NOT native pixel/device acceptance."""
from pathlib import Path
import json, argparse, sys

ROOT=Path(__file__).resolve().parents[1]
FILES={
"shell":"replacement/visual12/engine/runtime/DFINativeShell.inc",
"ui":"replacement/visual12/engine/runtime/DFIInterface.inc",
"cards":"replacement/visual12/engine/runtime/DFINativePickerCards.inc",
"native_menu":"runtime/fullscreen/DFPickerZoomMenu.xm",
"approved":"replacement/visual12/engine/runtime/DFIApprovedVisuals.h",
"layouts":"replacement/visual12/engine/DFILayouts.h",
"logo":"src/DFDividerLogoGrip.inc",
"hud":"replacement/visual12/engine/runtime/DFV12NativeHUD8.inc"
}
# Each reference requires actual matching source text; QA-only means *not*
# established as an original Native12 visual dimension.
SPECS=[["carplay_safearea","Window usable area","source: safe area -> left 64 fallback","shell","UIEdgeInsetsMake(0,64,0,0)","original104","reference"],["window_minimum","Minimum usable size","100x100","shell","CGRectGetWidth(r)<100","original104","fallback"],["layouts","Layout modes","8 kinds (1,2,3,4,5,6,7,8)","layouts","kind=kind<1||kind>8?2:kind","approved","needs-device"],["pane_pill","Pane pill","76x22 default; upper-right 2pt","ui","CGRectGetMaxX(frame)-78,CGRectGetMinY(frame)+3,76,22","native12-actual-deb-init","default-corrected-modes-pending"],["pill_app","App button","QA 30x22 at (4,0), width not proven","shell","CGRectMake(4,0,30,22)","qa","not-native-proven"],["pill_focus","Expand/restore button","QA 30x22 at (39,0), width not proven","shell","CGRectMake(39,0,30,22)","qa","not-native-proven"],["divider_strip","Divider pan touch","16pt; thin stroke 1pt","ui","CGRectMake(r.origin.x-8,r.origin.y,16,r.size.height)","qa","not-native-proven"],["divider_logo","Divider logo control","36x44pt","ui","CGRectMake(r.origin.x-18,r.origin.y+relative*r.size.height-22,36,44)","qa","not-native-proven"],["divider_hold","Approved native logo hold","0.30s","logo","kDFLogoHoldThreshold = 0.30","approved-native","missing-in-qa"],["divider_tap","Approved independent logo action","tap swaps apps","ui","tapAction:@selector(swapPanes)","approved-native","corrected"],["divider_hold_qa","Independent hold recognizer","0.30s","shell","hold.minimumPressDuration=0.30;","approved-native","corrected"],["divider_move_qa","Independent logo position storage","fraction 0.10..0.90 of divider","ui","self.dividerLogoPositions[index]=@(DFIClamp(offset/length,.10,.90));","qa","needs-device"],["split_restore","Restore the prior ratio","do not reset fraction/secondary","ui","self.maximized=-1;[self saveLayout];[self.view setNeedsLayout];","qa","corrected"],["sheet_width","Sheet width","max 470, responsive min180, 8pt margins","shell","MIN(470.0,MAX(180.0,CGRectGetWidth(windowBounds)-16.0))","qa","not-native-proven"],["sheet_height","Sheet height","max 280, min140, content 40pt*count+55","shell","(CGFloat)rowCount*40.0+55.0","qa","not-native-proven"],["sheet_radius","Sheet rounding","20pt original V12","shell","self.layer.cornerRadius=20.0;","original12","reference"],["sheet_border","Sheet outline","0pt approved; original was 1pt","shell","self.layer.borderWidth=0.0;","approved-native","reference"],["header_height","Picker menu row","30pt, replaces old 40pt experiment","ui","nativeMenuHeight=30.0","approved-native","reference"],["header_logo","Header logo","120x30pt at full width","native_menu","const CGFloat logoWidth=120.0;","approved-native","reference"],["header_tabs","App/Zoom/Style/Close widths","43/51/47/51pt","ui","{43.0,51.0,47.0,51.0}","approved-native","reference"],["header_x","Close X reserved","48pt; QA X 32x26","ui","closeReserved=48.0","approved-native","partial"],["header_icon","Menu icon","16pt","approved","configurationWithPointSize:16","approved-native","reference"],["header_font","Menu label","10pt","approved","systemFontOfSize:10","approved-native","reference"],["app_cols","App grid columns","valid 4..6; default 4","cards","value>=4 && value<=6?value:4","original104","reference"],["app_rows","App grid rows","valid 2..3; default 2","cards","value==2 || value==3?value:2","original104","reference"],["app_pages","App grid orientation","horizontal paged with UIPageControl","cards","_scrollView.pagingEnabled=!recent;","original104","reference"],["app_gap","Card spacing","8pt","cards","const CGFloat gap=8.0;","qa","not-native-proven"],["app_icon","App card icon","22..44pt","cards","MIN(44.0,MAX(22.0,cw-12.0))","qa","not-native-proven"],["recent_height","Recent card height","52pt","cards","CGFloat recentHeight=52.0;","qa","not-native-proven"],["layout_icon","Layout preview inset","9x8pt and 1.2pt outline","ui","CGRectInset(self.bounds,9,8)","qa","not-native-proven"],["speed_hud","Speed8 floating HUD","104x46pt * scale","hud","CGSizeMake(104*self.visualScale,46*self.visualScale)","native8-source","reference"],["limit_circle","HUD limit circle","34pt ring, 17 radius","hud","_limitRing.layer.cornerRadius=17","native8-source","reference"],["hud_settings","HUD settings","169pt tall; 220..320pt wide","hud","(b.size.height-169)/2,w,169","native8-source","reference"],["hud_buttons","HUD eight settings","4 columns, each height49, stride57","hud","38+row*57,bw,49","native8-source","reference"],["hud_hold","HUD settings hold","0.6s","hud","settings.minimumPressDuration=0.6;","native8-source","reference"],["border","Pane touched border","1pt active, 0 otherwise","ui","layer.borderWidth=active?1.0:0.0","qa","needs-device"],["red","Approved logo red","RGB 227/2/15","approved","blue:15.0/255.0","approved-native","reference"]]
def run():
    rows=[]
    for name,topic,value,source,needle,authority,status in SPECS:
        text=(ROOT/FILES[source]).read_text(encoding="utf-8",errors="replace")
        idx=text.find(needle)
        rows.append(dict(id=name,section=topic,dimension=value,
            file=FILES[source],line=(text.count("\n",0,idx)+1 if idx>=0 else None),
            matched=idx>=0,provenance=authority,acceptance=status))
    return dict(status="STATIC_NATIVE12_DIMENSION_MATRIX",total=len(rows),
        missing=[r["id"] for r in rows if not r["matched"]],rows=rows,
        device_accepted=False,
        superseded="Legacy 40pt menu was superseded by Native12 approved 30pt one-row menu")
def markdown(report):
    lines=["# DuoFace visual geometry coverage — Native12 and original 1.0.4", "",
      "**STATIC ONLY**. Do not call QA-only dimensions the original sizes. "+
      "Neither device screenshot nor interaction tests were run.", "",
      "| Component | Dimension / constraint | Source evidence | Provenance / confidence |",
      "|---|---|---|---|"]
    for r in report["rows"]:
        cite=f"`{r['file']}:{r['line']}`" if r["matched"] else f"MISSING {r['file']}"
        lines.append(f"| {r['section']} | {r['dimension']} | {cite} | {r['provenance']}: {r['acceptance']} |")
    lines+=["",f"Found {report['total']-len(report['missing'])}/{report['total']} source anchors.",
     "", "Unknown: native pill/button dimensions, original picker card gaps/icon geometry,"+
     " exact split touch sizes, receiver window stacking and every on-device rendered rect.", ""]
    return "\n".join(lines)
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--json",type=Path)
    p.add_argument("--md",type=Path)
    p.add_argument("--strict",action="store_true")
    args=p.parse_args()
    report=run()
    if args.json:
        args.json.parent.mkdir(parents=True,exist_ok=True)
        args.json.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    if args.md:
        args.md.parent.mkdir(parents=True,exist_ok=True)
        args.md.write_text(markdown(report),encoding="utf-8")
    print("NATIVE12_GEOMETRY_DIMENSIONS="+str(report["total"]-len(report["missing"]))+"/"+str(report["total"]))
    print("MISSING="+json.dumps(report["missing"]))
    if args.strict and report["missing"]:
        raise SystemExit(1)
if __name__=="__main__":main()
