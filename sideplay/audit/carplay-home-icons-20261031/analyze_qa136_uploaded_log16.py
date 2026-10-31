#!/usr/bin/env python3
"""Audit real user-uploaded Log16 vs QA136 and original DEB Home callsites.
No raw session diagnostics or app identifiers are persisted.
"""
import argparse
import collections
import hashlib
import json
import pathlib
import re

SECTION = re.compile(r"^===\s*(.+?)\s*===\s*$")
HOME = re.compile(r"DFHome136|HomePublisher136|native-FBS-library-instance-not-exposed|verified-library|reconcile=", re.I)
VERSION = re.compile(r"(?:0\.0\.136|0\.1\.136|nativehome1|QA136|0\.0\.135|0\.1\.135|homeabi1)",re.I)
DATE = re.compile(r"20(?:25|26)-\d\d-\d\d[ T]\d\d:\d\d:\d\d")
SENSITIVE = re.compile(r"(?i)(?:token|cookie|password|authorization|session|uuid|deviceid|deviceidentifier|ipaddress)\s*[:=]\s*[^\s,}\]]+")
UUID = re.compile(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F-]{27,}\b")
HEX = re.compile(r"\b[0-9a-fA-F]{36,}\b")
def safe(s):
    s = SENSITIVE.sub("[redacted]",s)
    s = UUID.sub("[uuid]",s)
    s = HEX.sub("[hex]",s)
    s = re.sub(r"\b(?:com|org|net)\.[A-Za-z0-9_.-]{4,}\b","[app-id]",s)
    return s.strip()[:260]

def inspect(log,source,orig):
    raw=log.read_bytes()
    counts=collections.Counter()
    sections=[]
    events=[]
    dates=[]
    first=[]
    section="unsectioned"
    for n,line in enumerate(raw.decode("utf-8","replace").splitlines(),1):
        if n<=5:first.append(safe(line))
        h=SECTION.match(line)
        if h:
            section=h.group(1)
            sections.append(section[:160])
        dt=DATE.search(line)
        if dt and len(dates)<80:dates.append({"line":n,"date":dt.group(0)})
        elif dt and n%1000==0:dates.append({"line":n,"date":dt.group(0)})
        if VERSION.search(line):
            counts["version_mentions"]+=1
            if "136" in line:counts["qa136_mentions"]+=1
            if "135" in line:counts["qa135_mentions"]+=1
        if HOME.search(line):
            counts["home136_related_lines"]+=1
            if "DFHome136" in line:counts["dfhome136_lines"]+=1
            if "started no-hook" in line:counts["home136_started"]+=1
            if "switch OFF" in line:counts["home136_off"]+=1
            if "native-FBS-library-instance-not-exposed" in line:counts["library_not_exposed"]+=1
            if "verified-library=" in line:counts["verified_library_observed"]+=1
            if re.search(r"reconcile=[1-9][0-9]*",line):counts["reconciled_positive"]+=1
            if "reconcile=0" in line:counts["reconciled_zero"]+=1
            if "reconcile=-1" in line:counts["reconciled_unavailable"]+=1
            if len(events)<80:events.append({"line":n,"section":section[:80],"text":safe(line)})
    c=source.read_text()
    reference=json.loads(orig.read_text())
    original={}
    for key in ("DuoNavi104","Native12Reference"):
        x=reference[key]["methods"]
        selectors={n for z in x.values() for v in z.get("resolved",[]) if (n:=v.get("name"))}
        original[key]={
            "exact_shapinned_binary_reference":reference[key].get("SHA256"),
            "registers_DashBoard_or_CARApplication":("DashBoard" in selectors and "_newApplicationLibrary" in selectors),
            "has_FBS_add_proxy":("addApplicationProxy:withOverrideURL:" in selectors),
            "has_Home_icon_model_callback":("_setupIconModel" in selectors),
            "has_Home_icon_launch_callback":any(x.startswith("iconManager:launchIcon") for x in selectors),
            "has_CarPlay_declaration":("CRCarPlayAppDeclaration" in selectors),
            "has_policy_evaluation":("effectivePolicyForAppDeclaration:" in selectors)}
    source_gaps={
      "only_CarPlay_process":'isEqualToString:@"CarPlay"' in c and 'isEqualToString:@"DashBoard"' not in c,
      "searches_only_UiKit_controller_tree":"UIApplication.sharedApplication" in c and "window.rootViewController" in c,
      "does_not_hook_original_home_owner":"MSHook" not in c and "_setupIconModel" not in c and "_newApplicationLibrary" not in c,
      "cannot_prove_real_Home_icons_from_source":True}
    return {
        "input":"REAL_UPLOADED_DUOFACE_AUDIT16_NOT_A_DEVICE_RUN_BY_CI",
        "commit":"31166d15e3606e571bc34b023e59f76613d4953c",
        "log_sha256":hashlib.sha256(raw).hexdigest(),
        "bytes":len(raw),
        "line_count":len(raw.splitlines()),
        "first_lines":first,
        "time_samples":dates[:12]+dates[-12:],
        "section_names":[s for s in sections if re.search("home|carplay|duoface|diagnostic",s,re.I)][:60],
        "has_HomePublisher136_export_section":any("DuoFaceHomePublisher136.log" in s for s in sections),
        "counts":dict(counts),
        "home136_event_samples":events,
        "original_semantic_home_calls":original,
        "qa136_source_gaps":source_gaps,
        "crash_ips_context":"Three uploaded IPS files share October 30 timestamps; never assign them to QA136 without matching physical incident and version.",
        "interpretation_limits":"No [DFHome136] lines does not distinguish disabled switch, not installed/running, absent exporter, or process mismatch. Original callsite xrefs do not establish that the same class exists in this iOS16 process."}
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--log",type=pathlib.Path,required=True)
    p.add_argument("--entry",type=pathlib.Path,required=True)
    p.add_argument("--original",type=pathlib.Path,required=True)
    p.add_argument("--out",type=pathlib.Path,required=True)
    a=p.parse_args()
    r=inspect(a.log,a.entry,a.original)
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(r,indent=2,ensure_ascii=False)+"\n")
    print("QA136_LOG16_AUDIT",r["bytes"],r["line_count"],r["counts"])
    print("QA136_HOME_SECTIONS",r["has_HomePublisher136_export_section"])
    print("QA136_SOURCE_VS_ORIGINAL",r["qa136_source_gaps"])
if __name__=="__main__":main()
