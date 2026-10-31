#!/usr/bin/env python3
"""Replay the actual QA138 CarPlay crash evidence; no device simulation."""
import argparse
import collections
import datetime
import hashlib
import json
import re
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--log', type=Path, required=True)
p.add_argument('--ips', type=Path, nargs=3, required=True)
p.add_argument('--out', type=Path, required=True)
a = p.parse_args()
raw = a.log.read_bytes()
log = raw.decode('utf-8', errors='replace')
section = re.search(r'^=== DuoFaceHomeAdmission138\.log.*?\n(.*?)(?=\n===|\Z)',
                    log, re.MULTILINE | re.DOTALL).group(1)
starts = [(float(t), int(pid)) for t, pid in
          re.findall(r'time=([\d.]+) pid=(\d+) ABI-checked hooks', section)]
reports = []
for path in a.ips:
    content = path.read_bytes()
    data = json.loads(content.decode().split('\n', 1)[1])
    assert data['procName'] == 'CarPlay'
    images = data['usedImages']
    dock_uuid = next(im['uuid'] for im in images
                     if im.get('name') == 'DFCarPlayDockOwner.dylib')
    # Exact UUID from the published QA138 archive QA138_MACHO_UUIDS.txt.
    assert dock_uuid.lower() == '26f13ecd-22fa-3fe0-8350-fc80dc45c526'
    assert data['pid'] in {pid for _, pid in starts}
    frames = data['threads'][data['faultingThread']]['frames']
    decoded = [{
        'image': images[f['imageIndex']]['name'],
        'symbol': f.get('symbol'),
        'symbolLocation': f.get('symbolLocation'),
        'imageOffset': f.get('imageOffset'),
    } for f in frames]
    symbols = collections.Counter(f['symbol'] for f in decoded if f['symbol'])
    image_counts = collections.Counter(f['image'] for f in decoded)
    pattern = sum(
        decoded[i]['symbol'] == 'DF138Answer' and
        decoded[i + 1]['symbol'] == 'DF138Entitlement3' and
        decoded[i + 2]['image'] == 'DFFirstPartyAdmission.dylib'
        for i in range(len(decoded) - 2))
    assert pattern > 100
    assert data['exception']['signal'] == 'SIGSEGV'
    assert 'STACK GUARD' in data.get('vmRegionInfo', '')
    reports.append({
        'file': path.name, 'sha256': hashlib.sha256(content).hexdigest(),
        'dock_uuid': dock_uuid, 'matches_public_qa138_uuid': True,
        'pid': data['pid'], 'captureTime': data['captureTime'],
        'exception': data['exception'], 'frame_count': len(frames),
        'recursive_three_frame_pattern_count': pattern,
        'symbol_counts': dict(symbols), 'image_counts': dict(image_counts),
        'fault_address_region': 'STACK GUARD',
        'representative_frames': decoded[15:27],
    })

result = {
    'source_upload_commit': 'dc147684b2a30dcef92f1e4d8f614dfa878d4c38',
    'log_file': 'sideplay/log/DuoFaceAudit 18.txt',
    'log_blob': 'f51c461bd344840bca6b033ba5946202babfdccc',
    'log_sha256': hashlib.sha256(raw).hexdigest(),
    'log_bytes': len(raw), 'log_lines': len(log.splitlines()),
    'home138_start_records': len(starts),
    'home138_unique_carplay_pids': len({pid for _, pid in starts}),
    'first_start_utc': datetime.datetime.fromtimestamp(starts[0][0], datetime.timezone.utc).isoformat(),
    'last_start_utc': datetime.datetime.fromtimestamp(starts[-1][0], datetime.timezone.utc).isoformat(),
    'home138_markers': {k: section.count(k) for k in
                        ('selected-LS-inclusion', 'selected-original-policy',
                         'selected-declaration-created', 'original-DashBoard-factory')},
    'crashes': reports,
    'verdict': 'QA138 LS admission hook recursively reenters DF138Answer/DF138Entitlement3 through existing admission forwarding; main-thread stack overflow kills CarPlay.',
    'source_explanation': 'DF138Answer calls its saved two-argument getter again to inspect native capabilities; the actual forwarding chain reaches the hooked three-argument getter and reenters DF138Answer. Original-pointer invocation does not guarantee absence of cross-selector reentry.',
    'limits': 'Does not prove a GOFA view-layout cause or physical QA139 UI recovery. Historical pre138 FatalException and TemplateUIHost reports are not this SIGSEGV.',
}
a.out.parent.mkdir(parents=True, exist_ok=True)
a.out.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({k: result[k] for k in
                  ('log_sha256', 'home138_start_records', 'home138_unique_carplay_pids', 'verdict')}))
print('ALL_THREE_REAL_CARPLAY_IPS_RECURSIVE_LS_STACK_GUARD_VERIFIED')
