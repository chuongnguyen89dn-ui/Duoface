#!/usr/bin/env python3
"""Audit all source blobs reachable from this repository's Git history.

Strictly read-only. This script never patches app binaries or edits project files
other than the requested JSON report. It distinguishes full implementations from
mere hook references to avoid inventing a rebuildable core.
"""
import argparse
import json
import pathlib
import re
import subprocess
from datetime import datetime, timezone

SOURCES=(".m",".mm",".xm",".x",".swift",".h",".hpp",".c",".cc",".cpp",".inc")
CORE=("CBLicenseSyncManager","CBBridgeManagerDashboard","CBBridgeManager","DuoFaceUI")
IMPL=re.compile(r"@implementation\s+([A-Za-z_]\w*)")
TARGETS={"CBLicenseSyncManager","CBBridgeManagerDashboard","CBBridgeManager"}
def git(*args):
    return subprocess.check_output(("git",)+args,stderr=subprocess.PIPE)
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",type=pathlib.Path,required=True)
    args=parser.parse_args()
    rows=git("rev-list","--objects","--all").decode("utf-8","replace").splitlines()
    by_sha={}
    for row in rows:
        parts=row.split(" ",1)
        if len(parts)!=2: continue
        sha,path=parts
        if path.lower().endswith(SOURCES):
            by_sha.setdefault(sha,path)
    found=[]
    tested=0
    p=subprocess.Popen(["git","cat-file","--batch"],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    try:
        for sha,path in sorted(by_sha.items(),key=lambda v:(v[1].casefold(),v[0])):
            p.stdin.write((sha+"\n").encode("ascii"))
            p.stdin.flush()
            head=p.stdout.readline().split()
            if len(head)<3:
                raise RuntimeError("Invalid git cat-file response for "+sha)
            size=int(head[2])
            data=p.stdout.read(size)
            assert len(data)==size
            assert p.stdout.read(1)==b"\n"
            if head[1]!=b"blob" or size>2_000_000:continue
            tested+=1
            content=data.decode("utf-8","replace")
            mentions=[name for name in CORE if name in content]
            implementations=sorted(set(IMPL.findall(content)))
            full=sorted(TARGETS.intersection(implementations))
            if not mentions and not full:continue
            found.append({"git_blob_sha":sha,"historical_path":path,
                         "mentions":mentions,
                         "implementation_symbols":full,
                         "any_other_implementations":len(implementations),
                         "source_bytes":size})
    finally:
        p.stdin.close()
        p.wait(timeout=15)
    matches={x:[] for x in sorted(TARGETS)}
    for item in found:
        for cls in item["implementation_symbols"]:
            matches[cls].append({"path":item["historical_path"],"blob":item["git_blob_sha"]})
    result={
        "status":"DUOFACE_ALL_REACHABLE_HISTORY_CORE_SOURCE_CENSUS",
        "utc_checked":datetime.now(timezone.utc).isoformat(),
        "branches_at_checkout":git("branch","-r").decode("utf-8","replace").splitlines(),
        "git_objects_reachable_entries":len(rows),
        "historical_source_blobs_with_source_extensions":len(by_sha),
        "source_blobs_inspected":tested,
        "blobs_with_core_mentions":len(found),
        "core_class_source_implementations":matches,
        "candidate_paths":found,
        "proof_scope":"Git blobs reachable from refs fetched in this job; not inaccessible remote repos/unreachable objects",
        "two_visualtest_host_rebuild_sources_proven_available":all(matches.values()),
        "read_only":True,"binary_modified":False,"hub_modified":False,
        "deb_built":False,"sileo_deployed":False
    }
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print("VISUALTEST12_HISTORICAL_SOURCE_SCAN_PASS")
    print("reachable_objects",len(rows),"source_blobs",len(by_sha),"inspected",tested)
    for cls,entries in matches.items():
        print(cls,"implementation_sources",len(entries),entries[:8])
if __name__=="__main__":main()
