"""Join exported schema-119 JSON lines by session/sample. Diagnostic, never a layout patch."""
import argparse
import json
import math
import re
from collections import defaultdict
from pathlib import Path


def rect(value):
    if not isinstance(value, str):
        return None
    nums = re.findall(r'[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?', value)
    if len(nums) != 4:
        return None
    r = list(map(float, nums))
    return r if all(map(math.isfinite, r)) and r[2] > 0 and r[3] > 0 else None


def analyze(records):
    groups = defaultdict(list)
    for r in records:
        if r.get('Schema') == 119 and r.get('Kind') == 'geometry-readonly':
            groups[r.get('Session'), r.get('Sample')].append(r)
    result = []
    for (session, sample), group in groups.items():
        out = {'session': session, 'sample': sample, 'status': 'unresolved',
               'layout_change_authorized': False, 'device_pass': False}
        result.append(out)
        if not session or not sample:
            out['reason'] = 'missing-session-or-sample'; continue
        times = [r.get('Timestamp') for r in group]
        requests = [r.get('SampleTime') for r in group]
        if (not all(isinstance(t, (int,float)) and math.isfinite(t) for t in times + requests)
                or len(set(requests)) != 1 or max(times)-min(times) > 1.5
                or any(t < requests[0] or t-requests[0] > 3.5 for t in times)):
            out['reason'] = 'not-one-fresh-sample'; continue
        app = [r for r in group if r.get('Process') == 'DuoFaceNativeHost']
        sb = [r for r in group if r.get('Process') == 'SpringBoard']
        native = [r for r in group if r.get('Process') in ('CarPlayApp','CarPlay','Dashboard')]
        if len(app) != 1 or len(sb) != 1 or not native:
            out['reason'] = 'missing-or-duplicate-process-sample'; continue
        a, b = app[0]['Measurements'], sb[0]['Measurements']
        docks = [d for n in native for d in n['Measurements'].get('DockCandidates', [])]
        if len(docks) != 1 or any(n['Measurements'].get('InventoryTruncated') for n in native):
            out['reason'] = 'native-dock-missing-ambiguous-or-truncated'; continue
        dock = docks[0]
        owner = dock['OwnerWindow']
        cp = a['CPWindow']
        physical = b['PhysicalGeometry']
        screen = rect(cp.get('ScreenBounds'))
        if (screen is None or rect(owner.get('ScreenBounds')) != screen
                or owner.get('Scale') != cp.get('Scale') or owner.get('Hidden')
                or physical.get('Fullscreen') or physical.get('Startup')):
            out['reason'] = 'display-mismatch-hidden-dock-or-transitional-layout'; continue
        windows = [w for w in physical.get('Windows', []) if not w.get('Hidden')]
        if not windows or any(rect(w.get('ScreenBounds')) != screen or w.get('Scale') != cp.get('Scale') for w in windows):
            out['reason'] = 'physical-window-display-mismatch'; continue
        frames = [rect(w.get('WindowInScreen')) for w in windows]
        rail = rect(dock.get('FrameInScreen'))
        if rail is None or any(f is None for f in frames):
            out['reason'] = 'missing-converted-rectangles'; continue
        # Values are points in each process' UIScreen coordinate space; same
        # bounds/scale is a compatibility check, not proof of display identity.
        if abs(rail[0]-screen[0]) <= 1:
            gap = min(f[0] for f in frames) - (rail[0]+rail[2])
            edge = 'left'
        elif abs(rail[0]+rail[2]-screen[0]-screen[2]) <= 1:
            gap = rail[0] - max(f[0]+f[2] for f in frames)
            edge = 'right'
        else:
            out['reason'] = 'dock-not-at-screen-edge'; continue
        out.update(status='measured-candidate', edge=edge, pane_dock_gap_points=gap,
                   reason='review-native-root-and-display-identity-before-layout-change',
                   native_root=[n['Measurements'].get('ActiveCarPlayRootCandidates', []) for n in native],
                   cp_window=cp, native_dock=dock, springboard=b)
    return result


def read_records(paths):
    for path in paths:
        for line in Path(path).read_text(errors='replace').splitlines():
            try:
                item=json.loads(line)
            except (ValueError, TypeError):
                continue  # Export headings and partial first line are expected.
            if isinstance(item, dict): yield item


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('logs', nargs='+')
    args=parser.parse_args()
    print(json.dumps(analyze(read_records(args.logs)), indent=2, ensure_ascii=False))
