#!/usr/bin/env python3
"""Analyze exact user-uploaded QA142 Log21 and 3 CarPlay crash IPS. READ ONLY.
No system launch/crash is attributed to current QA142 without temporal and UUID evidence.
"""
import argparse
import collections
import hashlib
import json
import pathlib
import re

HEAD = "b495e90a8d25f9c65802cf7ef040fe4f4c0aba54"
BLOB = "595cff0e687825008bc443e2a1d2bcc63560b3f5"
SECT = re.compile(r"^===\s*(.*?)\s*===")
TOKENS = ("DFHome142", "home-tap", "launchIcon", "requestStateChange:", "workspace", "carPlayDeclaration", "declaration-attached", "selected-original-policy", "newRecords=", "home140", "native-host", "scene-", "selected")
def checksum(x):return hashlib.sha256(x).hexdigest()

def get_sections(s):
    sections=collections.defaultdict(list)
    name="header"
    for line in s.splitlines():
        m=SECT.match(line)
        if m:
            name=m.group(1).split(" (last ")[0]
            sections[name]
        else:sections[name].append(line)
    return dict(sections)

def redact(line):
    # Keep only known DuoFace technical ABI/output; avoid UUID/session/device addresses.
    line=re.sub(r"(?i)(session|RequestID|UUID)=\S+",r"\1=[redacted]",line)
    line=re.sub(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F-]{27,}\b","[uuid]",line)
    return line[:650]

def crash(path):
    raw=path.read_bytes()
    ls=raw.decode("utf-8","replace").splitlines()
    header=json.loads(ls[0]);data=json.loads("\n".join(ls[1:]))
    triggered=next((t for t in data.get("threads",[]) if t.get("triggered")),{})
    frames=triggered.get("frames",[])
    counts=collections.Counter()
    for f in frames:
        name=f.get("symbol") or "(unsymbolicated)"
        if name.startswith(("DF138","DF141","DFHome","DFCarPlay")):counts[name]+=1
    mods={}
    for f in frames[:60]:
        i=f.get("imageIndex")
        if isinstance(i,int) and i<len(data.get("usedImages",[])):
            im=data["usedImages"][i]
            if im.get("name","").startswith(("DFCarPlay","DFFirstParty")):
                mods[im.get("name")]=im.get("uuid")
    return {"filename":path.name,"sha256":checksum(raw),
            "header":{k:header.get(k) for k in ("app_name","timestamp")},
            "process":data.get("procName"),"capture_time":data.get("captureTime"),
            "signal":data.get("exception",{}).get("signal"),
            "type":data.get("exception",{}).get("type"),
            "fault_thread_queue":triggered.get("queue"),"frame_count":len(frames),
            "source_owned_frame_counts":dict(counts),"injected_image_uuids":mods,
            "top_symbols":[f.get("symbol",f"image{f.get('imageIndex')}+{f.get('imageOffset')}") for f in frames[:29]]}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--log",required=True,type=pathlib.Path)
    ap.add_argument("--crash",required=True,type=pathlib.Path,nargs=3)
    ap.add_argument("--out",required=True,type=pathlib.Path)
    a=ap.parse_args()
    raw=a.log.read_bytes()
    if len(raw)<3_000_000:raise RuntimeError("Log21 truncated or wrong source")
    s=raw.decode("utf-8","replace")
    sections=get_sections(s)
    home=sections.get("DuoFaceHomeLaunch142.log",[])
    home141=sections.get("DuoFaceHomeAdmission141.log",[])
    if not home:raise RuntimeError("QA142 HomeLaunch142 section ABSENT: preserve failure diagnostics")
    abi=[redact(x) for x in home if "[DFHome142]" in x and
         any(t in x for t in ("method=","candidate=","candidate-count=","read-only","class-state"))]
    sample=[redact(x) for x in home[-90:]]
    policy=[redact(x) for x in home141 if any(z in x for z in
            ("declaration-attached","selected-original-policy","original-DashBoard-factory","ABI-checked","exception"))]
    others={}
    for name,lines in sections.items():
        if "DuoFace" not in name:continue
        occurrences=collections.Counter(k for x in lines for k in
            ("home-tap","launchIcon","app-host-refused","scene-failed","newRecords=",
             "native-owner-state","gofa","reconcile=","scene-replace-committed")
            if k.lower() in x.lower())
        others[name]={"lines":len(lines),"events":dict(occurrences)}
    crashes=[crash(p) for p in a.crash]
    result={"source_commit":HEAD,"source_git_blob":BLOB,"log_sha256":checksum(raw),
       "log_size":len(raw),"line_count":len(s.splitlines()),"header":s.splitlines()[:5],
       "sections":{k:len(v) for k,v in sections.items()},
       "home142":{"lines":len(home),"abi_matches":abi[-140:],"recent":sample},
       "home141":{"lines":len(home141),"policy":policy[-30:]},
       "observations":others,"crashes":crashes,
       "scope":"read-only; uploaded IPS are separate events; do not assume they occurred during QA142",
       "device_click_confirmed_by_user":False}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
    print("QA142_LOG21_INPUT",len(raw),"bytes",len(s.splitlines()),"lines",checksum(raw))
    print("QA142_HOME_LAUNCH_ABI",len(home),"lines")
    for x in abi[-60:]:print("QA142_ABI",x)
    print("QA142_HOME_ADMISSION",len(home141),"lines")
    for x in policy[-10:]:print("QA142_POLICY",x)
    for x in crashes:print("QA142_CRASH",x["capture_time"],x["process"],x["signal"],x["source_owned_frame_counts"],x["injected_image_uuids"])
    print("QA142_LOG21_PARSED_AND_ARCHIVED")
if __name__=="__main__":main()
