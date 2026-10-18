#!/usr/bin/env python3
"""Reconstruct an editable ZIP of the available Native12/HUD8-era text code.

This does NOT recover the absent original source of DuoFaceUI or
DuoFaceDashboard.dylib, which are compiled Mach-O ARM64 in the DEB.

Run:
  python3 exports/extract_native12_hud8_txt_to_zip.py --input <downloaded TXT>
or, with internet:
  python3 exports/extract_native12_hud8_txt_to_zip.py
"""
from __future__ import annotations
import argparse
import pathlib
import re
import urllib.request
import zipfile

PINNED = "f4de581f740885a236b5f2c59e4872d91b5f6ee5"
URL = ("https://raw.githubusercontent.com/chuongnguyen89dn-ui/Duoface/"
       + PINN + "/exports/DuoFace_Native12_HUD8_available_source_20261018.txt")
BEGIN = re.compile(r"^########## BEGIN FILE: (.+) ##########\n", re.M)

def sources(text: str):
    matches = list(BEGIN.finditer(text))
    if len(matches) != 143:
        raise ValueError("Expected exactly 143 embedded source files; got " + str(len(matches)))
    names = set()
    for idx, match in enumerate(matches):
        name = match.group(1)
        path = pathlib.PurePosixPath(name)
        if name in names or name.startswith("/") or any(p in ("..",".") for p in path.parts):
            raise ValueError("Invalid or duplicate path: " + name)
        names.add(name)
        end = "########## END FILE: " + name + " ##########\n"
        end_at = text.find(end, match.end())
        if end_at == -1 or (idx+1 < len(matches) and end_at > matches[idx+1].start()):
            raise ValueError("Missing END marker: " + name)
        yield name, text[match.end():end_at].encode("utf-8")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", type=pathlib.Path, help="Locally downloaded GitHub TXT")
    ap.add_argument("--output", type=pathlib.Path,
                    default=pathlib.Path("DuoFace_Native12_HUD8_source_available.zip"))
    a = ap.parse_args()
    if a.input:
        raw = a.input.read_bytes()
    else:
        req = urllib.request.Request(URL, headers={"User-Agent": "DuoFaceSourceExporter/1"})
        with urllib.request.urlopen(req, timeout=45) as response:
            raw = response.read()
    data = raw.decode("utf-8")
    a.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(a.output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("README_SCOPE.txt",
            "This contains available source only; complete original Native12 "
            "DuoFaceUI/DuoFaceDashboard source is NOT present in the repo.\n")
        for path, content in sources(data):
            archive.writestr(path, content)
    with zipfile.ZipFile(a.output) as check:
        assert check.testzip() is None
        assert len(check.namelist()) == 144
    print(f"Source ZIP ready: {a.output}")

if __name__ == "__main__":
    main()
