"""QA168: independent CarPlay maneuver model, transport and HUD contract.
This does not assert that GOFA or another app calls our first-party adapter.
"""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class TestQA168(unittest.TestCase):
    def test_protocol_is_fresh_and_requires_known_turn(self):
        protocol=(ROOT/"DF168NativeManeuver.h").read_text()
        for v in ("DF168TurnUnknown","DF168TurnLeft","DF168TurnRight",
                  "DF168TurnUTurn","DF168_MAX_DISTANCE_METERS",
                  "DF168_MAX_AGE_SECONDS","DF168ManeuverEncode",
                  "DF168ManeuverDecode"):
            self.assertIn(v,protocol)
        self.assertNotIn("cameraUpcoming",protocol)
        self.assertNotIn("roadSpeedLimit",protocol)
    def test_public_carplay_source_not_private_vendor_abi(self):
        source=(ROOT/"DF168PublicCarPlayManeuverAdapter.m").read_text()
        for v in ("CPManeuver","CPTravelEstimates","instructionVariants",
                  "distanceRemaining","DF168TurnUnknown",
                  "DF168PublishManeuver(turn,","isfinite(meters)"):
            self.assertIn(v,source)
        self.assertNotIn("method_setImplementation",source)
        self.assertNotIn("GOFA.DatapointModel",source)
    def test_compiled_and_fresh_only_across_real_hud_owners(self):
        build=(ROOT/"build.sh").read_text()
        view=(ROOT/"speed8/DFNative8SpeedHUDView.mm").read_text()
        self.assertGreaterEqual(build.count("DF168NativeManeuver.m"),4)
        self.assertIn("DF168PublicCarPlayManeuverAdapter.m",build)
        self.assertIn("DF168ReadManeuver(&maneuver)",view)
        self.assertIn('else self.unit.text=@"km/h"',view)
        self.assertIn("DF168TurnLeft",view)
        self.assertIn("DF168TurnRight",view)
        self.assertIn("DF168TurnUTurn",view)
    def test_producer_restricted_and_inactive_until_real_calls(self):
        transport=(ROOT/"DF168NativeManeuver.m").read_text()
        self.assertIn("com.lumi.GOFA",transport)
        self.assertIn("notify_set_state",transport)
        self.assertIn("notify_get_state",transport)
        self.assertNotIn("requestWhenInUseAuthorization",transport)
if __name__=="__main__":unittest.main()
