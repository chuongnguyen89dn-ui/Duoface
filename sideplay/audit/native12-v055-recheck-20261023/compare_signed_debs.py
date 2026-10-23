#!/usr/bin/env python3
"""Compare exact original Native12 DEB, staged .54, staged .55 Mach-O binaries.
All three actual DEBs must match pinned SHA256 before extraction. No install,
signing, runtime patch, or public Sileo modifications.
"""
from pathlib import Path
from hashlib import sha256
from collections import defaultdict
import argparse
import json
import subprocess
import sys
import tempfile

here=Path(__file__).resolve().parent
sys.path.insert(0,str(here.parent/"native12-modal-recheck-20261023"))
from scan_two_debs import scan, KEYS

def exact(p):
    return sha256(Path(p).read_bytes()).hexdigest()

def main():
    parser=argparse.ArgumentParser()
    for field in ("original","previous","candidate","original_sha","previous_sha","candidate_sha","out"):
        parser.add_argument("--"+field.replace("_","-"),required=True)
    a=parser.parse_args()
    paths={"original":a.original,"previous54":a.previous,"candidate55":a.candidate}
    hashes={"original":a.original_sha,"previous54":a.previous_sha,"candidate55":a.candidate_sha}
    out=Path(a.out)
    out.mkdir(parents=True,exist_ok=True)
    result={}
    # Extract real third-party evidence to ephemeral space, NOT a GitHub repo.
    with tempfile.TemporaryDirectory(prefix="duoface-deb-compare-") as temp:
        for name in paths:
            assert exact(paths[name])==hashes[name],name+" UNSIGNED OR WRONG BIN"
            result[name]=scan(name,paths[name],hashes[name],Path(temp))
    assert result["original"]["version"]=="0.1.0~native12+speed8compact"
    assert result["previous54"]["version"]=="0.0.54~nativecard1"
    assert result["candidate55"]["version"]=="0.0.55~zoomgrip1"
    for name in ("previous54","candidate55"):
        assert result[name]["package"]=="com.duoface.jb.embedded"
    a54={x["file"]:x for x in result["previous54"]["macho"]}
    a55={x["file"]:x for x in result["candidate55"]["macho"]}
    changed=[{"path":p,
               "54_sha256":a54[p]["sha256"] if p in a54 else None,
               "55_sha256":a55[p]["sha256"] if p in a55 else None}
             for p in sorted(set(a54)|set(a55))
             if p not in a54 or p not in a55 or a54[p]["sha256"]!=a55[p]["sha256"]]
    payloadOriginal={x["file"] for x in result["original"]["macho"]}
    payloadNew={x["file"] for x in result["candidate55"]["macho"]}
    originalClassEvidence="CBMultitaskingOverlayView" in result["original"]["present"]
    independentClassEvidence="DFNative12Chrome" in result["candidate55"]["present"]
    assert originalClassEvidence and independentClassEvidence
    # Different class owner is NOT equivalent to original pixel/behavior
    # equality. This audit is a strict byte/ObjC metadata comparison only.
    obj={
      "sources":{k:{"package":v["package"],"version":v["version"],"sha256":v["sha256"],
                     "mach_o_count":len(v["macho"]),"payload_file_count":v["files"]}
                 for k,v in result.items()},
      "macho_changed_54_to_55":changed,
      "original_native_methods":sorted(set(result["original"]["present"])&set(KEYS)),
      "candidate_method_markers":sorted(set(result["candidate55"]["present"])&set(KEYS)),
      "original_only_macho":sorted(payloadOriginal-payloadNew),
      "candidate_only_macho":sorted(payloadNew-payloadOriginal),
      "native_original_picker_class_found":originalClassEvidence,
      "independent_picker_class_found":independentClassEvidence,
      "pixel_parity_proven":False,
      "real_carplay_zoom_proven":False,
      "real_3_second_logo_movement_proven":False,
      "scope":"actual pinned DEB static binary, extracted metadata and hashes ONLY",
      "binary_inventory":result
    }
    (out/"ACTUAL_DEB_CROSSWALK.json").write_text(json.dumps(obj,ensure_ascii=False,indent=2)+"\n")
    md=[
       "# Actual signed Native12 original vs .54 vs .55 DEB binary comparison",
       "",
       "Evidence: exact downloads, pinned SHA256 verification, dpkg-deb extraction,",
       "Mach-O inventory, sha256 per Mach-O, Objective-C metadata with otool.",
       "No UIKit rendering, installed hardware logs, or entitlement-based CarPlay PASS.",
       "",
       "| Verified package | Version | SHA256 | Mach-O |",
       "|---|---|---|---:|"
    ]
    for k in ("original","previous54","candidate55"):
        v=result[k]
        md.append("| "+v["package"]+" | "+v["version"]+" | `"+v["sha256"]+"` | "+str(len(v["macho"]))+" |")
    md += ["","## Actual changed ARM64 images from .54 to .55"]
    for row in changed:
        md.append("- `"+row["path"]+"`: "+str(row["54_sha256"])+" → "+str(row["55_sha256"]))
    md += ["","## Original vs independent owner/selector proof"]
    for key in KEYS:
        orig=[x["file"] for x in result["original"]["macho"] if key in x["markers"]]
        cand=[x["file"] for x in result["candidate55"]["macho"] if key in x["markers"]]
        md.append("- `"+key+"`: original "+str(orig)+"; .55 "+str(cand))
    md += ["","## Verdict boundary",
      "- Native12 original CBMultitaskingOverlayView != independent DFNative12Chrome class; historical binary owner method evidence cannot be equated with current independent implementation.",
      "- Presence of a binary string or Objective-C selector does NOT prove CarPlay touch invocation or physical Dock hide.",
      "- Source and packaging CI passing does NOT prove exact original UI/behavior. Real fullscreen, logo 3s, ratio, video crashing, auto-hide, and restore require device QA.",
      "- No licensing framework or proprietary implementation has been imported through this forensic read-only workflow."
    ]
    (out/"REPORT.md").write_text("\n".join(md)+"\n")
    print("ORIGINAL_54_55_EXACT_DEB_SCAN_PASS")
    print("ACTUAL_CHANGED_IMAGES",json.dumps(changed))
    print("NATIVE12_ORIGINAL_CLASSS",originalClassEvidence,"INDEPENDENT_CLASS",independentClassEvidence)

if __name__=="__main__":
    main()
