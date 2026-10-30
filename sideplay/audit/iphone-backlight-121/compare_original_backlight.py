#!/usr/bin/env python3
"""READ ONLY: inspect SHA-pinned original DuoNavi & OmniCar DEB Mach-O strings.

No binaries, third-party source or licensed code are saved into the report.
Presence of a selector is NOT evidence the original vendor calls it or that it
keeps a screen lit: always distinguish referenced symbols from runtime effects.
"""
import argparse, hashlib, json, pathlib, re, subprocess, tempfile, datetime

DUONAVI_SHA="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
OMNICAR_SHA="d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd"
KEYWORDS=[
 "backlight","brightness","idletimer","idleTimer","idleSleep","keepAwake",
 "wakeLock","preventSleep","preventIdle","powerAssertion","sleepAssertion",
 "displaySleep","setIdle","isUILocked","isScreenOn","screenIsOn",
 "screenIsDim","lockState","lockstate","lockScreen","unlock","displayOff",
 "turnOnScreen","turnOffScreen","setScreen","screenBrightness",
 "autoLock","auto-lock","CADisplay","UIScreen","videoPlayback","foreground",
 "background","RunningBoard","BKSProcessAssertion","RBSAssertion",
 "AVAudioSession","AVPlayer","_setHidden","setHidden"
]
PATTERN=re.compile("|".join(map(re.escape,KEYWORDS)),re.I)
INTERESTED=("Backlight","Brightness","Idle","Sleep","Locked","Screen","Display","Power","Assertion","Foreground","Background")
def sha(path):
    h=hashlib.sha256()
    with open(path,"rb") as f:
        for chunk in iter(lambda:f.read(1024*1024),b""):h.update(chunk)
    return h.hexdigest()

def is_macho(path):
    with open(path,"rb") as f:head=f.read(4)
    return head in (bytes.fromhex("cffaedfe"),bytes.fromhex("feedfacf"),
                    bytes.fromhex("cafebabe"),bytes.fromhex("bebafeca"),
                    bytes.fromhex("cafebabf"),bytes.fromhex("bfbafeca"))
def examine(root, label):
    found=[]
    for f in sorted(root.rglob("*")):
        if not f.is_file() or f.stat().st_size<64 or f.stat().st_size>100*1024*1024:continue
        if not is_macho(f):continue
        strings=subprocess.run(["strings","-a","-n","5",str(f)],capture_output=True,text=True,errors="replace",check=True).stdout
        sleep_hints=sorted(set(x.strip()[:160] for x in strings.splitlines()
                               if re.search(r"(?i)(?:IOPM|assertion|preventuser|idle.?sleep|sleep.?assertion|backlight|screen.?blank|underlock)",x) and len(x)<260))
        hits=sorted(set(x.strip()[:180] for x in strings.splitlines()
                        if PATTERN.search(x) and len(x)<300))
        sensitive=lambda v:any(k.lower() in v.lower() for k in INTERESTED)
        relevant=[h for h in hits if sensitive(h)]
        found.append({"binary":str(f.relative_to(root)),"sha256":sha(f),
                      "candidateCount":len(hits),"sleepPolicyCandidates":sleep_hints[:130],"selected":relevant[:125],
                      "other": [x for x in hits if not sensitive(x)][:55]})
    return found

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--duonavi",required=True)
    ap.add_argument("--omnicar",required=True)
    ap.add_argument("--out",required=True)
    args=ap.parse_args()
    source=[("DuoNavi_1.0.4",pathlib.Path(args.duonavi),DUONAVI_SHA,"com.duonavi.app"),
            ("OmniCar_1.0.3",pathlib.Path(args.omnicar),OMNICAR_SHA,"com.anlai.omnicar")]
    output={}
    with tempfile.TemporaryDirectory(prefix="backlight-audit-") as temp:
        for name,deb,expected,pkg in source:
            observed=sha(deb)
            if observed!=expected:raise SystemExit(name+" SHA mismatch "+observed)
            current_pkg=subprocess.check_output(["dpkg-deb","-f",str(deb),"Package"],text=True).strip()
            if current_pkg!=pkg:raise SystemExit(name+" package name mismatch "+current_pkg)
            dest=pathlib.Path(temp)/name
            dest.mkdir()
            subprocess.run(["dpkg-deb","-x",str(deb),str(dest)],check=True)
            output[name]={"DEB_sha256":observed,"package":pkg,"MachOBinaries":examine(dest,name)}
    # Source code strings can prove missing native iPhone idle handling in QA120,
    # but cannot prove the exact runtime origin of a Play failure.
    out=pathlib.Path(args.out);out.mkdir(parents=True,exist_ok=True)
    (out/"ORIGINAL_BACKLIGHT_KEYWORDS.json").write_text(json.dumps(output,indent=2,ensure_ascii=False)+"\n")
    lines=["# Original DuoNavi / OmniCar — backlight, idle, lock and foreground binary crosscheck",
           "","This is **read-only SHA-checked binary string metadata**, not decompilation of playback",
           "or a proof which original method executes. Does not ship original binary or license.","",
           "Hardware report QA120: sizing **works**; YouTube scrolling and other taps **work**,",
           "but Play requires visibly lit iPhone. In originals, phone remains dimly lit.",
           "A screen illumination correlation alone cannot distinguish media foreground policy",
           "from touch target, app suspension, screen power and audio-session state.","",
           "## Original signed reference identity",""]
    for label,row in output.items():
        lines += [f"### {label}",f"- Package: `{row['package']}`",
                  f"- Original exact SHA256: `{row['DEB_sha256']}`",
                  f"- Mach-O files scanned: {len(row['MachOBinaries'])}",""]
        for b in row["MachOBinaries"]:
            hints=b["sleepPolicyCandidates"]
            if hints:
                lines += [f"#### Original power/sleep candidate metadata from {b['binary']}"]
                lines += [f"- {x[:150]}" for x in hints[:120]]
                lines += [""]
            hits=b["selected"]
            if not hits:continue
            lines += [f"#### `{b['binary']}`",f"- SHA256: `{b['sha256']}`",
                      f"- Backlight/idle/screen/foreground-related string candidates ({len(hits)} shown):"]
            lines += [f"  - `{x.replace(chr(96),chr(39))}`" for x in hits[:120]]
            lines += [""]
    lines += ["## Next precise gate","",
              "- Presence/absence of `SBBacklightController`, `setIdleTimerDisabled:forReason:`, `_setScreenBrightness:` or another selector is **not a proof** of execution or causal dependency.",
              "- If strong candidates appear, disassemble exact original owner callsites + compare first-party current source; preserve system lock and avoid indefinite full-brightness display.",
              "- If absent, identify YouTube UIApplication/scene activation while iPhone locked vs awake with a minimal read-only app-process state probe, and distinguish Play from scrolling.",
              "- Preserve QA120 measured native geometry, .90 video rotation, .92 controls; do not publish guessed fixes or copy the original payload."]
    (out/"REPORT.md").write_text("\n".join(lines)+"\n")
    print("BACKLIGHT_121_SHA_PINNED_READONLY_AUDIT_PASS",[(k,len(v["MachOBinaries"])) for k,v in output.items()])
if __name__=="__main__":main()
