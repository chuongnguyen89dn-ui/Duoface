#!/usr/bin/env python3
"""Read-only analysis of user-uploaded Log22 after QA145 physical Home test.

Input is sourced from immutable GitHub main commit; don't infer CarPlay pixels,
successful Back or actual source build from log markers alone.
"""
import argparse
import collections
import hashlib
import json
import pathlib
import re

EXPECTED_BLOB="4a80d75f6bb831b00be8b5d2075aa9d76d7f99d0"
EXPECTED_SIZE=6611528
SECTION=re.compile(r"^===\s*(.*?)\s*===")
STAGE=re.compile(r"\bstage=([^\s]+)")
TIME=re.compile(r"\btime=(\d+\.\d+)")
BUNDLE=re.compile(r"\bbid=([^\s]+)")
UUID=re.compile(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b")
KEYWORDS=("standalone", "home", "dock", "switch", "stop", "back", "scene", "launch", "touch", "window", "exit")
SELECTED=("DuoFaceStandalone144.log", "DuoFaceHomeLaunch143.log", "DuoFaceHomeLaunch142.log",
          "DuoFaceTouchOwner.log", "DuoFaceDockOwner.log", "DuoFaceSceneHost.log",
          "DuoFaceDeepTrace.log", "DuoFaceDeepTrace.log.previous")

def safe(line):
    line=UUID.sub("[uuid]", line)
    line=re.sub(r"\b(?:RequestID|request|session|uuid|req)=[^\s]+",
                lambda m: m.group(0).split("=")[0]+"=[redacted]",line, flags=re.I)
    return line.strip()[:420]

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--log",required=True,type=pathlib.Path)
    p.add_argument("--output",required=True,type=pathlib.Path)
    a=p.parse_args()
    raw=a.log.read_bytes()
    if len(raw)!=EXPECTED_SIZE: raise ValueError("User Log22 expected exactly %s bytes, got %s"%(EXPECTED_SIZE,len(raw)))
    blob=hashlib.sha1(("blob %d\0"%len(raw)).encode()+raw).hexdigest()
    if blob!=EXPECTED_BLOB:raise ValueError("Git blob mismatch "+blob)
    s=raw.decode("utf-8","replace")
    sec=collections.defaultdict(list)
    section="header"
    for line in s.splitlines():
        match=SECTION.match(line)
        if match:
            section=match.group(1).split(" (last ")[0].strip()
            continue
        sec[section].append(line)
    standalone=sec.get("DuoFaceStandalone144.log",[])
    all_stages=collections.Counter()
    processes=collections.Counter()
    events=[]
    for line in standalone:
        if "[DFStandalone144]" not in line:continue
        mt=TIME.search(line);ms=STAGE.search(line)
        stage=ms.group(1) if ms else "unparsed"
        all_stages[stage]+=1
        proc=re.search(r"\bprocess=([^\s]+)",line)
        processes[proc.group(1) if proc else "unknown"]+=1
        events.append({"epoch":float(mt.group(1)) if mt else None,"stage":stage,
                       "bundle":(BUNDLE.search(line).group(1) if BUNDLE.search(line) else None),
                       "line":safe(line)})
    sel={}
    for name in SELECTED:
        lines=sec.get(name,[])
        matching=[safe(x) for x in lines if any(w in x.lower() for w in KEYWORDS)]
        sel[name]={"line_count":len(lines),
                   "tail":list(map(safe,lines[-24:])),
                   "keyword_matching_tail":matching[-60:]}
    result={
      "source":"actual user Log22 GitHub main commit ce436ddb04e62d1762531a97ad74e21d3354a34d",
      "source_blob":blob,"byte_length":len(raw),"sha256":hashlib.sha256(raw).hexdigest(),
      "line_count":len(s.splitlines()),"header":list(map(safe,s.splitlines()[:12])),
      "sections":{k:len(v) for k,v in sec.items()},
      "standalone_stages":dict(all_stages),"standalone_processes":dict(processes),
      "standalone_events":events[-160:],"sections_selected":sel,
      "standalone_home_status":[safe(x) for x in s.splitlines() if x.startswith("Standalone Home:")][-3:],
      "not_proven":"absence of log markers not a device event; export may contain only last 256KiB per section; no automatic Sileo/device fix"
    }
    a.output.parent.mkdir(parents=True,exist_ok=True)
    a.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("LOG22_BYTES",len(raw),"LINES",len(s.splitlines()),"SHA256",result["sha256"])
    print("LOG22_STANDALONE_STAGE_COUNTS",json.dumps(dict(all_stages),sort_keys=True))
    print("LOG22_STANDALONE_PROCESS_COUNTS",json.dumps(dict(processes),sort_keys=True))
    for x in events[-60:]:print("LOG22_EVENT",x["line"])
    for name in SELECTED:
        print("LOG22_SECTION",name,sel[name]["line_count"])
        for x in sel[name]["keyword_matching_tail"][-10:]:print("LOG22_SECTION_MATCH",name,x)
    print("LOG22_HOME_STATUS",json.dumps(result["standalone_home_status"]))
    print("LOG22_READONLY_REPORT_WRITTEN")
if __name__=="__main__": main()
