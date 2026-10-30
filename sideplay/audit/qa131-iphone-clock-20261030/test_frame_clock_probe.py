#!/usr/bin/env python3
"""Safety contract for QA131 passive iOS16 app-scene frame-clock probe."""
import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[3]
YT=(ROOT/"sideplay/duoface-native-scene-host/DFYouTubeOrientationRelay.m").read_text()
HOST=(ROOT/"sideplay/duoface-native-scene-host/DFSceneHost.m").read_text()
class FrameClockProbe(unittest.TestCase):
 def test_reads_exact_leased_scene_only(self):
  self.assertIn("if(scene!=self.scene",YT)
  self.assertIn("self.frameClockScene=scene;",YT)
  self.assertIn("DFYTValidState(self.state,now)",YT)
  self.assertIn("if(!owned)",YT)
  self.assertIn("self.scene=owned;",YT)
  self.assertIn("[self startFrameClockObservation:owned];",YT)
  self.assertIn("DFYTBundle",YT)
 def test_ios16_api_not_future_beta_api(self):
  self.assertIn("[actual displayLinkWithTarget:self selector:@selector(frameClockTick:)]",YT)
  self.assertNotIn("[scene displayLinkWithTarget:",YT)
  self.assertIn("link.preferredFramesPerSecond=5",YT)
 def test_readonly_no_global_screen_or_player_control(self):
  # Existing orientation logic is intentionally preserved.
  self.assertIn("DFYTRotate(window,UIInterfaceOrientationPortrait)",YT)
  self.assertIn("DFYTVirtualUpdateLease(self.state,owned)",YT)
  self.assertNotIn("BKSDisplayServicesSetScreenBlanked",YT)
  self.assertNotIn("PreventUserIdleDisplaySleep",YT)
  self.assertNotIn("setIdleTimerDisabled",YT)
  self.assertNotIn("MSHookFunction",YT)
  self.assertNotIn("sendEvent:",YT)
 def test_bounded_and_session_reversible(self):
  self.assertIn("now-self.lastFrameClockReportAt<5",YT)
  self.assertIn("DFYTPost(DFYTAckName",YT)
  self.assertIn("qa131-iphone-display-clock-observed",YT)
  self.assertIn("[self.frameClock invalidate]; self.frameClock=nil;",YT)
  self.assertIn("self.frameClockScene=nil;self.frameClockTicks=0",YT)
  self.assertIn("onMainScreen",YT)
  self.assertIn("protectedData",YT)
 def test_host_log_distinguishes_tick_from_play_ack(self):
  self.assertIn("ack[@\"ticks\"]",HOST)
  self.assertIn("ack[@\"elapsedSeconds\"]",HOST)
  self.assertIn("ack[@\"sceneActivation\"]",HOST)
  self.assertIn("youtube-app-handshake-ack",HOST)
if __name__=="__main__":unittest.main()
