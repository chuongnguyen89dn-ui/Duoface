"""User-observed CarPlay .106 regression: no in-car App approval UI;
restore exact trusted .92 divider machine and survive modal hide/reveal.
Source-only proof, separate from actual car hardware acceptance.
"""
import json
from pathlib import Path
import unittest

BASE=Path(__file__).resolve().parents[1]
def load(name):
    return (BASE/name).read_text(encoding="utf8")

class PhoneOnlyPickerAndDivider107(unittest.TestCase):
    def test_carplay_must_never_approve_new_apps(self):
        picker=load("DFAppPickerVC.m")
        phone=load("DFNativeHostRootController.m")
        self.assertIn("DFPickerAllowsApp(app.bundleID,enabled)",picker)
        self.assertIn("DFPickerAllowsApp(app.bundleID,DFConfiguredEnabledAppIDs())",picker)
        self.assertIn("return self.apps;",picker)
        self.assertIn("NSInteger count=(NSInteger)self.visibleApps.count;",picker)
        self.assertIn("DFWriteEnabledAppIDs(",phone)
        for forbidden in ("DFWriteEnabledAppIDs(","DFAddMoreAppsController",
                          "presentAddMore","showCategoryMenu","categoryButton",
                          "UINavigationController","UIAlertController",
                          "Phân loại ứng dụng","plus.circle.fill"):
            self.assertNotIn(forbidden,picker,forbidden)
        self.assertIn("My Apps — Đã chọn",phone)

    def test_all_five_critical_divider_sections_identical_to_working_092(self):
        source=load("DFNative12Chrome.m")
        golden=json.loads(load("tests/fixtures/divider92_exact_source.json"))
        self.assertEqual(golden["reference_blob"],
                         "367689325f6ff84d8d258ff9891ec85338a7d647")
        for name,section in golden["parts"].items():
            start,end=section["start"],section["end"]
            self.assertIn(start,source)
            a=source.index(start)
            z=source.index(end,a)
            self.assertEqual(source[a:z],section["text"],
                             f".92 original divider source changed: {name}")

    def test_only_drop_dangling_gesture_when_ui_owner_is_hidden(self):
        chrome=load("DFNative12Chrome.m")
        block=chrome.split("- (void)layoutControls {",1)[1].split("    CGRect cr=self.contentRect;",1)[0]
        self.assertIn("DFSlotCountForPreset(self.preset)<=1",block)
        self.assertIn("self.focus>=0",block)
        self.assertIn("self.appPickerVisible",block)
        self.assertIn("self.styleVisible",block)
        self.assertIn("if(unavailable && (_dividerDrag.active",block)
        self.assertIn("_dividerDrag.active=false;",block)
        self.assertIn("self.panActive=NO;",block)
        self.assertIn("self.logoTouchPending=NO;",block)
        self.assertIn("self.logoHoldGate=(DFLogoHoldGate){0};",block)
        # While the divider is available the old .92 state machine is untouched.
        self.assertNotIn("DFDragMove",block)
        self.assertNotIn("self.ratio=",block)
        self.assertNotIn("DFDragFinish",block)
        self.assertIn("divider92-hidden-owner-contact-cancelled-for-next-reveal",block)

if __name__=="__main__":
    unittest.main(verbosity=2)
