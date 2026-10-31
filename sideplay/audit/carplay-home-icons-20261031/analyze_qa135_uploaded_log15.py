#!/usr/bin/env python3
"""Read-only analyze user-uploaded DuoFaceAudit 15 and three SpringBoard IPS.

Input is pinned to the user-uploaded main-branch commit, not a CI build log.
Summaries avoid copying raw app identifiers, sessions or diagnostic payloads.
"""
import argparse
import collections
import hashlib
import json
import pathlib
import re

HOME = re.compile(
    r"DuoFaceHomeABI|DuoFaceHomeCatalogABI|CARApplication|_newApplicationLibrary|"
    r"FBSApplicationLibrary|DBApplicationInfo|CRCarPlayAppPolicyEvaluator|"
    r"LSBundleInfoCachedValues|LSBundleProxy|entitlementValuesForKeys|"
    r"FBSApplicationInfo", re.I)
SCOPED = re.compile(
    r"gofa|home|enabled-apps|app(s)?-changed|app.?select|catalog|"
    r"selected|dashboard|CarPlay|SpringBoard|installed|allowlist|"
    r"DFNativeHost|appBridge|BKS|lock|scene", re.I)
ERROR = re.compile(r"error|fatal|exception|crash|fail|reject|denied|missing|unavailable|absent|not.found", re.I)
VERSION = re.compile(r"QA135|0[.]0[.]135|homeabi1|QA134|0[.]0[.]134", re.I)
DATE = re.compile(r"20(?:25|26)-\d\d-\d\d(?:[T ]\d\d:\d\d:\d\d(?:[.]\d+)?)?")
SEC = re.compile(r"^=== (.*?) ===\s*$")
PRIVATE = re.compile(r"(?:Session|UUID|Token|Cookie|Password|Auth(?:orization)?|DeviceID|DeviceIdentifier|IPAddress)\s*[:=]",re.I)

def bounded_line(line, limit=280):
    # Technical snippet without opaque session identifiers/tokens or raw full user logs.
    text = line.strip()
    text = re.sub(r"(?i)(session|uuid|token|cookie|password|authorization)\s*[:=]\s*[^\s,}]+",r"\1=REDACTED",text)
    text = re.sub(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F-]{27,}\b","[UUID]",text)
    text = re.sub(r"\b[0-9a-fA-F]{40,}\b","[HEX]",text)
    return text[:limit]

def digest(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda:f.read(1024*1024),b""):h.update(chunk)
    return h.hexdigest()

def audit_log(path):
    groups=collections.Counter()
    section_groups=collections.Counter()
    lines=0; dates=[]; abi=[]; errors=[]; home=[]; version=[]; heads=[]; tails=[]
    current_section="unsectioned"
    hitsets=collections.defaultdict(list)
    with path.open("r",encoding="utf-8",errors="replace") as f:
        for n,text in enumerate(f,1):
            lines=n
            text=text.rstrip("\n")
            if n<=30:heads.append({"line":n,"text":bounded_line(text)})
            tails=(tails+[{"line":n,"text":bounded_line(text)}])[-20:]
            m=SEC.match(text.strip())
            if m:current_section=m.group(1)[:120]
            if DATE.search(text):dates.append((n,DATE.search(text).group(0)))
            for tag,rx in (("home_abi",HOME),("home_scope",SCOPED),("error",ERROR),("version",VERSION)):
                if rx.search(text):
                    groups[tag]+=1;section_groups[(current_section,tag)]+=1
                    if tag=="home_abi" and len(abi)<120:abi.append({"line":n,"section":current_section,"text":bounded_line(text,450)})
                    if tag=="home_scope" and len(home)<95:home.append({"line":n,"section":current_section,"text":bounded_line(text)})
                    if tag=="error" and len(errors)<140:errors.append({"line":n,"section":current_section,"text":bounded_line(text)})
                    if tag=="version" and len(version)<55:version.append({"line":n,"section":current_section,"text":bounded_line(text)})
    return {"bytes":path.stat().st_size,"sha256":digest(path),"line_count":lines,
            "groups":dict(groups),"sections":[{"section":a,"kind":b,"hits":n}
                for (a,b),n in section_groups.most_common(70)],
            "date_first":dates[:15],"date_last":dates[-15:],
            "abi_lines":abi,"scope_lines":home,"error_lines":errors,"version_lines":version,
            "first_lines":heads,"last_lines":tails}

def read_ips(path):
    raw=path.read_text(encoding="utf-8",errors="replace")
    hdr,_,rest=raw.partition("\n")
    try: obj=json.loads(rest)
    except json.JSONDecodeError:
        obj=None
    try: header=json.loads(hdr)
    except json.JSONDecodeError: header={}
    if not isinstance(obj,dict):
        return {"file":path.name,"parse":"invalid","sha256":digest(path)}
    frames=obj.get("lastExceptionBacktrace") or []
    threads=obj.get("threads") or []
    trig=next((t for t in threads if t.get("triggered")),{})
    top=trig.get("frames") or []
    interesting=lambda xs:[{
        "symbol":f.get("symbol",""),
        "symbolLocation":f.get("symbolLocation",None),
        "imageIndex":f.get("imageIndex",None)}
        for f in xs if re.search(r"SBAppViewController|SBSceneHandle|DFManagedSceneObserver|DFUpdateScene|Immortalizer|FBScene|CARApplication|DuoFace",f.get("symbol",""),re.I)][:18]
    return {"file":path.name,"sha256":digest(path),"timestamp":header.get("timestamp"),
            "capture_time":obj.get("captureTime"),"process":obj.get("procName"),
            "os":obj.get("osVersion",{}).get("train"),
            "signal":obj.get("exception",{}).get("signal"),
            "exception":obj.get("exception",{}).get("type"),
            "consecutive_crashes":obj.get("consecutiveCrashCount"),
            "top_triggered_frames":[{"symbol":f.get("symbol"),"offset":f.get("imageOffset")}
                                    for f in top[:8]],
            "important_exception_frames":interesting(frames),
            "important_triggered_frames":interesting(top),
            "is_pre_qa135_build":(obj.get("captureTime") or "").startswith("2026-10-30 1")}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--log",type=pathlib.Path,required=True)
    p.add_argument("--ips",nargs=3,type=pathlib.Path,required=True)
    p.add_argument("--out",type=pathlib.Path,required=True)
    a=p.parse_args()
    report={"input_commit":"12ef117f469ed6cd1dd11c0096621953329793ee",
        "report_kind":"READ_ONLY_USER_UPLOADED_LOG15_NOT_CI_DEVICE_QA",
        "user_report":"GOFA fixed on device; third-party selected apps not visible on actual CarPlay Home",
        "log":audit_log(a.log),
        "crashes":[read_ips(file) for file in a.ips],
        "warning":"An uploaded historical SpringBoard IPS is not proof QA135 caused the crash; respect original incident timestamp."}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print("LOG15_ANALYSIS_SUCCESS",report["log"]["bytes"],report["log"]["line_count"])
    print("LOG15_SECTION_MATCHES",report["log"]["groups"])
    print("LOG15_DATE_LAST",report["log"]["date_last"])
    print("LOG15_ABI_EXCERPTS",json.dumps(report["log"]["abi_lines"][:15],ensure_ascii=False))
    print("LOG15_CRASH_SUMMARY",json.dumps(report["crashes"],ensure_ascii=False)[:5500])
if __name__=="__main__":main()
