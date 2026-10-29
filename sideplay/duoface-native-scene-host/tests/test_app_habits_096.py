"""Personalized CarPlay picker source contracts (no signed DEB or device claim)."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def file(name):return (ROOT/name).read_text(encoding="utf-8")

class HabitsSource(unittest.TestCase):
    def test_policy_separate_preferences_no_auto_launch(self):
        p=file("DFAppHabits.h")
        for fragment in ("DFAppChoicesPath","DFAppHabitCountsPath",
                         "DFReadAppChoicesAtPath","DFWriteAppChoicesAtPath",
                         "DFRecordReadyAppHabitAtPath","DFRankAppIDsByHabits",
                         "DFAppChoicesChangedNotification"):
            self.assertIn(fragment,p)
        self.assertNotIn("hostViewForBundleID",p)
        self.assertNotIn("selectedSlot",p)

    def test_phone_can_set_default_and_favorites_but_not_panes(self):
        p=file("DFNativeHostRootController.m")
        for fragment in ("Đặt làm ứng dụng mặc định","Thêm vào Ưa dùng",
                         "DFSaveAppChoices","showHabitSettings",
                         "Mặc định & Ưa dùng"):
            self.assertIn(fragment,p)
        self.assertNotIn("AppSlotAssignments",p)

    def test_carplay_filtered_real_catalog_sorted_without_auto_replace(self):
        p=file("DFAppPickerVC.m")
        self.assertIn("DFPickerAllowsApp(app.bundleID,enabled)",p)
        self.assertIn("DFRankAppIDsByHabits",p)
        self.assertIn("DFAppChoicesChangedNotification",p)
        self.assertIn("notify_cancel(self.habitNotifyToken)",p)
        self.assertIn("didSelectBundleID:app.bundleID",p)

    def test_only_scene_ready_records_usage(self):
        p=file("DFNative12Chrome.m")
        source=p.split("- (void)sceneReady:(NSNotification *)note {",1)[1]
        ready=source.split("- (void)sceneFailed:",1)[0]
        self.assertIn("DFRecordReadyAppHabit(readyBundle)",ready)
        self.assertIn("self.sceneHandleReady[(NSUInteger)i]=@YES;",ready)
        self.assertIn('DFRecordReadyAppHabit(readyBundle)',ready.split('sceneHandleReady[(NSUInteger)i]=@YES;',1)[1])

if __name__=="__main__":
    unittest.main(verbosity=2)
