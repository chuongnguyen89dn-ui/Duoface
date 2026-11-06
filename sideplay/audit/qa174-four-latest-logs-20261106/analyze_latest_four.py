#!/usr/bin/env python3
"""Read exactly four pinned user log blobs; never glob or consume old log files.
No device execution, app changes, package build, deployment or secrets access.
"""
from __future__ import annotations
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import urllib.parse
import urllib.request

REPO = 'chuongnguyen89dn-ui/Duoface'
UPLOAD = '3dc27f7d833709be04fc3406aa3bb7077b023f83'
FILES = {
    'Crash-0-SpringBoard.diskwrites_resource-2026-11-04-210058 3.ips': 'fd7f66c3969dc0eab91d7c6c934f6da7cc9705eb',
    'Crash-1-CarPlay.diskwrites_resource-2026-11-02-140101 3.ips': '45ac1ec2cf378ecf75675d98702d1ff6789c3a58',
    'Crash-2-SpringBoard.diskwrites_resource-2026-11-02-104439 3.ips': '904a9aa2bbd8e69761c3fff3eb8b46065c7710c2',
    'DuoFaceAudit 3.txt': '0db33be9fe28ecfa9dcc1bdc14749aadfda21bc3',
}
CURRENT = '0.0.174~mapwake1'
TOPICS = {
    'wake': r'qa17[2789].*(?:logo|recall|touch)|qa120-(?:pane-tap|hosted-touch-hit)|media-pane-hit-test-target|logo-invisible-first-tap|gate-touch|pane-root-passive|logo.*(?:hide|hidden|wake)|kbstate',
    'maps': r'qa178-native-map|native-map|native-launch|command=Attach|Native Map ACK|Native Maps|native map|map-pane|map-reflow|GoogleMaps|com\.waze',
    'home': r'DFHome|home-publisher|home-admission|HomeRoster|NATIVE_DECLARATION|SELECTED_ADMISSION|BRIDGE_DECLARATION|Standalone Home:|home-.*(?:unavailable|reject|fail)|standalone.*(?:reject|fail|unavailable)',
    'lifecycle': r'qa12[345]-underlock|postlock-settings|background-abi|underlock-background|scene-lifecycle|screen.?blank|foreground-observed|scene-failed|scene-host-timeout',
    'errors': r'(?:exception|fatal|rejected|denied|failed|timeout|unavailable|unverified|not-ready|not-observed|not-found|invalid)',
}

def scope(line: str) -> str:
    match = re.search(r'\bbuild=([^\s]+)', line)
    return 'current174' if match and match[1] == CURRENT else ('other_stamped' if match else 'unstamped')

def excerpt(line: str, limit: int = 1400) -> str:
    return line if len(line) <= limit else line[:limit] + ' [LINE TRUNCATED; see pinned original]'

