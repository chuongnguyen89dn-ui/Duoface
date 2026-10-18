#!/usr/bin/env python3
"""Read-only, bounded SidePlay CarPlay window geometry investigation.

Does not modify executable, hook third-party functions, build a DEB or install
anything. Output only static facts + selector sections, never inferred callgraph.
"""
import hashlib
import json
import re
import struct
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
SOURCE = REPO / "sideplay/extracted-1.0.4-1/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib"
INVENTORY = REPO / "sideplay/audit/deb-1.0.4-1/inventory.json"
OUT = REPO / "sideplay/normal-carplay/audit"
TERMS = (
    "carDock", "carDockArea", "carAppArea", "carWindowFrame", "carWindowFrameNow",
    "carDockMode", "autoFitCar", "autoCarArea:", "manualCarArea:", "readPrefs",
    "makeMainScreenWindow", "UIRootSceneWindow", "initWithDisplayConfiguration:",
    "setWindowLevel:", "setFrame:", "safeAreaInsets", "bounds", "screen",
    "area set by hand", "Thanh dock CarPlay", "car screen ", "setCarWindowFrame:",
    "layoutInFrame:scaleMode:", "carFrames", "UIWindow", "CarPlay", "carZoom",
)
META = (
    "__objc_methname", "__objc_selrefs", "__objc_classlist", "__objc_const",
    "__cstring", "__text", "__objc_classname"
)

def cstr(blob: bytes, start: int) -> str:
    return blob[start:start+16].split(b"\x00")[0].decode("utf-8", "replace")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def slices(blob: bytes):
    m = struct.unpack_from(">I", blob)[0]
    if m in (0xcafebabe, 0xcafebabf):
        n = struct.unpack_from(">I", blob, 4)[0]
        long_arch = m == 0xcafebabf
        entsize = 32 if long_arch else 20
        for i in range(min(n, 100)):
            pos = 8 + i*entsize
            if long_arch:
                cpu, subcpu, off, size, align, reserved = struct.unpack_from(">IIQQII", blob, pos)
            else:
                cpu, subcpu, off, size, align = struct.unpack_from(">IIIII", blob, pos)
            if off + size > len(blob):
                raise ValueError("Invalid fat slice bounds")
            yield cpu, subcpu, off, blob[off:off+size]
    else:
        yield 0, 0, 0, blob


def sections(buf: bytes):
    # Standard 64-bit MachO little-endian and 32-bit parsing.
    magic = buf[:4]
    if magic != b"\xcf\xfa\xed\xfe":
        raise ValueError(f"Expected arm64 MH_MAGIC_64; magic={magic.hex()}")
    cpu, subcpu, filetype, ncmd, sizeofcmd, flags, reserved = struct.unpack_from("<IIIIIII",buf,4)
    results = []
    offset = 32
    for _ in range(ncmd):
        cmd, size = struct.unpack_from("<II",buf,offset)
        if size < 8 or offset+size > len(buf):
            raise ValueError("Corrupt MachO load command")
        if cmd == 0x19:
            segname = cstr(buf,offset+8)
            vmaddr,vmsize,fileoff,filesize = struct.unpack_from("<QQQQ",buf,offset+24)
            nsects = struct.unpack_from("<I",buf,offset+64)[0]
            for i in range(nsects):
                p = offset+72+80*i
                if p+80>offset+size:
                    raise ValueError("Corrupt MachO section")
                sectname = cstr(buf,p)
                secsegname = cstr(buf,p+16)
                secaddr, secsize = struct.unpack_from("<QQ",buf,p+32)
                secoff = struct.unpack_from("<I",buf,p+48)[0]
                if secoff+secsize <= len(buf) and secsize<10000000:
                    results.append({"name":sectname,"segment":secsegname,"vmaddr":secaddr,
                                   "size":secsize,"fileoff":secoff})
        offset += size
    return {"cpu":cpu,"subcpu":subcpu,"ncmd":ncmd,"filetype":filetype,"sections":results}


def main():
    binary = SOURCE.read_bytes()
    inv = json.loads(INVENTORY.read_text("utf-8"))
    matched = [x for x in inv if x.get("path") == "var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib" and x["scope"]=="rootfs"]
    if len(matched) != 1 or matched[0]["sha256"] != sha256(binary):
        raise SystemExit("HASH_MISMATCH: file differs from original verified SidePlay.dylib")
    report = {"source_sha256":sha256(binary), "source_bytes":len(binary),
              "verified_against_extracted_inventory":True,
              "timestamp_utc":datetime.now(timezone.utc).isoformat(),"slices":[]}
    for cpu, subcpu, base, blob in slices(binary):
        d=sections(blob)
        d.update({"fat_offset":base,"slice_sha256":sha256(blob),"slice_bytes":len(blob),
                  "strings":[],"string_sections":[],"narrow_scoped_terms":list(TERMS)})
        for x in d["sections"]:
            if x["name"] in META:
                d["string_sections"].append(x)
            if x["name"] in ("__objc_methname", "__cstring", "__objc_classname"):
                chunk=blob[x["fileoff"]:x["fileoff"]+x["size"]]
                for match in re.finditer(rb"[\x20-\x7e]{4,}",chunk):
                    string=match.group().decode("ascii","replace")
                    if any(term.lower() in string.lower() for term in TERMS):
                        d["strings"].append({"section":x["name"],"value":string,
                              "fileoff_hex":hex(x["fileoff"]+match.start()),
                              "vmaddr_hex":hex(x["vmaddr"]+match.start())})
        report["slices"].append(d)
    OUT.mkdir(parents=True,exist_ok=True)
    dest=OUT/"geometry-selector-evidence.json"
    dest.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"hash":report["source_sha256"],"slices":[
        {"cpu":x["cpu"],"subcpu":x["subcpu"],"fileoff":x["fat_offset"],
         "strings":len(x["strings"]),"objc_terms":[v for v in x["strings"] if
              v["value"] in ("carDockArea","carAppArea","carDockMode","carWindowFrame","setWindowLevel:","makeMainScreenWindow","safeAreaInsets")]}
        for x in report["slices"]]},ensure_ascii=False,indent=2))

if __name__=="__main__":
    main()
