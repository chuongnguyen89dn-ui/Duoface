#!/usr/bin/env python3
"""Read-only SHA-verified original Native12 vs independent .53 real DEB scan."""
import argparse,hashlib,json,pathlib,subprocess
KEYS=["CBMultitaskingOverlayView","setupCardContent","setupAppPickerCardsInCardW",
"setupRecentAppsCardsInCardW","showAppPickerForSlot","dismissOverlay","appSelected:",
"_appSegmentBtn","_layoutSegmentBtn","_recentSegmentBtn","DuoFace",
"native12-action-row","native12-ellipsis","native12-zoom-button-touchdown",
"Zoom In","Zoom Out","DFNative12Chrome"]
def run(*args,check=True):
 p=subprocess.run(args,text=True,capture_output=True)
 if check and p.returncode:raise RuntimeError(repr(args)+": "+p.stderr[:500])
 return p.stdout
def sha(p):
 return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
def scan(name,deb,expected,out):
 deb=pathlib.Path(deb)
 if sha(deb)!=expected:raise ValueError(name+" HASH MISMATCH")
 dest=out/name;dest.mkdir(parents=True,exist_ok=True)
 run("dpkg-deb","-x",str(deb),str(dest))
 entries=[]
 for p in sorted(dest.rglob("*")):
  if not p.is_file() or p.is_symlink():continue
  typ=run("file","-b",str(p),check=False)
  if "Mach-O" not in typ:continue
  strings=run("strings","-a",str(p),check=False)
  objc=run("otool","-ov",str(p),check=False)
  markers={k:{"strings":k in strings,"objc":k in objc} for k in KEYS if k in strings or k in objc}
  entries.append({"file":str(p.relative_to(dest)),"sha256":sha(p),"size":p.stat().st_size,"markers":markers})
 return {"package":run("dpkg-deb","-f",str(deb),"Package").strip(),
 "version":run("dpkg-deb","-f",str(deb),"Version").strip(),
 "sha256":expected,"files":sum(p.is_file() for p in dest.rglob("*")),
 "macho":entries,"present":sorted(set(k for x in entries for k in x["markers"]))}
def main():
 a=argparse.ArgumentParser()
 for n in ["original","current","original_sha","current_sha","out"]:
  a.add_argument("--"+n.replace("_","-"),required=True)
 z=a.parse_args();out=pathlib.Path(z.out);out.mkdir(parents=True,exist_ok=True)
 original=scan("original",z.original,z.original_sha,out)
 current=scan("current",z.current,z.current_sha,out)
 assert len(original["macho"])>=6
 assert "CBMultitaskingOverlayView" in original["present"]
 assert "setupCardContent" in original["present"]
 assert "DFNative12Chrome" in current["present"]
 result={"original":original,"current":current,
 "limitation":"Actual binary selector scan; not on-device tap or UI parity."}
 (out/"DEB_BINARY_CROSSWALK.json").write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
 report=["# Original Native12 Speed8 vs DuoFace .53: actual DEB re-scan","",
 "Original DEB SHA256: "+original["sha256"],
 "Current signed .53 DEB SHA256: "+current["sha256"],
 "Original package/version: "+original["package"]+" "+original["version"],
 "Current package/version: "+current["package"]+" "+current["version"],
 "Original Mach-O count: "+str(len(original["macho"])),
 "Current Mach-O count: "+str(len(current["macho"])),"",
 "## Original Objective-C selector evidence from extracted Mach-O"]
 for key in KEYS:
  hits=[x["file"] for x in original["macho"] if key in x["markers"]]
  report.append("- "+key+": "+(", ".join(hits) if hits else "not seen"))
 report.extend(["","## Independent .53 actual binary evidence"])
 for key in KEYS:
  hits=[x["file"] for x in current["macho"] if key in x["markers"]]
  report.append("- "+key+": "+(", ".join(hits) if hits else "not seen"))
 report.extend(["","## 2026-10-23 physical screenshot comparison",
 "The user photo shows only a narrow custom floating App / Zoom In / Style",
 "/ Close strip covering two empty panes. The original DEB has native",
 "CBMultitaskingOverlayView card lifecycle, setupCardContent and app",
 "card method machinery. A lone 30pt detached toolbar cannot substitute",
 "for that modal content. This report is real binary inspection and does",
 "not authorize copying any proprietary license or binary.",
 "The current unbuilt source change opening the existing complete first-party",
 "App card is a candidate, not yet validated visually or on device.",
 "For whole-host Zoom: real touch dispatch -> global Zoom -> actual native",
 "CarPlay Dock hidden -> both scene panes fill screen -> reversible restore.",
 "Selector presence never proves execution."])
 (out/"REPORT.md").write_text("\n".join(report)+"\n")
 print("EXACT_DEB_SHA_AND_MACHO_RESCAN_OK",len(original["macho"]),len(current["macho"]))
 print("ORIGINAL_NATIVE_OVERLAY_AND_APP_CARD_EVIDENCE",sorted(set(original["present"]).intersection(KEYS)))
if __name__=="__main__":main()
