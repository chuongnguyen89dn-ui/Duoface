#!/usr/bin/env python3
"""Privacy-scoped reproducible audit of QA137 user Log17 and 3 original crash IPS.

Do not interpret source-log registration as a visible/tappable Home icon or infer
that an Apple system process crash was caused by DuoFace without a shared stack.
"""
import argparse
import collections
import hashlib
import json
import pathlib
import re

SECT=re.compile(r'^===\s*(.*?)\s*===')
PAIRS=('DuoFaceSceneHost.log','DuoFaceNativeSceneJoin.log','DuoFaceDockOwner.log',
       'DuoFaceHomePublisher136.log','DuoFaceHomeAdmission137.log','DuoFaceTouchOwner.log')
def sha(raw):return hashlib.sha256(raw).hexdigest()

def audit_text(path):
    raw=path.read_bytes()
    sections={};current="intro";sections[current]=[]
    for line in raw.decode("utf-8","replace").splitlines():
        m=SECT.match(line)
        if m:
            current=m.group(1).split(' (last ')[0]
            sections.setdefault(current,[])
        else:sections.setdefault(current,[]).append(line)
    home=sections.get('DuoFaceHomeAdmission137.log',[])
    counts=collections.Counter()
    perproc=collections.Counter()
    abi={}
    classes=collections.Counter()
    for line in home:
        m=re.search(r'\bprocess=(\S+)',line)
        proc=m.group(1) if m else "unknown"
        perproc[proc]+=1
        if 'fbs-info sample=' in line:
            counts["fbs_info_observations"]+=1
            if 'concrete-class=DBApplicationInfo isDBApplicationInfo=1' in line:
                counts["fbs_db_info_observations"]+=1
            m2=re.search(r'concrete-class=([A-Za-z0-9_]+)',line)
            if m2:classes[m2.group(1)]+=1
        if "fbs-info-abi" in line and "method-absent" in line:
            counts["fbs_missing_getter_observations"]+=1
        m2=re.search(r'abi (?:[+-]\[.+? (.+?)\]) (.*)$',line)
        if m2:abi.setdefault(proc,{})[m2.group(1)]=m2.group(2)
    gofa=[line for line in sections.get('DuoFaceSceneHost.log',[])
          if 'bundle=com.lumi.GOFA' in line]
    f=[line for line in gofa if 'event=scene-frame-readback ' in line]
    gofa_result={
        "scene_event_lines":len(gofa),
        "remote_precommit_frame_reads":len(f),
        "remote_precommit_mismatch":sum("same=0" in x for x in f),
        "remote_precommit_match":sum("same=1" in x for x in f),
        "portrait_375x812_precommit":sum("actual={{0, 0}, {375, 812}}" in x for x in f),
        "logical_target_example_793x685":sum("target={{0, 0}, {793, 685}}" in x for x in f),
        "native12_three_arg_child_setter_dispatches":sum("event=original-native12-scene-size-dispatch" in x and "child3=1" in x for x in gofa),
        "remote_size_update_requests":sum("event=native12-scene-settings-live-contract-requested" in x for x in gofa),
        "foreground_observations":sum("event=scene-foreground-observed-only" in x for x in gofa),
        "after_write_size_ack_present":False,
    }
    start=sections.get("DuoFaceNativeSceneJoin.log",[])
    startup={"app_launched":sum("application-launched," in x for x in start),
             "template_role_issued":sum("CarPlay-template-role-issued-by-system" in x for x in start),
             "phone_scene_connected":sum("phone-scene-connected" in x for x in start),
             "background_boundary":sum("qa125-background-boundary" in x for x in start),
             "native_car_scene_active":sum("native-carplay-scene-active" in x for x in start)}
    publisher=sections.get("DuoFaceHomePublisher136.log",[])
    pub={"positive_six":sum("reconcile=6" in x for x in publisher),
         "subsequent_zero":sum("reconcile=0" in x for x in publisher),
         "fbs_library_found":sum("verified-library=FBSApplicationLibrary" in x for x in publisher),
         "not_exposed":sum("native-FBS-library-instance-not-exposed" in x for x in publisher)}
    return {"input":"user QA137 manual export Log17 (not CI physical device)",
        "sha256":sha(raw),"bytes":len(raw),"line_count":len(raw.splitlines()),
        "export_header":raw.decode("utf-8","replace").splitlines()[:4],
        "home_137":{"by_process":dict(perproc),"info_classes":dict(classes),
                    "counts":dict(counts),"method_abi_by_process":abi},
        "home_136":pub,"gofa":gofa_result,"duoface_startup":startup,
        "limits":["pre-update scene-frame-readback is NOT an after-write ACK or proof rendered map",
                  "CarPlayTemplateUIHost crash ≠ proven DuoFace NativeHost crash",
                  "Home FBS record ≠ user-visible Apple Home icon or launch",
                  "Raw export includes older accumulated traces; no session/time in every line"]}

def audit_crash(path):
    raw=path.read_bytes()
    txt=raw.decode("utf-8","replace").splitlines()
    if not txt or not txt[0].startswith('{'):raise RuntimeError("IPS header missing")
    j=json.loads("\n".join(txt[1:]))
    return {"filename":path.name,"sha256":sha(raw),"procName":j.get("procName"),
            "captureTime":j.get("captureTime"),
            "procLaunch":j.get("procLaunch"),
            "exception":(j.get("exception") or {}).get("signal"),
            "exceptionType":(j.get("exception") or {}).get("type"),
            "backtrace_top_symbols":[x.get("symbol","") for x in
                          (j.get("lastExceptionBacktrace") or [])[:9]],
            "DuoFaceNativeHost_crash_proven":j.get("procName")=="DuoFaceNativeHost"}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--log",type=pathlib.Path,required=True)
    p.add_argument("--crash",type=pathlib.Path,nargs=3,required=True)
    p.add_argument("--out",type=pathlib.Path,required=True)
    z=p.parse_args()
    result={"replay":"pinned GitHub main upload commit 488a2b5f416ca7ff91bc7c0c7d04379e5ad8344b",
            "log":audit_text(z.log),
            "crashes":[audit_crash(x) for x in z.crash]}
    if result["log"]["bytes"]<5_000_000:raise ValueError("Unexpected truncated user Log17")
    if result["log"]["gofa"]["remote_precommit_frame_reads"]<10:raise ValueError("GOFA scene export missing")
    if len(result["crashes"])!=3:raise ValueError("Expected three Apple host IPS")
    z.out.parent.mkdir(parents=True,exist_ok=True)
    z.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print("REAL_QA137_LOG17_PARSED",result["log"]["bytes"],result["log"]["line_count"],
          result["log"]["gofa"],result["log"]["home_136"])
    print("APPLE_HOST_CRASHES",[(x["captureTime"],x["procName"],x["exception"],
           x["backtrace_top_symbols"][6:7]) for x in result["crashes"]])
if __name__=="__main__":main()
