#!/usr/bin/env python3
"""Source-owned DuoFace Visual12 DEB QA: not proof of real CarPlay behavior."""
import hashlib
import io
import json
import pathlib
import plistlib
import struct
import subprocess
import sys
import tarfile

deb = pathlib.Path(sys.argv[1])
assert deb.is_file() and deb.stat().st_size > 30000, "Missing or truncated DEB"
control = subprocess.check_output(["dpkg-deb", "-f", str(deb)], text=True)
assert "Package: com.duoface.visual12\n" in control
assert "Architecture: iphoneos-arm64\n" in control
assert "Version: 1.0.3-12~standalone1\n" in control
assert "Conflicts:" not in control
assert "Replaces:" not in control
data = subprocess.check_output(["dpkg-deb", "--fsys-tarfile", str(deb)])
with tarfile.open(fileobj=io.BytesIO(data), mode="r:") as tf:
    files = {m.name.removeprefix("./"): tf.extractfile(m).read()
             for m in tf.getmembers() if m.isfile()}

app = "var/jb/Applications/DuoFaceVisual12.app/"
tweak = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisual12.dylib"
filter_plist = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisual12.plist"
prefs = "var/jb/Library/PreferenceBundles/DuoFaceVisual12Prefs.bundle/"
loader = "var/jb/Library/PreferenceLoader/Preferences/DuoFaceVisual12Prefs.plist"
resource = "var/jb/Library/Application Support/DuoFaceVisual12/"
assert len(files) >= 16, f"Unexpectedly small payload: {len(files)} files"
expected = [app + "DuoFaceVisual12", app + "Info.plist", tweak, filter_plist,
            prefs + "DuoFaceVisual12Prefs", prefs + "Info.plist", loader,
            resource + "asset-transfer-manifest.json"]
for path in expected:
    assert path in files, f"Missing: {path}"

for path in files:
    lower = path.lower()
    assert not any(x in lower for x in ("duonavi", "duodash", "airaw", "duofacedashboard")), path
    assert "duofaceindependent" not in lower, f"Could overwrite Hub: {path}"
    assert not lower.startswith("var/mobile/library/preferences/"), f"Unexpected preference overwrite: {path}"
assert not any("com.duoface.independent" in x for x in files)
assert not any("com.duonavi.app" in x for x in files)

app_info = plistlib.loads(files[app + "Info.plist"])
pref_info = plistlib.loads(files[prefs + "Info.plist"])
pref_loader = plistlib.loads(files[loader])
injection = plistlib.loads(files[filter_plist])
assert app_info["CFBundleIdentifier"] == "com.duoface.visual12"
assert app_info["CFBundleExecutable"] == "DuoFaceVisual12"
assert pref_info["CFBundleIdentifier"] == "com.duoface.visual12.preferences"
assert pref_info["NSPrincipalClass"] == "DFV12PreferencesController"
assert pref_loader["entry"]["bundle"] == "DuoFaceVisual12Prefs"
assert pref_loader["entry"]["detail"] == "DFV12PreferencesController"
assert set(injection["Filter"]["Executables"]) == {"SpringBoard", "CarPlay"}
assert app_info["CFBundleIcons"]["CFBundlePrimaryIcon"]["CFBundleIconFiles"]

def inspect_macho(blob: bytes, expected_type: int):
    magic = blob[:4]
    assert magic == b"\xcf\xfa\xed\xfe", f"Expected ARM64 Mach-O, found {magic!r}"
    _, cpu, sub, kind, cmd_count, cmd_bytes, _, _ = struct.unpack_from("<8I", blob)
    assert cpu == 0x100000c and kind == expected_type
    assert 0 < cmd_count < 300 and 32 + cmd_bytes <= len(blob)
    cursor, signed, target_ios = 32, False, False
    for _ in range(cmd_count):
        cmd, size = struct.unpack_from("<II", blob, cursor)
        assert size >= 8 and cursor + size <= 32 + cmd_bytes
        if cmd == 0x1d:
            start, length = struct.unpack_from("<II", blob, cursor + 8)
            assert 0 < length <= len(blob) and start + length <= len(blob)
            assert blob[start:start + 4] == b"\xfa\xde\x0c\xc0", "Invalid code signature"
            signed = True
        if cmd == 0x32:
            platform, min_version = struct.unpack_from("<II", blob, cursor + 8)
            target_ios = platform == 2 and min_version <= 0x100000
        cursor += size
    assert signed and target_ios, "Binary must be signed for iOS16 or earlier"
for p, kind in [(app+"DuoFaceVisual12",2),(tweak,6),(prefs+"DuoFaceVisual12Prefs",8)]:
    inspect_macho(files[p],kind)

assets = json.loads(files[resource+"asset-transfer-manifest.json"].decode())
assert assets["source_hashes_verified"] >= 7
for rel, item in assets["files"].items():
    assert hashlib.sha256(files[resource+rel]).hexdigest() == item["sha256"], rel
assert len(assets["files"]) >= 7

for scale in (1,2,3):
    suffix = "" if scale == 1 else f"@{scale}x"
    png = files[prefs+f"Icon{suffix}.png"]
    assert png[:8] == b"\x89PNG\r\n\x1a\n"
    assert struct.unpack_from(">II",png,16) == (29*scale,29*scale)
print("VISUAL12_QA_DEB_PACKAGE_MACHO_SIGNATURE_ASSET_CHECKS_PASS")
print(f"package={deb.name} files={len(files)} size={deb.stat().st_size} sha256={hashlib.sha256(deb.read_bytes()).hexdigest()}")
print("NOT_TESTED_ON_IPHONE, NOT_PUBLISHED_TO_SILEO, NATIVE12_HUB8_UNCHANGED")
