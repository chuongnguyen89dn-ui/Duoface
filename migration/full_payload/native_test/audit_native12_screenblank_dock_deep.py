#!/usr/bin/env python3
"""Exact native12 deeper static audit: iPhone Screen Blank and CarPlay Dock System Monitor.

Scope: read-only Objective-C metadata, selectors, ARM64 disassembly with literal hints,
and xref candidates. Never install/patch the package or claim real iPhone behavior.
"""
from __future__ import annotations
import argparse, hashlib, json, re, subprocess, tempfile
from pathlib import Path
from audit_native12_license_class_xrefs import MachO, select_arm64, BINARIES, NATIVE12_SHA
from audit_native12_carplay_add_app_chain import methods, disassemble

DIGESTS={
    "DuoFaceUI":"cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
    "DuoFaceDashboard":"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
}
OWNERS={
    "DuoFaceUI":(
        "CBGeneralSettingsViewController",
    ),
    "DuoFaceDashboard":(
        "CBDashboardSettings",
        "CBDockSystemMonitorView",
        "CBBridgeManager",
        "CBBridgedPortalAppView",
        "CBWindow",
    ),
}
KEYWORDS=re.compile(
    r"screenBlank|screenblank|blank|brightness|idleTimer|lockDevice|lockScreen|"
    r"setBacklight|thermal|temperature|battery|cpu|dockSystemMonitor|"
    r"startMonitoring|stopMonitoring|readCpuUsage|host_statistics|"
    r"mach_host|sysctl|processInfo|createTimer|schedule|setHidden|"
    r"setAlpha|isCarPlay|settingsChanged|connectionChanged|"
    r"monitor|refresh|update|displayLink",re.I
)
LITERALS=[
"screenBlankEnabled","setScreenBlankEnabled:",
"dockMonitorEnabled","dockMonitorToggleChanged:","dockSystemMonitorEnabled",
"setDockSystemMonitorEnabled:","dockSystemMonitorShowAll",
"screenBlankToggleChanged:","readCpuUsage","startMonitoring",
"stopMonitoring","updateMonitoring","thermalState","thermalStateDidChangeNotification",
"batteryLevel","batteryState","temperature","CPU","sysctlbyname",
"host_statistics","task_info","processInfo","CADisplayLink",
"setBrightness:","brightness","setIdleTimerDisabled:","lockDevice",
"SBDimScreenManager","SBBacklightController","SBAwayController",
"setScreenBlankEnabled:","applyScreenBlank","setScreenBlank:",
"UIWindow","isCarPlayConnected","carPlayConnected",
]
FOCUS={
"DuoFaceUI":{
  "CBGeneralSettingsViewController":{
      "screenBlankToggleChanged:","dockMonitorToggleChanged:","loadPreferences",
      "savePreferences","viewDidLoad","screenBlankEnabled","dockMonitorEnabled",
      "setScreenBlankEnabled:","setDockMonitorEnabled:",
  },
},
"DuoFaceDashboard":{
  "CBDashboardSettings":{
      "screenBlankEnabled","setScreenBlankEnabled:","dockSystemMonitorEnabled",
      "setDockSystemMonitorEnabled:","dockSystemMonitorShowAll",
      "reloadAppPrefs","reload","init","load",
  },
  "CBDockSystemMonitorView":{"startMonitoring","stopMonitoring","readCpuUsage",
      "layoutSubviews","dealloc","init","initWithFrame:","isMonitoring"},
  "CBBridgeManager":{"handleSettingsChanged","handleCarPlayConnectionChanged:",
      "handleCarPlayDisconnected","startMonitoring","stopMonitoring","init"},
  "CBBridgedPortalAppView":{"displayLink","setDisplayLink:"},
  "CBWindow":{"layoutSubviews","init","setHidden:"},
},
}
# Cap report size. The selected full disassembly files are saved for certain owner methods
# only; selections are evidence of selector presence, not automated proof of invocation.
IMPORTANT_INSTRUCTION=re.compile(
   r"SEL_OR_LITERAL|DIRECT_STRING|bl #|blr |mov |cmp |cbz |cbnz |tbz |tbnz",re.I)
def sha(b):return hashlib.sha256(b).hexdigest()

