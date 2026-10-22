#!/usr/bin/env python3
"""Exact literal-address decoder for original Native12 0xa2a58 raster helper."""
import argparse,json,pathlib,runpy,sys,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
ADDRS={
    "header_310cd0":0x310cd0,
    "header_311720":0x311720,
    "header_311728":0x311728,
    "header_311730":0x311730,
    "header_311758":0x311758,
    "header_311760":0x311760,
    "header_311768":0x311768,
    "header_311770":0x311770,
    "header_311778":0x311778,
    "header_311780":0x311780,
    "header_311788":0x311788,
    "header_311790":0x311790,
    "header_311798":0x311798,
    "header_311830":0x311830,
    "header_311838":0x311838,
}
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
    data={"original_source_imp":"0xa2a58","original_source_deb_sha256":"2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
         "macho_sha256":raw["macho_sha256"],
         "constants":{k:raw["constants"][k] for k in ADDRS},
         "device_color_pixel_parity_verified":False}
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"CARD_HEADER_LITERALS.json").write_text(json.dumps(data,indent=2)+"\n")
    print("ORIGINAL_NATIVE12_CARD_HEADER_CONSTS_VERIFIED",len(ADDRS))
if __name__=="__main__":main()
