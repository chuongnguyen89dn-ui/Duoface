#!/usr/bin/env python3
"""Static read-only inspection of DuoFace native12 connect/disconnect/audio markers.
Does not alter Mach-Os, launch apps, contact a phone or decide feature presence
solely from class/selector names.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

from audit_native12_license_class_xrefs import MachO, select_arm64

SHA = "85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
HOSTS = {
    "DuoFaceUI": "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard": "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
# Exact markers are evidence of textual references/ObjC metadata, not proof of
# functional behavior nor proof that unlisted code paths do not exist.
GROUPS = {
    "auto_launch": r"autolaunch|auto.?start|start.?on.?connect|launch.?bundle|launch.?app",
    "carplay_connect": r"carplay.{0,40}connect|connect.{0,25}carplay|uiscreen.?didconnect|cp.?connected|iscarplayscreen",
    "carplay_disconnect": r"carplay.{0,45}disconnect|disconnect.{0,30}carplay|uiscreen.?diddisconnect|disconnected|disconnect.?close",
    "audio_media": r"avaudiosession|audioroute|routechange|mediaremote|nowplaying|mpmusicplayer|pause.?playback|music|media.?player|sendcommand",
    "terminate": r"terminateapp|terminateall|close.?app|kill.?app|stop.?app|deactivatecurrent|deactivateapp|exit.?app",
    "restore": r"restore.?session|last.?session|previous.?app|bridgedapps|splitapp[1-4]|split(left|right)bundle|session.?snapshot",
}
KEEP_CLASSES = re.compile(r"settings|bridgemanager|dashboard|audio|media|music|appdelegate|rootview|application|carplay",re.I)
KEEP_SELECTORS = re.compile(
    "|".join(GROUPS.values()) + r"|bridgeDid(Activate|Deactivate):|handleStateDict:|reloadAppPrefs|savePreferences",
    re.I,
)

def printable_markers(data, pat):
    found=[]
    for mat in re.finditer(rb"[\x20-\x7e]{4,}", data):
        try: s=mat.group(0).decode("ascii")
        except UnicodeDecodeError: continue
        if len(s)>240 or not pat.search(s): continue
        found.append({"offset":hex(mat.start()),"value":s})
    return found

def inspect(name, raw):
    arm=select_arm64(raw)
    mo=MachO(arm)
    cls=mo.classes()
    matches={}
    for tag,pattern in GROUPS.items():
        pat=re.compile(pattern,re.I)
        entries=printable_markers(arm,pat)
        matches[tag]={"count":len(entries),"entries":entries[:100]}
    selected_classes={}
    selected_methods=[]
    for class_name,meta in cls.items():
        if KEEP_CLASSES.search(class_name):
            selected_classes[class_name]={"method_count":len(meta["methods"]),
                "methods_of_interest":[m for m in meta["methods"] if KEEP_SELECTORS.search(m)][:90]}
        for method in meta["methods"]:
            if KEEP_SELECTORS.search(method):
                selected_methods.append({"class":class_name,"method":method})
    return {
        "binary_sha256":hashlib.sha256(raw).hexdigest(),
        "arm64_sha256":hashlib.sha256(arm).hexdigest(),
        "objc_class_count":len(cls),
        "objc_method_count":sum(len(x["methods"]) for x in cls.values()),
        "selected_objc_classes":selected_classes,
        "selected_methods":selected_methods[:400],
        "static_string_groups":matches,
        "proves_event_route_or_music_shutdown":False,
        "absence_of_marker_proves_absence_of_behavior":False,
    }

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb", type=Path,required=True)
    p.add_argument("--out", type=Path,required=True)
    a=p.parse_args()
    raw=a.deb.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SHA:raise SystemExit("native12 immutable DEB SHA256 mismatch")
    with tempfile.TemporaryDirectory(prefix="df12-connect-audio-") as root:
        subprocess.run(["dpkg-deb","-x",str(a.deb),root],check=True)
        bins={name:inspect(name,(Path(root)/path).read_bytes()) for name,path in HOSTS.items()}
    report={
        "status":"DUOFACE_NATIVE12_CONNECTION_AUDIO_STATIC_READONLY",
        "deb_sha256":SHA,
        "tool_method":"read-only Mach-O arm64 ObjC methods and relevant ASCII literals",
        "package_modified":False,
        "feature_implemented":False,
        "device_audio_test_completed":False,
        "event_callgraph_completed":False,
        "no_definitive_absence_claim":True,
        "binaries":bins,
    }
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    for name,item in bins.items():
        print(name,"ObjC classes",item["objc_class_count"],
              "matched selectors",len(item["selected_methods"]))
        print(name,"string group counts",{k:v["count"] for k,v in item["static_string_groups"].items()})
    print("DONE static read-only: does not prove dispatch behavior or absence of music shutdown")

if __name__=="__main__":main()
