#!/usr/bin/env python3
"""Static regression guards for original104-derived QA scene launch sequencing.
NOT a device test or proof that first-respring exitMode is resolved.
"""
from pathlib import Path
import math

root = Path(__file__).resolve().parents[3]
runtime = (root/"replacement/visual12/engine/runtime/DFIRuntime.m").read_text()
ui = (root/"replacement/visual12/engine/runtime/DFIInterface.inc").read_text()

def method(source, start, end):
    assert source.count(start) == 1, start
    return source.split(start,1)[1].split(end,1)[0]

attach = method(runtime, "- (void)attachTo:(UIViewController *)parent container:(UIView *)container {", "- (void)moveToContainer:")
assert attach.index("[self resizeTo:paneSize];") < attach.index("setRequestedMode:",attach.index("DFIInteger(self.controller"))
assert "paneSize.width<=0" in attach
poll = method(runtime, "- (void)pollScene {", "- (void)resizeTo:")
assert poll.index("if(pane.width>0 && pane.height>0)[self resizeTo:pane];") < poll.index("if(!self.sceneReadyNotified")
assert poll.index("[self applySize];") < poll.index("self.sceneReadyNotified=YES;")
sizing = method(runtime,"- (void)resizeTo:(CGSize)size {","- (void)applySize {")
assert "round(size.width*2)" in sizing and "round(size.height*2)" in sizing
# Decompiled 1.0.4: the nested device app view is resized as well, with
# UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight (0x12).
assert "inner.frame=(CGRect){CGPointZero,logical};" in sizing
assert "inner.autoresizingMask=UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight" in sizing
assert "view.frame=(CGRect){CGPointZero,logical};" in sizing
assert "CGAffineTransformMakeScale(scale,scale)" in sizing
assert "NSInteger orientation=UIInterfaceOrientationPortrait;" in sizing
assert 'DFIRect(settings,@"setFrame:"' in runtime
assert 'if(geometry[@"orientation"])' in runtime
assert "Original updateSceneSettingsFrame changes the frame" in runtime
for w,h in [(120,200),(401.25,270.75),(600,280)]:
    original104 = (math.floor(2*w+0.5),math.floor(2*h+0.5))
    # C99/ObjC round() and ARM64 FRINTA both round a positive half away
    # from zero; Python built-in round() is ties-to-even and is NOT equivalent.
    independent = (math.floor(2*w+0.5),math.floor(2*h+0.5))
    assert original104 == independent, (w,h,original104,independent)

loading = method(ui,"- (void)viewDidLoad {\n [super viewDidLoad];self.view.backgroundColor","- (void)viewDidAppear:")
assert "openBundle:" not in loading, "Do not open app scene during viewDidLoad"
assert "savedAppsRestoreStarted" in ui and "- (void)restoreNextSavedPane" in ui
changing = method(ui,"- (void)openBundle:(NSString *)bid pane:(NSInteger)pane {","- (void)saveLayout")
assert changing.index("[previous close]") < changing.index("initWithBundleID:bid error:&error")
assert changing.index("dispatch_after") < changing.index("initWithBundleID:bid error:&error")
assert "QA scene host allocate bundle=" in changing
shutdown = method(runtime,"- (void)close {","- (void)dealloc {")
assert shutdown.index('@"setRequestedMode:",0') < shutdown.index('SEL invalidate=NSSelectorFromString(@"invalidate")')
assert '@"QA scene invalidate end"' in shutdown
print("ORIGINAL104_QA_SCENE_GEOMETRY_LAUNCH_ORDER_SOURCE_CONTRACT_PASS")
print("STATIC_ONLY_NOT_DEVICE_TESTED_FIRST_RESPRING_EXITMODE_UNRESOLVED")
