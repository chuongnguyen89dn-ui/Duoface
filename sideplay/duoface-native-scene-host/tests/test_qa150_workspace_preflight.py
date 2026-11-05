"""QA150: source and ABI evidence gates, NOT a device workspace transition test."""
from pathlib import Path
import hashlib
import unittest
from native_map_host_guard import without_native_map_guard

BASE = Path(__file__).resolve().parents[1]
SOLO = (BASE / "DFHomeStandalone144.m").read_text()
PROBE = (BASE / "DFWorkspaceABIProbe150.h").read_text()
SCENE = without_native_map_guard((BASE / "DFSceneHost.m").read_bytes())
DOCK = (BASE / "DFNativeDockSync147.h").read_text()


class WorkspaceAndTerminalGate(unittest.TestCase):
    def test_two_read_only_process_probes_on_verified_selected_requests(self):
        self.assertIn('#import "DFWorkspaceABIProbe150.h"', SOLO)
        carplay = SOLO.split("static BOOL DF144BeginSelectedBridge(", 1)[1].split("static void DF144Launch(", 1)[0]
        self.assertLess(carplay.index("DF144ValidRequest(p,"), carplay.index("DF150ProbeWorkspaceForRequest(rid,bundle,display,NO)"))
        self.assertLess(carplay.index("DF150ProbeWorkspaceForRequest(rid,bundle,display,NO)"), carplay.index("notify_post(DF144RequestNotify)"))
        springboard = SOLO.split("static void DF144Consume(", 1)[1].split("__attribute__((constructor))static void DF144StartSpringBoard", 1)[0]
        self.assertLess(springboard.index("DF144ValidRequest(p,"), springboard.index("DF150ProbeWorkspaceForRequest(uuid,p"))
        self.assertLess(springboard.index("DF144Allowed(p["), springboard.index("DF150ProbeWorkspaceForRequest(uuid,p"))
        self.assertIn('DF150ProbeWorkspaceForRequest(uuid,p[@"BundleID"],p[@"CarDisplayID"],YES)', springboard)
        self.assertIn("qa150-native-workspace-abi", PROBE)
        self.assertIn("qa150-native-workspace-probe-complete", PROBE)

    def test_probe_reads_method_types_only_and_does_not_modify_workspace(self):
        for required in (
            "DBMutableWorkspaceStateChangeRequest",
            "deactivateApplication:",
            "setCompletionHandler:",
            "DBWorkspace",
            "requestStateChange:",
            "SBMainWorkspace",
            "executeTransitionRequest:",
            "clickedMenuButton",
            "class_getInstanceMethod",
            "class_getClassMethod",
            "method_getTypeEncoding",
        ):
            self.assertIn(required, PROBE)
        for prohibited in (
            "objc_msgSend", "method_setImplementation", "class_replaceMethod",
            "MSHookMessageEx", "alloc]", "performSelector:",
            "notify_post", "writeToFile:", "executeTransitionRequest:request)",
        ):
            self.assertNotIn(prohibited, PROBE)

    def test_no_duplicate_terminal_result_or_overwritten_exception(self):
        owner = SOLO.split("- (void)reply:(NSString *)state reason:(NSString *)reason verifiedPID:", 1)[1].split("- (void)reply:(NSString *)state reason:", 1)[0]
        self.assertLess(owner.index("if(self.emittedTerminal)"), owner.index("writeToFile:DF144Result"))
        self.assertIn('BOOL terminal=[state isEqualToString:@"failed"] || [state isEqualToString:@"stopped"]', owner)
        self.assertIn("if(terminal)self.emittedTerminal=YES;", owner)
        begin = SOLO.split("- (BOOL)begin:(NSDictionary *)p {",1)[1].split("- (void)attemptOwnedReadyForView:",1)[0]
        self.assertIn("self.emittedTerminal=NO",begin)
        reject = SOLO.split("static void DF150ReplyRejected(",1)[1].split("static void DF144Consume(",1)[0]
        self.assertIn('@"RequestID":p[@"RequestID"]',reject)
        self.assertIn('@"BundleID":p[@"BundleID"]',reject)
        self.assertIn('@"CarDisplayID":p[@"CarDisplayID"]',reject)
        self.assertIn('@"Outcome":@"failed"',reject)
        self.assertIn('@"VerifiedPID":@0',reject)
        self.assertIn('@"receiver-preflight-rejected-no-scene-owner"',reject)
        self.assertIn('qa150-preflight-terminal-preserved',reject)
        self.assertIn('qa150-preflight-rejected-terminal',reject)
        self.assertLess(reject.index('([outcome isEqualToString:@"failed"]'),reject.index("writeToFile:DF144Result"))
        self.assertNotIn("scene-hosted-render-and-touch-unverified",reject)

    def test_frozen_geometry_and_native_dock_not_swapped(self):
        actual=hashlib.sha1(b"blob "+str(len(SCENE)).encode()+b"\0"+SCENE).hexdigest()
        self.assertIn(actual, {"aeb6178654eebe3a052e358febcc0b2519c3ac54", "d1a71c03041d0d71f4a4ac6364ee14f84bf7f3de", "6a3c073f9d7502d588eb441d4ecb6c546c3f09f8"}) # original and reviewed QA160 solo-only fast probe
        self.assertIn("DF149Receive(&DF149Life,identity,fresh,",DOCK)
        self.assertIn("DF149NativeDockPressedOriginal(receiver,sel,button)",DOCK)
        self.assertIn("DF147RestoreDock",DOCK)


if __name__ == "__main__":
    unittest.main()
