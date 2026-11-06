"""Verify the iPhone carrier uses the executable shared ACK/lifecycle policy.

The Foundation harness exercises state and time semantics. These checks cover
the real UIKit method wiring, with negative controls for bypassing its guards.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
PHONE = (ROOT / "DFNativeHostRootController.m").read_text()


def command_method(source):
    begin = source.index("- (void)nativeMapPaneCommand:(NSString *)operation slot:(NSInteger)slot bundle:")
    end = source.index("- (void)pollNativeMapAckForRequest:", begin)
    return source[begin:end]


def poll_method(source):
    begin = source.index("- (void)pollNativeMapAckForRequest:")
    end = source.index("- (void)nativeMapPaneAlert:", begin)
    return source[begin:end]


def uses_bound_poll_policy(source):
    body = poll_method(source)
    read_at = body.index("NSDictionary *ack=")
    prefix = body[:read_at]
    return all(token in prefix for token in (
        "DFNativeMapPollDecisionForRequest(",
        "request,self.nativeMapActiveRequest,generation,self.nativeMapCommandGeneration,active,",
        "startedMonotonic,NSProcessInfo.processInfo.systemUptime,completedPolls)",
        "if(decision==DFNativeMapPollStop)return;",
        "if(decision==DFNativeMapPollTimedOut)",
    ))


def uses_terminal_ack_policy(source):
    body = poll_method(source)
    declaration = re.search(r"BOOL terminal=([^;]+);", body)
    if not declaration:
        return False
    states = re.sub(r"\s+", "", declaration.group(1))
    return (
        "DFNativeMapAckReadState(ack,request,operation," in body
        and "requestedAt,NSDate.date.timeIntervalSince1970)" in body
        and states == "state==DFNativeMapAckApplied||state==DFNativeMapAckRejected||state==DFNativeMapAckCancelled"
        and "if(terminal && !self.presentedViewController)" in body
    )


class NativeMapCommandProtocol(unittest.TestCase):
    def test_current_controller_and_request_gate_every_poll(self):
        self.assertTrue(uses_bound_poll_policy(PHONE))
        for before, after in (
            ("if(decision==DFNativeMapPollStop)return;", "/* stale request allowed */"),
            ("generation,self.nativeMapCommandGeneration,active,", "generation,generation,active,"),
            ("startedMonotonic,NSProcessInfo.processInfo.systemUptime,completedPolls)",
             "startedMonotonic,NSDate.date.timeIntervalSince1970,completedPolls)"),
        ):
            broken = PHONE.replace(before, after, 1)
            self.assertNotEqual(broken, PHONE)
            self.assertFalse(uses_bound_poll_policy(broken))

    def test_pending_and_malformed_ack_cannot_be_shown_as_terminal(self):
        self.assertTrue(uses_terminal_ack_policy(PHONE))
        for before, after in (
            ("DFNativeMapAckReadState(ack,request,operation,", "UnverifiedAck(ack,request,operation,"),
            ("BOOL terminal=state==DFNativeMapAckApplied", "BOOL terminal=state==DFNativeMapAckPending"),
        ):
            broken = PHONE.replace(before, after, 1)
            self.assertNotEqual(broken, PHONE)
            self.assertFalse(uses_terminal_ack_policy(broken))

    def test_polling_never_resends_or_refreshes_the_command(self):
        command, poll = command_method(PHONE), poll_method(PHONE)
        self.assertEqual(command.count("[record writeToFile:commandPath atomically:YES]"), 1)
        self.assertEqual(command.count('notify_post("com.duoface.nativehost.map-pane.command.v1")'), 1)
        self.assertIn('@"Timestamp":@(requestedAt)', command)
        self.assertIn("DFNativeMapClientAckPollInterval*NSEC_PER_SEC", command)
        self.assertNotIn("1.5*NSEC_PER_SEC", command)
        for forbidden in ("writeToFile:", "notify_post(", "NSUUID.UUID", '@"Timestamp":'):
            self.assertNotIn(forbidden, poll)
        self.assertIn("completedPolls:completedPolls+1", poll)
        self.assertIn("DFNativeMapClientAckPollInterval*NSEC_PER_SEC", poll)
        for section in (command, poll):
            self.assertIn("__weak typeof(self) weakSelf=self;", section)
            self.assertIn("[weakSelf pollNativeMapAckForRequest:", section)

    def test_leaving_ui_invalidates_pending_result_without_server_replay(self):
        leave = PHONE[PHONE.index("- (void)viewWillDisappear:(BOOL)animated {"):]
        self.assertIn("DFNativeMapNextCommandGeneration(self.nativeMapCommandGeneration)", leave)
        self.assertIn("self.nativeMapActiveRequest=nil;", leave)
        self.assertNotIn("nativeMapPaneCommand:", leave)
        self.assertNotIn("notify_post", leave)

    def test_phone_background_revokes_polling_before_later_foreground_callback(self):
        begin = PHONE.index("- (instancetype)initWithCarPlay:(BOOL)carPlay {")
        end = PHONE.index("- (UIImage *)art:", begin)
        lifecycle = PHONE[begin:end]
        self.assertIn("if(!carPlay)[NSNotificationCenter.defaultCenter addObserver:self", lifecycle)
        self.assertIn("selector:@selector(nativeMapPhoneDidEnterBackground:)", lifecycle)
        self.assertIn("name:UIApplicationDidEnterBackgroundNotification object:nil]", lifecycle)
        self.assertIn("removeObserver:self", lifecycle)
        begin = PHONE.index("- (void)nativeMapPhoneDidEnterBackground:")
        background = PHONE[begin:PHONE.index("- (void)viewWillDisappear:", begin)]
        self.assertIn("DFNativeMapNextCommandGeneration(self.nativeMapCommandGeneration)", background)
        self.assertIn("self.nativeMapActiveRequest=nil;", background)
        for forbidden in ("nativeMapPaneAlert:", "nativeMapPaneCommand:", "notify_post", "writeToFile:"):
            self.assertNotIn(forbidden, background)

    def test_shared_protocol_and_guarded_launch_instructions_are_used(self):
        self.assertIn('#import "../native-carplay-scene-v1/DFNativeMapCommandProtocol.h"', PHONE)
        self.assertIn('@"Version":@(DFNativeMapCommandVersion)', command_method(PHONE))
        self.assertNotIn("DuoFace chưa tự mở", PHONE)
        self.assertNotIn("Mở đúng ứng dụng bản đồ trực tiếp trên CarPlay", PHONE)
        self.assertIn("mở đúng ứng dụng một lần", PHONE)
        self.assertIn("chỉ ghép khi xác minh", PHONE)
        self.assertIn("vẫn cần kiểm tra trên xe", PHONE)
        self.assertIn("chưa xác nhận khả năng giữ ứng dụng chạy nền", PHONE)


if __name__ == "__main__":
    unittest.main(verbosity=2)
