#!/usr/bin/env python3
"""Decode gallery literals by reusing the existing SHA-checked Mach-O decoder."""
import argparse, json, pathlib, runpy, sys, tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--macho",required=True)
    p.add_argument("--out",required=True,type=pathlib.Path)
    a=p.parse_args()
    decoder=runpy.run_path(str(ROOT/"audit/native12-layout-forensic-20261021/decode_layout_constants.py"))
    # PCs a5f44, a6120, a6128, a6718 in original setupPresetCards...
    extra={"gallery_six_column_threshold":0x3117d8,
           "gallery_row_stride":0x3117e0,
           "gallery_card_height":0x3117e8,
           "gallery_content_height":0x3117f8,
           "gallery_unselected_blue":0x3117f0,
           "gallery_check_red":0x311720,
           "gallery_check_green":0x311728,
           "gallery_selected_red":0x3116c8,"gallery_selected_green":0x30f9c8,
           "gallery_selected_blue":0x311718,"gallery_fill_alpha":0x30faf8,
           "gallery_border_red":0x310cd0,"gallery_border_green":0x30faa8,
           "gallery_unselected_red":0x311790,"gallery_unselected_green":0x30f9a8,
           "gallery_border_alpha":0x30fac0}
    decoder["main"].__globals__["ADDRS"].update(extra)
    old=sys.argv
    try:
        with tempfile.TemporaryDirectory() as tmp:
            sys.argv=[old[0],"--macho",a.macho,"--out",tmp]
            decoder["main"]()
            raw=json.loads((pathlib.Path(tmp)/"DIVIDER_CONSTANTS.json").read_text())
    finally:
        sys.argv=old
    result={"evidence":"ORIGINAL_SHA_VERIFIED_MACHO_LITERALS_NOT_RUNTIME",
            "macho_sha256":raw["macho_sha256"],
            "source_imp":"0xa5e78","source_selector":"setupPresetCardsInCardW:cardH:contentY:",
            "constants":{k:raw["constants"][k] for k in extra},
            "immediates":{"horizontal_inset":14,"column_gap":10,"first_row_y":22,
                          "corner_radius":12,"preview_height":54,"preview_top":6,
                          "preview_width":"roundf(cardWidth - 14)","selected_border":2,
                          "unselected_border":1,"selection_badge_size":17},
            "new_runtime_changed":False,"device_verified":False}
    a.out.mkdir(parents=True,exist_ok=True)
    dest=a.out/"GALLERY_CONSTANTS.json"
    dest.write_text(json.dumps(result,indent=2)+"\n")
    print("NATIVE12_ORIGINAL_GALLERY_CONSTANTS_VERIFIED",dest)
if __name__=="__main__":main()
