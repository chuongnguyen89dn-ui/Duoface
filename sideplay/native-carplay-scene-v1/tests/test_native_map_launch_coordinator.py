"""Source integration gates for the executable native launch lifecycle policy.

Foundation harnesses execute the actual policy/native-shaped dispatcher on CI;
these wiring checks prevent routing around those gates. They do not run UIKit.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def section(source, start, end):
    return source.split(start, 1)[1].split(end, 1)[0]


def assert_auto_cannot_launch(source):
    auto = section(source, "- (void)autoRestoreAfterReconnectIfVerified {",
                   "- (void)refreshAdoptedNativeMapBounds {")
    assert "self.pendingLaunch || self.adoptionInProgress" in auto
    assert "DFMapUniqueOwnerForBundle(owners,bundle)" in auto
    assert "[self handleAttachCommand:cmd allowLaunch:NO]" in auto
    assert "handleCommand:" not in auto
    assert "allowLaunch:YES" not in auto
    assert "DispatchLaunch" not in auto


def assert_dispatch_is_claimed_once(source):
    begin = section(source, "- (void)beginPendingLaunch:", "- (void)handleAttachCommand:")
    assert begin.index("self.pendingLaunch=pending;") < begin.index("DFNativeMapLaunchClaimAttempt(")
    assert begin.index("DFNativeMapLaunchClaimAttempt(") < begin.index("DFNativeMapDispatchLaunchGuarded(")
    assert begin.index("DFNativeMapDispatchLaunchGuarded(") < begin.index("DFNativeMapLaunchMarkSubmitted(")
    assert begin.index("DFNativeMapLaunchMarkSubmitted(") < begin.index("[self advancePendingLaunch]")
    assert '"Timestamp":cmd[@"Timestamp"]' in begin
    assert "now-[cmd[@\"Timestamp\"] doubleValue]" in begin
    assert "pending.context=context" in begin
    assert "pending.plan=observation.plan" in begin
    for forbidden in ("DFNativeMapSaveChoice", "DFNativeMapWriteLease", "handleCommand:"):
        assert forbidden not in begin
    assert source.count("DFNativeMapDispatchLaunchGuarded(") == 1


def assert_native_observations_preserve_command_generation(source):
    attach = section(source, "- (void)handleAttachCommand:", "- (void)handleCommand:")
    observe = attach.index("[self observeBundle:")
    assert attach.index("uint64_t commandGeneration=self.commandGeneration;") < observe
    between = attach[observe:attach.index("DFNativeMapSelectAttachAction(")]
    assert "DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration)" in between
    assert "pending:nil generation:commandGeneration" in attach
    assert "observation:observation generation:commandGeneration" in attach
    begin = section(source, "- (void)beginPendingLaunch:", "- (void)handleAttachCommand:")
    resolver = begin.index("DFNativeMapResolveLaunchContext(")
    admission = begin.index("DFNativeMapLaunchBeginForCommand(")
    assert "DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration)" in begin[resolver:admission]
    assert "&_launchState,commandGeneration,self.commandGeneration" in begin
    assert "pending.commandGeneration=commandGeneration" in begin
    adopt = section(source, "- (void)adoptCommand:", "- (void)advancePendingLaunch {")
    assert "generation:(uint64_t)commandGeneration" in adopt
    assert "uint64_t commandGeneration=self.commandGeneration" not in adopt
    selected = section(source, "- (BOOL)pendingRequestRemainsSelected:", "- (BOOL)pendingDispatchIsCurrent:")
    assert "DFNativeMapCommandGenerationMatches(pending.commandGeneration,self.commandGeneration)" in selected
    reply = section(source, "- (void)replyCurrent:", "- (void)finishPending:")
    assert reply.index("DFNativeMapCommandGenerationMatches(") < reply.index("[self reply:command")


class NativeMapLaunchCoordinator(unittest.TestCase):
    def setUp(self):
        self.source = (ROOT / "DFNativeMapPaneCoordinator.m").read_text()

    def test_only_fresh_explicit_command_can_reach_launch_action(self):
        explicit = section(self.source, "- (void)handleCommand:", "- (void)handle {")
        self.assertLess(explicit.index("DFNativeMapFreshExplicitCommand("),
                        explicit.index("DFNativeMapConsumeExplicitRequest("))
        self.assertLess(explicit.index("DFNativeMapConsumeExplicitRequest("),
                        explicit.index("[self cancelPending:"))
        self.assertIn("[self handleAttachCommand:cmd allowLaunch:YES]", explicit)
        attach = section(self.source, "- (void)handleAttachCommand:", "- (void)handleCommand:")
        self.assertIn("DFNativeMapSelectAttachAction(", attach)
        self.assertIn("allowLaunch,observation.matchingOwners,observation.owner!=nil", attach)
        self.assertIn("case DFNativeMapAttachRejectAmbiguous:", attach)
        self.assertIn("case DFNativeMapAttachRejectNotReady:", attach)
        self.assertIn("case DFNativeMapAttachStartLaunch:", attach)
        assert_auto_cannot_launch(self.source)

    def test_pending_request_preserves_original_identity_and_claims_before_dispatch(self):
        assert_dispatch_is_claimed_once(self.source)
        advance = section(self.source, "- (void)advancePendingLaunch {", "- (void)beginPendingLaunch:")
        self.assertIn("DFNativeMapLaunchReadyToAdopt", advance)
        self.assertIn("[self adoptCommand:pending.command", advance)
        for forbidden in ("handleCommand:", "handleAttachCommand:", "DispatchLaunch", "@\"Timestamp\""):
            self.assertNotIn(forbidden, advance)

    def test_pre_pending_native_reentry_cannot_overwrite_newer_command_or_ack(self):
        assert_native_observations_preserve_command_generation(self.source)
        needle = ("DFMapPaneObservation *observation=[self observeBundle:requestedBundle slot:number.integerValue];\n"
                  "    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration))return;")
        replacement = "DFMapPaneObservation *observation=[self observeBundle:requestedBundle slot:number.integerValue];"
        unguarded = self.source.replace(needle, replacement, 1)
        self.assertNotEqual(unguarded, self.source)
        with self.assertRaises(AssertionError):
            assert_native_observations_preserve_command_generation(unguarded)

    def test_final_dispatch_guard_reads_only_first_party_state_and_fresh_receipts(self):
        guard = section(self.source, "- (BOOL)pendingDispatchIsCurrent:", "- (BOOL)pendingCommitIsCurrent:")
        for contract in ("pendingRequestRemainsSelected:", "DFPhysicalMapVerifyPane(",
                         "DFOwnerSessionRevoked(pending.session)", "pending.context.physicalSession",
                         "DFNativeMapLaunchEvaluate(", "systemUptime", "DFNativeMapFreshExplicitCommand("):
            self.assertIn(contract, guard)
        for forbidden in ("DFNativeMapResolveLaunchContext(", "DFMapReadObject(",
                          "DFMapFindVC(", "observeBundle:", "observePending:"):
            self.assertNotIn(forbidden, guard)

    def test_final_commit_reads_home_generation_after_all_native_getters(self):
        guard = section(self.source, "- (BOOL)pendingCommitIsCurrent:", "- (DFMapPaneObservation *)observePending:")
        for contract in ("DF_NATIVE_MAP_HOME_GENERATION_SYMBOL", "readHomeGeneration?readHomeGeneration():0",
                         "DFNativeMapLaunchCanCommit(", "DFPhysicalMapVerifyPane(",
                         "DFOwnerSessionRevoked(pending.session)", "systemUptime"):
            self.assertIn(contract, guard)
        for forbidden in ("DFNativeMapResolveLaunchContext(", "DFMapReadObject(", "DFMapFindVC(",
                          "observeBundle:", "observePending:", "hasVerifiedNativeOwner", "DFMapVerifiedBundle("):
            self.assertNotIn(forbidden, guard)
        adopt = section(self.source, "- (void)adoptCommand:", "- (void)advancePendingLaunch {")
        boundary = adopt.index("[self pendingCommitIsCurrent:pending]")
        self.assertLess(adopt.rindex("[adapter hasVerifiedNativeOwner]"), boundary)
        self.assertLess(adopt.rindex("DFMapVerifiedBundle(self.owner)"), boundary)
        self.assertLess(boundary, adopt.index("self.adoptionCommitted=YES;"))
        self.assertLess(boundary, adopt.index("DFNativeMapSaveChoiceForBundle("))

    def test_every_observation_and_immediate_adoption_check_revalidates_session_and_context(self):
        observed = section(self.source, "- (DFMapPaneObservation *)observeBundle:", "- (BOOL)pendingRequestRemainsSelected:")
        self.assertIn('DFOwnerSessionRevoked(binding[@"Session"])', observed)
        self.assertIn("DFMapMatchingOwnerCount(owners,requestedBundle)", observed)
        pending = section(self.source, "- (DFMapPaneObservation *)observePending:", "- (void)adoptCommand:")
        for contract in ("DFNativeMapResolveLaunchContext(", "context.physicalSession",
                         "observation.physicalSlot==pending.physicalSlot", "DFNativeMapLaunchEvaluate("):
            self.assertIn(contract, pending)
        adopt = section(self.source, "- (void)adoptCommand:", "- (void)advancePendingLaunch {")
        self.assertLess(adopt.index("allowOwnedLease:NO"), adopt.index("DFNativeMapLaunchClaimAdoption("))
        self.assertLess(adopt.index("DFNativeMapLaunchClaimAdoption("), adopt.index("[adapter adoptNativeController:"))
        self.assertLess(adopt.index("[adapter adoptNativeController:"), adopt.index("allowOwnedLease:YES"))
        self.assertLess(adopt.index("allowOwnedLease:YES"), adopt.index("DFNativeMapSaveChoiceForBundle("))
        self.assertLess(adopt.index("CGRect actualInDashboard="), adopt.index("DFNativeMapSaveChoiceForBundle("))
        self.assertIn("!DFOwnerSessionRevoked(self.boundSession)", adopt)
        self.assertLess(adopt.index("self.geometryVerified=YES;"), adopt.index("DFNativeMapWriteLease("))
        self.assertLess(adopt.index("self.adoptionCommitted=YES;"), adopt.index("DFNativeMapWriteLease("))
        self.assertLess(adopt.index("native-launch-invalidated-before-commit"),
                        adopt.index("self.adoptionCommitted=YES;"))

    def test_cancel_and_reentrant_tick_cannot_write_a_premature_lease(self):
        finish = section(self.source, "- (void)finishPending:", "- (void)cancelPending:")
        self.assertLess(finish.index("DFNativeMapLaunchInvalidate("), finish.index("self.pendingLaunch=nil;"))
        self.assertLess(finish.index("self.pendingLaunch=nil;"), finish.index("[self reply:pending.command"))
        tick = section(self.source, "- (void)tick:", "- (void)start {")
        self.assertLess(tick.index("if(self.adoptionInProgress){[self handle];return;}"),
                        tick.index("if(self.adapter.isAttached)"))
        self.assertLess(tick.index("[self handle]; //"), tick.index("[self advancePendingLaunch];"))
        self.assertLess(tick.index("[self advancePendingLaunch];"), tick.index("[self autoRestoreAfterReconnectIfVerified];"))
        self.assertIn("if(!self.adoptionCommitted)", tick)
        self.assertIn("self.geometryVerified && self.adoptionCommitted &&", tick)
        refresh = section(self.source, "- (void)refreshAdoptedNativeMapBounds {", "- (void)tick:")
        self.assertIn("!DFOwnerSessionRevoked(self.boundSession)", refresh)

    def test_negative_controls_detect_automatic_launch_and_unclaimed_or_premature_event(self):
        automatic = self.source.replace("[self handleAttachCommand:cmd allowLaunch:NO]",
                                        "[self handleAttachCommand:cmd allowLaunch:YES]", 1)
        self.assertNotEqual(automatic, self.source)
        with self.assertRaises(AssertionError):
            assert_auto_cannot_launch(automatic)
        unclaimed = self.source.replace("DFNativeMapLaunchClaimAttempt(", "UNSAFE_UNCLAIMED_EVENT(", 1)
        with self.assertRaises((AssertionError, ValueError)):
            assert_dispatch_is_claimed_once(unclaimed)
        premature = self.source.replace("    self.pendingLaunch=pending;",
                                        "    DFNativeMapWriteLease(nil,nil,0);\n    self.pendingLaunch=pending;", 1)
        with self.assertRaises(AssertionError):
            assert_dispatch_is_claimed_once(premature)


if __name__ == "__main__":
    unittest.main(verbosity=2)
