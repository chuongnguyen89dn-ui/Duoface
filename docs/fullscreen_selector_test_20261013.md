# Fullscreen reverse engineering: executed selector test

Executed locally on extracted user-supplied Airaw 1.7.1k Mach-O:

```
python - <<'PY'
from pathlib import Path
import struct
p=Path('/mnt/data/airaw_audit/root/var/jb/Library/MobileSubstrate/DynamicLibraries/Airaw.dylib').read_bytes()
for a in [0x80c68,0x7e8a0,0x7f998]:
 v=struct.unpack_from('<Q',p,0x4000+a)[0]
 o=0x4000+(v&0xffffffff)
 print(hex(a),hex(v),p[o:o+80].split(b'\0')[0])
PY
```

Observed output:
```
0x80c68 0x100000000635cc b'layoutSubviews'
0x7e8a0 0x10000000062d4c b'isChk'
0x7f998 0x10000000065a8f b'setIsChk:'
```

This **test passes**: verifies binary pointer resolution and rules out previous claim that `0x4af40` is a fullscreen resize helper. It is an Objective-C selector stub. This is a static Airaw test, **not** a DuoFace build or iPhone CarPlay runtime test.

Next concrete target: discover app window resizing logic and measure frames before/after fullscreen on iOS16.7.x; use working v12 package `dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb`. Do not alter original app/split/usage-days or publish untested Sileo update.