def sample(rows: list[dict], maximum: int = 65) -> list[dict]:
    # Unique messages retain actual source line numbers. Most recent occurrence wins.
    seen = set()
    result = []
    for row in reversed(rows):
        normalized = re.sub(r'^utc=\S+ uptime=\S+ build=\S+ pid=\d+ process=\S+ run=\S+ main=\d+ ', '', row['text'])
        normalized = re.sub(r'0x[0-9a-fA-F]+', 'PTR', normalized)
        normalized = re.sub(r'\b(?:utc|uptime|Timestamp|age|time)=\S+', 'time=VALUE', normalized)
        if normalized in seen:
            continue
        seen.add(normalized)
        result.append(row)
        if len(result) >= maximum:
            break
    return sorted(result, key=lambda row: row['line'])

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--input-dir', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--fetch', action='store_true')
    args = parser.parse_args()
    args.input_dir.mkdir(parents=True, exist_ok=True)
    args.out.mkdir(parents=True, exist_ok=True)
    manifest = []
    blobs = {}
    for name, expected in FILES.items():
        path = args.input_dir / name
        url = 'https://raw.githubusercontent.com/' + REPO + '/' + UPLOAD + '/' + urllib.parse.quote('sideplay/log/' + name, safe='/')
        if args.fetch:
            request = urllib.request.Request(url, headers={'User-Agent': 'DuoFace-four-log-readonly-audit'})
            with urllib.request.urlopen(request, timeout=90) as response:
                data = response.read(80 * 1024 * 1024 + 1)
            if len(data) > 80 * 1024 * 1024:
                raise RuntimeError('Log exceeds explicit safe size limit: ' + name)
            path.write_bytes(data)
        data = path.read_bytes()
        actual = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
        if actual != expected:
            raise RuntimeError('Pinned Git blob mismatch: ' + name)
        text = data.decode('utf-8-sig', errors='strict')
        lines = text.splitlines()
        blobs[name] = lines
        manifest.append({'path': 'sideplay/log/' + name, 'upload_commit': UPLOAD,
                         'git_blob_sha': actual, 'sha256': hashlib.sha256(data).hexdigest(),
                         'bytes': len(data), 'lines': len(lines), 'url': url})
    (args.out / 'MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n')
    crashes = ['# Three newly uploaded IPS files: event dates are not upload dates', '',
               'Only the three IPS files in upload ' + UPLOAD + ' are read. No older repository log is opened.', '']
    for name in FILES:
        if not name.endswith('.ips'):
            continue
        lines = blobs[name]
        crashes += ['## ' + name, '']
        for number, line in enumerate(lines[:48], 1):
            if number == 1 or re.match(r'^(Date/Time|End time|OS Version|Command|PID|Event|Action taken|Writes|Duration|Hardware model|Data Source)', line):
                crashes += [f'L{number}: {line}']
        start = next((i for i, line in enumerate(lines) if line.startswith('Heaviest stack')), -1)
        if start >= 0:
            end = start + 1
            while end < len(lines) and lines[end].strip():
                end += 1
            crashes += ['', '### Heaviest-stack excerpt', ''] + [f'L{i+1}: {lines[i]}' for i in range(start, min(end, start+38))]
            uuids = set(re.findall(r'<([0-9A-F-]{36})>', '\n'.join(lines[start:end])))
            crashes += ['', '### Image records for unresolved heaviest-stack UUIDs', '']
            for i, line in enumerate(lines):
                if re.match(r'^\s*0x[0-9a-fA-F]+\s*-', line) and any(u in line for u in uuids):
                    crashes.append(f'L{i+1}: {line}')
        crashes += ['']
    (args.out / 'CRASH_SUMMARY.md').write_text('\n'.join(crashes) + '\n')
    audit = blobs['DuoFaceAudit 3.txt']
    sections = []
    section = 'export-header'
    rows = []
    build_counts = Counter()
    by_topic = {topic: [] for topic in TOPICS}
    patterns = {topic: re.compile(pattern, re.I) for topic, pattern in TOPICS.items()}
    markers = Counter()
    reasons = Counter()
    epoch_values = []
    snapshots = []
    for number, line in enumerate(audit, 1):
        if line.startswith('==='):
            section = line
            sections.append({'line': number, 'heading': line})
        match = re.search(r'\bbuild=([^\s]+)', line)
        if match:
            build_counts[match[1]] += 1
        current_scope = scope(line)
        timestamp = re.search(r'\butc=(\d+(?:\.\d+)?)', line)
        if timestamp and current_scope == 'current174':
            epoch_values.append(float(timestamp[1]))
        event = re.search(r'\bevent=([^\s]+)', line)
        area = re.search(r'\barea=([^\s]+)', line)
        if event:
            markers[(current_scope, 'event=' + event[1])] += 1
        if area:
            markers[(current_scope, 'area=' + area[1])] += 1
        for token in re.findall(r'\bqa\d+[\w-]+', line):
            markers[(current_scope, token)] += 1
        for reason in re.findall(r'\breason=([^\n]+)', line):
            reasons[(current_scope, reason[:240])] += 1
        row = {'line': number, 'scope': current_scope, 'section': section, 'text': excerpt(line)}
        for topic, pattern in patterns.items():
            if pattern.search(line):
                by_topic[topic].append(row)
        if re.match(r'^(Date:|iOS:|App:|Audit schema:|Session active:|Standalone Home:|Native Map ACK:|Native Maps physical|Native Maps pixels|Remembered app slot|Native map chosen|Physical unplug|Disconnect close|Crash included:)', line):
            snapshots.append(row)
    summary = {
        'upload_commit': UPLOAD, 'reviewed_only': list(FILES),
        'audit_line_count': len(audit), 'audit_header': audit[:12], 'build_stamp_counts': dict(build_counts),
        'current174_utc_range': [datetime.fromtimestamp(t, timezone.utc).isoformat() for t in (min(epoch_values), max(epoch_values))] if epoch_values else None,
        'sections': sections, 'snapshot_lines': snapshots,
        'topic_counts_by_stamp': {topic: dict(Counter(row['scope'] for row in values)) for topic, values in by_topic.items()},
        'markers': [{'scope': s, 'marker': m, 'count': n} for (s,m),n in markers.most_common()],
        'reasons': [{'scope': s, 'reason': r, 'count': n} for (s,r),n in reasons.most_common()],
        'generated_at_utc': datetime.now(timezone.utc).isoformat(),
        'bounds': 'Unstamped section lines can be cumulative; do not assign them to QA174 without correlated time/session evidence. Historical IPS event dates remain historical even when uploaded today.'
    }
    (args.out / 'SUMMARY.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False) + '\n')
    overview = ['# Four latest uploaded logs: mechanical evidence overview', '',
                'Pinned upload commit: ' + UPLOAD, '', '## Exact four file identities', '']
    overview += [f"- `{item['path']}`: {item['bytes']} bytes, {item['lines']} lines, blob `{item['git_blob_sha']}`." for item in manifest]
    overview += ['', '## Export header', ''] + [f'L{i+1}: {line}' for i,line in enumerate(audit[:12])]
    overview += ['', '## Runtime build stamps', '', json.dumps(dict(build_counts), ensure_ascii=False), '',
                 'QA174 UTC range: ' + str(summary['current174_utc_range']), '', '## Section boundaries', '']
    overview += [f"L{x['line']}: {x['heading']}" for x in sections]
    overview += ['', '## Export snapshot', ''] + [f"L{x['line']}: {x['text']}" for x in snapshots]
    overview += ['', '## Marker counts (stamped QA174 only)', '']
    overview += [f"{item['marker']}: {item['count']}" for item in summary['markers'] if item['scope']=='current174']
    overview += ['', '## Limits', '', summary['bounds'], 'No runtime patch, DEB build, deployment or device execution is part of this analysis.']
    (args.out / 'OVERVIEW.md').write_text('\n'.join(overview) + '\n')
    for topic, values in by_topic.items():
        selected = []
        for s in ('current174','unstamped','other_stamped'):
            group = [row for row in values if row['scope']==s]
            # Only four new files are read; older stamped lines inside this export
            # are separated and are not used as proof of a QA174 failure.
            chosen = sample(group, 100 if s == 'current174' else 55 if s == 'unstamped' else 8)
            selected += ['## ' + s + f' ({len(group)} matching lines)', '']
            last_section = None
            for row in chosen:
                if row['section'] != last_section:
                    selected += ['', row['section'], '']
                    last_section = row['section']
                selected.append(f"L{row['line']}: {row['text']}")
            selected.append('')
        (args.out / (topic.upper() + '.md')).write_text('# ' + topic + ' evidence from DuoFaceAudit 3.txt\n\n' + '\n'.join(selected) + '\n')
    print('FOUR_PINNED_LOG_BLOBS_VERIFIED', UPLOAD)
    print(json.dumps({'build_stamps':dict(build_counts), 'current174_utc_range':summary['current174_utc_range'], 'topic_counts':summary['topic_counts_by_stamp']}, ensure_ascii=False))
    print('ANALYSIS_ONLY_NOT_FUNCTIONAL_PASS')

if __name__ == '__main__':
    main()
