#!/usr/bin/env python3
"""Derive ONLY our own verified iOS16 admission code, scoped to isolated Gate1 ID.
Generated .m files are build inputs and are never committed or installed directly.
"""
from pathlib import Path
import plistlib
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent / "firstparty-carplay-admission"
OUT=ROOT / ".generated"
OUT.mkdir(exist_ok=True)
replacements={
    "com.duoface.native.scenehost":"com.duoface.gate1smoke",
    "com.duoface.firstparty-admission.plist":"com.duoface.gate1smoke.plist",
    ".duoface-firstparty-admission-disable":".duoface-gate1smoke-disable",
    "com.duoface.firstparty-admission.refresh":"com.duoface.gate1smoke.refresh",
    "DuoFaceFirstPartyAdmission.log":"DuoFaceGate1CarPlay.log",
    "DuoFaceFirstPartySpringBoard.log":"DuoFaceGate1SpringBoard.log",
}
for src,dest,pref in [
    ("DFFirstPartyAdmission.m","Gate1CarPlay.m","NSDictionary *d=[NSDictionary dictionaryWithContentsOfFile:DFPrefs];"),
    ("DFFirstPartySpringBoard.m","Gate1SpringBoard.m","NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:kPrefs];")]:
    text=(SOURCE/src).read_text()
    assert text.count("com.duoface.native.scenehost")==1,(src,"host ID unexpected")
    for old,new in replacements.items():
        text=text.replace(old,new)
    assert text.count(pref)==1,(src,"consent anchor missing")
    guard=f"""
    // Don't refuse dormant legacy Enabled prefs while its kill switch is ON.
    NSDictionary *other=[NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.duoface.firstparty-admission.plist"];
    BOOL oldEffective=[other[@"Enabled"] boolValue] &&
        [other[@"RiskAcknowledged"] boolValue] &&
        [other[@"HostBundleID"] isEqualToString:@"com.duoface.native.scenehost"] &&
        access("/var/mobile/Library/Preferences/.duoface-firstparty-admission-disable",F_OK)!=0;
    if(oldEffective)return NO;
"""
    text=text.replace(pref,pref+guard)
    if dest=="Gate1SpringBoard.m":
        anchor='if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;'
        assert text.count(anchor)==1
        text=text.replace(anchor,anchor+'\n      rosterLog("gate1-smoke-SpringBoard-loaded; default-off\\n");')
    assert 'com.duoface.native.scenehost' not in text
    assert 'com.duoface.gate1smoke' in text
    assert '.duoface-gate1smoke-disable' in text
    assert 'oldEffective' in text
    (OUT/dest).write_text(text)
print("GATE1_OWN_BUNDLE_SCOPED_GENERATION_PASS")
