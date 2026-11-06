"""QA180 production integration guards. Behavior runs separately in Objective-C.
These guards are NOT physical event delivery or native CarPlay rendering tests.
"""
import hashlib
import os
from pathlib import Path
import unittest
ROOT=Path(os.environ.get('QA180_SOURCE_ROOT',Path(__file__).resolve().parents[1]))
def read(name):
    p=ROOT/name
    return p.read_text() if p.exists() else ''
CHROME=read('DFNative12Chrome.m')
SCENE=read('DFSceneHost.m')
GATE=read('DFOwnedWakeSurface180.m')
def method(source,start,end):
    if start not in source:return ''
    a=source.index(start);b=source.find(end,a+len(start))
    return source[a:b if b>=0 else len(source)]
class OwnedWakeMap180(unittest.TestCase):
    def test_hidden_contact_contract_not_passive(self):
        self.assertIn('DFNativePanePassthroughView : DFOwnedWakeSurface180',CHROME)
        self.assertIn('DFSceneSurface : DFOwnedWakeSurface180',SCENE)
        self.assertIn('reservesWakeAtPoint180:point event:event])return self;',GATE)
    def test_occupied_map_selection_starts_explicit_replacement(self):
        tap=method(CHROME,'- (void)appPicker:(DFAppPickerVC *)picker\n    didSelectNativeMapBundleID:',
                   '- (void)appPicker:(DFAppPickerVC *)picker\n didSelectBundleID:')
        self.assertIn('[self df180BeginMapReplacement:bundleID name:name visual:slot physical:physical];',tap)
        self.assertIn('qa180-native-map-card-entry',tap)
    def test_no_new_shield_and_no_keyboard_ipc_prerequisite(self):
        bind=method(CHROME,'- (void)ensureWakeGates {','- (void)layoutControls {')
        for token in ('kbStateKnown177','kbVisible177','wakeGateEligible','initWithFrame:', 'layoutControls];'):
            self.assertNotIn(token,bind)
        self.assertIn('owner!=DF177CurrentTouchOwner',bind)
        self.assertIn('[owner df178RecallChromeVisualOnly];',bind)
        self.assertNotIn('DFNativeWakeGateView',CHROME)
    def test_gate_wakes_only_on_delivered_contact_and_drains_tail(self):
        hit=method(GATE,'- (UIView *)hitTest:','- (void)touchesBegan:')
        self.assertNotIn('self.wakeContact180(',hit)
        self.assertIn('touch.view!=self',GATE)
        self.assertIn('[forward minusSet:self.wakeContacts180',GATE)
        self.assertIn('touchesCancelled:',GATE)
        self.assertIn('isDescendantOfView:self',GATE)
    def test_replacement_waits_for_actual_empty_readback(self):
        wait=method(CHROME,'- (void)df180AwaitEmptyPane:', '- (void)df180BeginMapReplacement:')
        self.assertIn('DF180EmptyPaneReadbackReady(',wait)
        self.assertIn('physical-panes.v1.plist',wait)
        self.assertNotIn('writeToFile:',wait)
        self.assertLess(wait.index('DF180EmptyPaneReadbackReady('),wait.index('didSelectNativeMapBundleID:'))
    def test_selected_pane_only_and_no_forced_native_adoption(self):
        begin=method(CHROME,'- (void)df180BeginMapReplacement:', '- (void)df178PollNativeMapPicker:')
        self.assertIn('self.hostedScenes[(NSUInteger)physical]=NSNull.null;',begin)
        self.assertIn('bundleIDForHostedView:active',begin)
        self.assertNotIn('stopAllHosts',begin)
        self.assertNotIn('kill(',begin)
        self.assertIn('DFNativeMapFreshLease',begin)
        self.assertIn('DFNativeMapAckReadState',CHROME)
    def test_cancel_or_timeout_requires_restore_ack_before_rollback(self):
        poll=method(CHROME,'- (void)df180PollMapRestore:', '- (void)df180AbortMapReplacement:')
        self.assertIn('DFNativeMapAckReadState(ack,request,@"Restore"',poll)
        self.assertIn('restorePrevious:YES reason:@"restore-ack-confirmed"',poll)
        self.assertIn('restorePrevious:NO reason:@"restore-unverified-pane-left-empty"',poll)
        abort=method(CHROME,'- (void)df180AbortMapReplacement:', '- (void)df180AwaitEmptyPane:')
        self.assertIn('previous[@"RequestID"]',abort)
        self.assertIn('@"Operation":@"Restore"',abort)
    def test_no_underlock_gofa_or_native_coordinator_change(self):
        blobs={'DFSceneLifecycle.m':'524a1af4ddc0789517890b8fea4d0bd2071bebb4',
               '../native-carplay-scene-v1/DFNativeMapPaneCoordinator.m':'7d70264250da60d705dbaf31e2411c0b6231778f',
               'DF154GeneralAppStateRelay.m':'160f4c52f9dc524223712ce61f0dd8f2a58830ed'}
        for name,expected in blobs.items():
            b=(ROOT/name).read_bytes()
            self.assertEqual(hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest(),expected,name)
    def test_gate_is_in_actual_build_not_only_a_test_fixture(self):
        self.assertIn('DFOwnedWakeSurface180.m DFSceneHost.m',read('build.sh'))
        self.assertIn('#import "DFOwnedWakeSurface180.h"',SCENE)
        self.assertIn('#import "DFOwnedWakeSurface180.h"',CHROME)
if __name__=='__main__':unittest.main()