def inspect_binary(name,raw):
    assert sha(raw)==DIGESTS[name],(name,sha(raw))
    m=MachO(select_arm64(raw))
    all_classes=m.classes()
    strings={}
    for term in LITERALS:
        count=len(list(re.finditer(re.escape(term.encode()),raw)))
        strings[term]=count
    relevant_strings={k:v for k,v in strings.items() if v}
    out={"sha256":sha(raw),"class_count":len(all_classes),
         "raw_literal_counts":relevant_strings,"owner_method_lists":{},
         "selected_method_disassembly":{},"selector_site_candidates":[]}
    for c in OWNERS[name]:
        if c not in all_classes:continue
        method_catalog=methods(m,c)
        out["owner_method_lists"][c]=sorted(method_catalog.keys())
        entries=sorted({int(item["vm"]) for item in method_catalog.values() if item["vm"]})
        for target in FOCUS.get(name,{}).get(c,()):
            match=method_catalog.get("-"+target) or method_catalog.get("+"+target)
            if not match: continue
            begin=int(match["vm"]);end=next((v for v in entries if v>begin),begin+2400)
            dis=disassemble(m,begin,min(end,begin+12000))
            # Full disassembly for concise, targeted methods; selected instructions otherwise.
            full=len(dis)<=220 or target in {
                "startMonitoring","stopMonitoring","readCpuUsage",
                "screenBlankToggleChanged:","dockMonitorToggleChanged:",
                "screenBlankEnabled","setScreenBlankEnabled:",
                "dockSystemMonitorEnabled","setDockSystemMonitorEnabled:"}
            out["selected_method_disassembly"][c+"."+target]={
                 "vm":hex(begin),"method_end_estimate":hex(end),
                 "type":match["type"],"decoded_instructions":len(dis),
                 "truncated_by_disassembler":len(dis)>=1401,
                 "full_instructions":dis if full else [],
                 "relevant_instructions":[s for s in dis if KEYWORDS.search(s)][:140],
                 "selector_hints":[s for s in dis if "SEL_OR_LITERAL" in s or "DIRECT_STRING" in s][:140],
                 "head":dis[:18],
            }
    # List all candidate native code callsites where the selector reference is recognized.
    # Do not infer definite behavior from absence: swizzling, IMP pointers and dynamic
    # dispatch can evade this heuristic. Keep only selector hints, never assume call executed.
    if name=="DuoFaceDashboard":
        for c in sorted(all_classes):
            catalog=methods(m,c)
            entries=sorted({int(item["vm"]) for item in catalog.values() if item["vm"]})
            for method,item in catalog.items():
                vm=int(item["vm"] or 0)
                if not vm:continue
                end=next((v for v in entries if v>vm),vm+240)
                dis=disassemble(m,vm,min(end,vm+2400))
                selected=[]
                for i,ln in enumerate(dis):
                    if ("SEL_OR_LITERAL" in ln or "DIRECT_STRING" in ln) and KEYWORDS.search(ln):
                        selected.append({"at":ln,"next_calls":[s for s in dis[i+1:i+9] if "bl " in s or "blr " in s][:2]})
                if selected:
                    out["selector_site_candidates"].append({"class":c,"method":method,"vm":hex(vm),"hints":selected[:15]})
    return out

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    original=a.deb.read_bytes()
    assert sha(original)==NATIVE12_SHA
    assert subprocess.check_output(["dpkg-deb","-f",str(a.deb),"Version"],text=True).strip()=="0.1.0~native12"
    with tempfile.TemporaryDirectory(prefix="df-native12-dock-screen-readonly-") as td:
        subprocess.run(["dpkg-deb","-x",str(a.deb),td],check=True)
        evidence={name:inspect_binary(name,(Path(td)/rel).read_bytes()) for name,rel in BINARIES.items()}
    report={
      "status":"NATIVE12_SCREEN_BLANK_AND_DOCK_DEEP_STATIC_READONLY_PASS",
      "baseline_sha256":NATIVE12_SHA,
      "native12_exact_file_repackaged":False,
      "device_screen_tested":False,
      "dock_values_tested":False,
      "test_limitations":"Static Objective-C metadata and disassembly heuristics only; no runtime, no thermistor or per-process metrics",
      "binaries":evidence,
    }
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    for name,data in evidence.items():
        print("BINARY",name,"METHODS",len(data["selected_method_disassembly"]))
        print("SIGNATURES",data["raw_literal_counts"])
        for key,m in data["selected_method_disassembly"].items():
            print("OWNER",key,"vm",m["vm"],"instructions",m["decoded_instructions"],
                  "hints",m["selector_hints"][:12])
        print("SELECTOR_SITE_TOTAL",len(data["selector_site_candidates"]))
    print("NATIVE12_SCREEN_BLANK_DOCK_DEEP_STATIC_READONLY_PASS")
if __name__=="__main__": main()
