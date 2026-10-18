#!/usr/bin/env python3
"""Inspect original SidePlay iPhone X arm64 ObjC dock/window methods, read-only.

Produces a bounded text report from llvm-objdump. No binary modifications.
Not a claim that matching selector strings prove runtime execution.
"""
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[3]
MODULE=ROOT/"sideplay/normal-carplay/tools/trace_window_geometry.py"
OUT=ROOT/"sideplay/normal-carplay/audit/geometry-objc-window-trace.txt"
SELECTORS=re.compile(
    r"carDockArea|carAppArea|carDockMode|carWindowFrame|makeMainScreenWindow|"
    r"setWindowLevel:|safeAreaInsets|autoCarArea:|setCarWindowFrame:",
    flags=re.I)

def bounded(text, context=15, max_matches=60):
    lines=text.splitlines()
    positions=[i for i,x in enumerate(lines) if SELECTORS.search(x)][:max_matches]
    keep=set()
    for i in positions:
        keep.update(range(max(0,i-context),min(len(lines),i+context+1)))
    return "\n".join(f"{i+1:06d} {lines[i]}" for i in sorted(keep))

def main():
    spec=importlib.util.spec_from_file_location("sideplay_geometry",MODULE)
    mod=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    original=mod.SOURCE.read_bytes()
    inventory=json.loads(mod.INVENTORY.read_text("utf-8"))
    match=[x for x in inventory if x.get("scope")=="rootfs" and x.get("path")==
       "var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib"]
    if len(match)!=1 or match[0]["sha256"]!=mod.sha256(original):
        raise SystemExit("Original SidePlay.dylib checksum changed; REFUSE")
    slices=[x for x in mod.slices(original) if x[0]==0x100000c and x[1]==0]
    if len(slices)!=1:
        raise SystemExit("Expected exactly one arm64 slice")
    llvm=shutil.which("llvm-objdump")
    if not llvm:
        for name in ("llvm-objdump-22","llvm-objdump-21","llvm-objdump-20","llvm-objdump-19",
                     "llvm-objdump-18","llvm-objdump-17","llvm-objdump-16","llvm-objdump-15",
                     "llvm-objdump-14"):
            llvm=shutil.which(name)
            if llvm: break
    if not llvm:
        raise SystemExit("No llvm-objdump installed")
    with tempfile.TemporaryDirectory() as t:
        thin=Path(t)/"sideplay-arm64"
        thin.write_bytes(slices[0][3])
        notes=[
            "# Original SidePlay arm64 static geometry/ObjC trace",
            f"original_dylib_sha256={mod.sha256(original)}",
            f"arm64_slice_sha256={mod.sha256(slices[0][3])}",
            f"arm64_slice_size={len(slices[0][3])}",
            f"llvm_tool={llvm}",
            "# Binary not executed, edited, installed or packaged.",
            "",
        ]
        for title,args in (
            ("SECTION HEADERS",["--macho","--section-headers"]),
            ("OBJC METADATA",["--macho","--objc-meta-data"]),
            ("ARM64 DISASSEMBLY SELECTOR ANNOTATIONS",["--macho","--disassemble"]),
        ):
            result=subprocess.run([llvm,*args,str(thin)],
                stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,errors="replace")
            out=result.stdout+("\nSTDERR: "+result.stderr if result.stderr else "")
            notes += [
                "## "+title,
                "tool_exit="+str(result.returncode)+" lines="+str(len(out.splitlines())),
                bounded(out,5 if title=="SECTION HEADERS" else 15),
                "FIRST_OUTPUT_LINES (to detect unsupported flags):",
                "\n".join(out.splitlines()[:15]),
                "",
            ]
        OUT.parent.mkdir(parents=True,exist_ok=True)
        OUT.write_text("\n".join(notes)+"\n",encoding="utf-8")
        print("wrote",OUT,"bytes",OUT.stat().st_size)
        for s in notes:
            if s.startswith("tool_exit="):
                print(s)

if __name__=="__main__":
    main()
