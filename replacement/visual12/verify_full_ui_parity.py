#!/usr/bin/env python3
"""Static guard for retaining the existing DuoFace interface."""
from pathlib import Path

root = Path(__file__).resolve().parents[2]
source = (root / 'replacement/visual12/engine/runtime/DFIInterface.inc').read_text()
required = ['DFV12SplitController', 'DFV12List', 'self.layoutKind>8', 'i<3;i++', 'self.toolbarStack', 'self.panel']
missing = [item for item in required if item not in source]
if missing:
    raise SystemExit('DuoFace interface baseline incomplete: ' + ', '.join(missing))
print('DuoFace interface baseline markers verified')
