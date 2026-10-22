#!/usr/bin/env python3
"""Exact literal-address decoder for original Native12 0x9efe0 raster helper."""
import argparse,json,pathlib,runpy,sys,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
ADDRS={
    "preview_literal_30f9b8":0x30f9b8,
    "preview_literal_30f9c0":0x30f9c0,
    "preview_literal_30f9c8":0x30f9c8,
    "preview_literal_30fab8":0x30fab8,
    "preview_literal_30fac8":0x30fac8,
    "preview_literal_30faf8":0x30faf8,
    "preview_literal_310c80":0x310c80,
    "preview_literal_310cb0":0x310cb0,
    "preview_literal_310cc8":0x310cc8,
    "preview_literal_3116c0":0x3116c0,
    "preview_literal_3116c8":0x3116c8,
    "preview_literal_3116d0":0x3116d0,
    "preview_literal_3116d8":0x3116d8,
    "preview_literal_3116e0":0x3116e0,
    "preview_literal_3116e8":0x3116e8,
    "preview_literal_3116f0":0x3116f0,
    "preview_literal_3116f8":0x3116f8,
    "preview_literal_311700":0x311700,
    "preview_literal_311708":0x311708,
    "preview_literal_311710":0x311710,
    "preview_literal_311718":0x311718,
    "preview_literal_311720":0x311720,
    "preview_literal_311728":0x311728,
    "preview_literal_311730":0x311730,
    "preview_literal_311738":0x311738,
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--macho",required=True)
    p.add_argument("--out",required=True,type=pathlib.Path)
    a=p.parse_args()
    decoder=runpy.run_path(str(ROOT/"audit/native12-layout-forensic-20261021/decode_layout_constants.py"))
    decoder["main"].__globals__["ADDRS"].update(ADDRS)
    old=sys.argv
    try:
        with tempfile.TemporaryDirectory() as tmp:
            sys.argv=[old[0],"--macho",a.macho,"--out",tmp]
            decoder["main"]()
            raw=json.loads((pathlib.Path(tmp)/"DIVIDER_CONSTANTS.json").read_text())
    finally:
        sys.argv=old
    assert raw["macho_sha256"]=="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
    data={"original_source_imp":"0x9efe0","original_source_deb_sha256":"2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
         "macho_sha256":raw["macho_sha256"],
         "constants":{k:raw["constants"][k] for k in ADDRS},
         "device_color_pixel_parity_verified":False}
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"PREVIEW_HELPER_LITERALS.json").write_text(json.dumps(data,indent=2)+"\n")
    print("ORIGINAL_NATIVE12_PREVIEW_HELPER_25_CONSTS_VERIFIED",len(ADDRS))
if __name__=="__main__":main()
