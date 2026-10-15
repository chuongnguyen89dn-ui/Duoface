#!/usr/bin/env python3
"""Static numerical menu-row check only; NOT a device test or DEB build."""
import hashlib
import json
import math
import re
from pathlib import Path
src_path = Path("runtime/fullscreen/DFPickerZoomMenu.xm")
src = src_path.read_text()
def number(name):
    match=re.search(r"const CGFloat "+re.escape(name)+r"=([0-9.]+);",src)
    assert match,name
    return float(match.group(1))
height=number("menuHeight")
inset=number("sideInset")
logo=number("logoWidth")
x_reserved=number("xReserved")
assert height==30.0 and logo==120.0 and x_reserved>=44.0
assert "NSString *zoomTitle=@\"Zoom\";" in src
assert 'DFDecorate(close,@"Close"' in src
assert "DFClearNativePickerChrome(overlay)" in src
assert 'DFBuildingNativeAddTile' in src
match=re.search(r"const CGFloat desired\[4\]=\{([^}]+)\};",src)
assert match
widths=[float(v.strip()) for v in match.group(1).split(",")]
assert len(widths)==4
button_total=number("buttonTotal")
assert abs(sum(widths)-button_total)<0.01
checks=[]
for sheet in (350, 360, 390, 420, 480, 520, 550, 600, 720):
    available=sheet-2*inset-logo-x_reserved
    gap=max(6.,(available-button_total)/5.)
    scale=min(1.,(available-5*gap)/button_total)
    if scale<0.72:
        checks.append(dict(sheet_width=sheet,status="native_fallback_no_overlap",scale=round(scale,3)))
        continue
    menu_width=sum(math.floor(v*scale) for v in widths)+3*gap
    menu_left=inset+logo+gap
    menu_right=menu_left+menu_width
    native_x_left=sheet-inset-x_reserved
    remainder=native_x_left-menu_right
    assert remainder>=gap-1e-6,(sheet,remainder,gap)
    assert menu_left>=inset+logo+6
    assert menu_right<native_x_left,(sheet,menu_right,native_x_left)
    checks.append(dict(sheet_width=sheet,status="safe_static_layout",
                       logo_left=inset,logo_right=inset+logo,
                       tabs_left=round(menu_left,2),tabs_right=round(menu_right,2),
                       reserved_x_left=round(native_x_left,2),
                       gap=round(gap,2),scale=round(scale,3)))
data=dict(status="STATIC_GEOMETRY_NOT_DEVICE_PASS",source_sha256=hashlib.sha256(src.encode()).hexdigest(),
          menu_height_pt=height,logo_slot_width_pt=logo,native_x_reserved_pt=x_reserved,
          checks=checks,deb_built=False,device_tested=False)
out=Path("audit/duoface-picker-layout-sanity-20261015.json")
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(data,indent=2)+"\n")
print(out.read_text())
