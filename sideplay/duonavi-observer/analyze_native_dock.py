#!/usr/bin/env python3
"""Summarize metadata evidence; never turn missing capture into ABI success."""
import argparse,json,pathlib
REQUIRED={"_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:",
          "setActiveBundleIdentifier:animated:","_refreshAppDock","setDisplayState:"}
def analyze(text):
    records=[]
    for line in text.splitlines():
        if not line.lstrip().startswith('{'):continue
        try:r=json.loads(line)
        except json.JSONDecodeError:continue
        if isinstance(r,dict):records.append(r)
    owners={}
    for r in records:
        if r.get('event')!='native_dock_class_abi':continue
        for m in r.get('declared_methods',[]):
            name=m.get('selector')
            if name not in REQUIRED:continue
            item={k:r.get(k) for k in ('process','pid','class','image')}
            item.update({k:m.get(k) for k in ('encoding','argument_count')})
            if item not in owners.setdefault(name,[]):owners[name].append(item)
    missing=sorted(REQUIRED-owners.keys())
    nodes=[r for r in records if r.get('event')=='native_dock_scene_node']
    return {'schema':1,'metadata_observed':bool(owners),'missing_selectors':missing,
        'declaring_owners':owners,'public_scene_nodes':nodes,
        'status':'METADATA_CAPTURE_AVAILABLE' if owners else 'NO_NATIVE_DOCK_METADATA_CAPTURE',
        'runtime_receiver_identity_verified':False,'activation_safe_to_implement':False,
        'private_call_arguments_measured':False,'device_fix_verified':False,
        'limitation':'Declaring class and public containment do not prove a live private ivar receiver, arguments, execution, ACK or touch latency.'}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--log',type=pathlib.Path,required=True)
    ap.add_argument('--output',type=pathlib.Path,required=True);a=ap.parse_args()
    report=analyze(a.log.read_text(errors='replace'))
    a.output.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
    print(report['status'], 'missing='+str(len(report['missing_selectors'])))
if __name__=='__main__':main()
