#!/usr/bin/env python3
"""Read-only SHA-pinned DuoNavi-original vs DuoDash-repack native Home crosswalk."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

PINS = {
    'DuoNavi104': '44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15',
    'DuoDash113Repack': 'b41dd7f892bfd3722e95a40f764a989886078b4a30943c1f0b50d47b6e248a47',
}
MARKERS = (
    'CARApplication', '_newApplicationLibrary', 'bridgedApps',
    'addApplicationProxy:withOverrideURL:', 'DBApplicationInfo',
    'CRCarPlayAppDeclaration', 'effectivePolicyForAppDeclaration:',
    '_CARDashboardHomeViewController', 'iconManager:launchIcon:',
    'iconManager:launchIconForIconView:', 'shouldInterceptLaunchForApp:',
    'startBridging:', 'stopBridging', 'DBApplicationController',
    'DBMutableWorkspaceStateChangeRequest', 'DBWorkspace',
    'onHostRequest:', 'onHostRequestSplit:',
    'cnabBuildSceneHostForBid:displaySize:',
    'setBridgeState:width:height:orientation:', 'appbridge_enabled',
)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--duonavi', required=True, type=Path)
    ap.add_argument('--duodash-repack', required=True, type=Path)
    ap.add_argument('--scanner', required=True, type=Path)
    ap.add_argument('--out', required=True, type=Path)
    args=ap.parse_args()
    spec=importlib.util.spec_from_file_location('prior_verified_scanner', args.scanner)
    if not spec or not spec.loader: raise RuntimeError('missing existing verified scanner')
    scanner=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(scanner)
    scanner.PINS=PINS
    scanner.MARKERS=MARKERS
    output={
        'scope':'original DuoNavi 1.0.4 vs DuoDash 1.1.3 Fullscreen427 REPACK static xrefs',
        'execution_or_device_proof':False,
        'home_tap_to_launch_proven':False,
        'input_debs_extracted_by_workflow':True,
        'images':{},
    }
    for label,path in [('DuoNavi104',args.duonavi),('DuoDash113Repack',args.duodash_repack)]:
        actual=hashlib.sha256(path.read_bytes()).hexdigest()
        if actual!=PINS[label]: raise AssertionError(f'{label}: wrong dylib SHA {actual}')
        s=scanner.analyze(label,path)
        top=[]
        for method in s['function_refs']:
            refs=list(dict.fromkeys(r['marker'] for r in method['refs']))
            if any('launchIcon' in x or 'startBridging' in x or 'onHostRequest' in x or 'SceneHost' in x for x in refs):
                top.append({'vm':method['vm'],'markers':refs})
        output['images'][label]={
            'dylib_sha256':actual,
            'matched_functions':s['matchedFunctions'],
            'tracked_literals':s['tracked_literals'],
            'candidate_functions':top[:60],
            'candidate_function_count':len(top),
            'caveat':'co-located original xrefs do not prove invocation or selector type encoding',
        }
        print('QA142_XREF',label,'matched_functions',s['matchedFunctions'],
              'candidate_functions',len(top),'sha256',actual)
    assert all(x['matched_functions']>0 for x in output['images'].values()), 'No xrefs; investigate before claiming success'
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(output,indent=2,ensure_ascii=False)+'\n')
    print('QA142_TWO_BINARIES_STATIC_XREF_COMPLETE_NOT_DEVICE_LAUNCH_PROOF')

if __name__=='__main__':main()
