#!/usr/bin/env python3
"""Static QA of Speed9 source-selection candidate; NO live source producer claim."""
from pathlib import Path
r=Path(".")
hud=(r/"runtime/speedbubble/DFSpeedNativeSplit9TrustedSourcesSpringBoard.mm").read_text()
reader=(r/"runtime/speedbubble/DFSpeedGMapReader9.mm").read_text()
tx=(r/"runtime/speedbubble/DFSpeedTransport9.mm").read_text()
catalog=(r/"runtime/speedbubble/DFSpeedInstalledSourceCatalog9.mm").read_text()
mk=(r/"Makefile.speedhud-native9trusted-qa-stage").read_text()
for required in (
    'CBTouchPassThroughRootSceneWindow','CBBridgedSplitApp','count<2 || count>4',
    'attached<2','pane.window==root','S7Unmount',
    '[root addSubview:s7HUD]','[root bringSubviewToFront:s7HUD]',
    'DFSpeedInstalledSupportedSources','showSourcePicker','selectSource:',
    'source==0', 'self.selectedSource=0',
    'DuoFaceSpeedSplit9-SpringBoard.jsonl',
    'initWithFrame:CGRectMake(0,0,104,46)'):
    assert required in hud, required
for forbidden in (
    '[[UIWindow alloc]','initWithWindowScene:','windowLevel=10000000',
    'MSHookMessageEx','method_setImplementation','com.google.Maps'):
    assert forbidden not in hud,forbidden
for name in ('com.waze.iphone','vn.vietmap.live','com.lumi.GOFA','LSApplicationProxy',
             'applicationProxyForIdentifier:'):
    assert name in catalog,name
assert '"Auto"' not in hud
assert 'if(!DFSpeedSourceInstalled(pinned)) return NO;' in tx
assert 'if(!DFSpeedSourceInstalled(pinned)) return false;' in reader
assert 'DFSpeedGMapReader9.mm' in mk
assert 'DFSpeedTransport9.mm' in mk
assert 'DFSpeedInstalledSourceCatalog9.mm' in mk
assert '-DDF_SPEED_HUD_SPRINGBOARD=1' in mk
assert 'CarPlayApp' not in (r/'DuoFaceSpeedHUDNative7.plist').read_text()
print('SPEED9_STATIC_MANUAL_INSTALLED_SOURCE_ONLY_SAME_SPLIT_HUD_PASS')
print('NO_NUMERIC_PROVIDER_BUILT; SILEO_UNCHANGED; DEVICE_UNTESTED')
