"""Static safety regressions for QA147 launch ACK/owner reentrancy.

These assertions verify source-order and generation gates, not iPhone runtime behavior.
"""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOLO = (ROOT / "DFHomeStandalone144.m").read_text()
HOST = (ROOT / "DFSceneHost.m").read_text()
DOCK = (ROOT / "DFNativeDockSync147.h").read_text()


class NativeStandaloneMountAndAck(unittest.TestCase):
    def test_pending_precedes_synchronous_mount_and_is_not_rewritten(self):
        body = SOLO.split("- (BOOL)begin:(NSDictionary *)p {", 1)[1].split("- (void)attemptOwnedReadyForView:", 1)[0]
        pending = body.index('[self reply:@"pending-scene"')
        mount = body.index("[root.view addSubview:v]")
        self.assertLess(pending, mount, "pending must precede reentrant UIKit mount")
        self.assertEqual(body.count('[self reply:@"pending-scene"'), 1)
        self.assertIn("self.generation!=generation", body[mount:])
        self.assertIn("self.surface!=v", body[mount:])
        self.assertIn("self.window!=w", body[mount:])
        self.assertIn("mount-reentrancy-terminal", body[mount:])
        self.assertIn("return NO;", body[mount:])

    def test_ack_only_from_real_host_with_pid_and_generation(self):
        body = SOLO.split("- (void)attemptOwnedReadyForView:", 1)[1].split("- (void)sceneFailed:", 1)[0]
        self.assertIn("self.generation!=generation", body)
        self.assertIn("self.surface!=v", body)
        self.assertIn("self.emittedHosted", body)
        self.assertIn("isLiveSceneForHostedView:v", body)
        self.assertIn("bundleIDForHostedView:v", body)
        self.assertIn("verifiedPIDForHostedView:v", body)
        self.assertIn("if(attempt>=14)return;", body)
        self.assertIn("dispatch_after(", body)
        self.assertIn('[self reply:@"scene-hosted-render-and-touch-unverified"', body)
        self.assertIn("qa147-ready-pid-unavailable", body)

    def test_failure_operation_and_dimensions_observable(self):
        self.assertIn('@"attach-exception-operation"', HOST)
        self.assertIn('@"mount-app-view"', HOST)
        self.assertIn('@"request-mode-2"', HOST)
        self.assertIn('@"before-standalone-mount"', SOLO)
        self.assertIn('@"after-standalone-mount"', SOLO)
        self.assertIn("NSStringFromCGRect(w.bounds)", SOLO)

    def test_no_fake_native_dock_activation(self):
        self.assertIn("DF147ResultAction(&DF147Life,identity,fresh,hosted,terminal,pid)", DOCK)
        self.assertIn('BOOL hosted=[outcome isEqual:@"scene-hosted-render-and-touch-unverified"]', DOCK)
        self.assertNotIn("scene-ready-and-play-verified", SOLO)


if __name__ == "__main__":
    unittest.main()
