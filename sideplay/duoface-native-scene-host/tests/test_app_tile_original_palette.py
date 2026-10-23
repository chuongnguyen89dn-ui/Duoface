"""Static regression against SHA-pinned Native12 APP state audit, not pixel/device parity."""
import pathlib
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]

class AppTileOriginalPalette(unittest.TestCase):
    def test_app_visual_is_not_running_card(self):
        p=(ROOT/"DFAppPickerVC.m").read_text()
        self.assertIn("card.contentView.backgroundColor=self.runningMode?",p)
        self.assertIn("[UIColor colorWithWhite:.19 alpha:.96]:UIColor.clearColor",p)
        self.assertIn("self.icon.layer.cornerRadius=self.runningControls?0:(.225*iconSide)",p)
        self.assertIn("[UIColor colorWithRed:.55 green:.80 blue:1 alpha:1]",p)
        self.assertIn("[UIColor colorWithWhite:.95 alpha:1]",p)
        self.assertIn("card.icon.layer.borderWidth=selectedApp?2:0;",p)
        self.assertIn("[UIColor colorWithRed:.15 green:.62 blue:1 alpha:1]",p)
        self.assertIn("self.currentSlotBundleID isEqualToString:app.bundleID",p)
    def test_verified_scene_identity_not_inventory_guess(self):
        h=(ROOT/"DFAppPickerVC.h").read_text()
        c=(ROOT/"DFNative12Chrome.m").read_text()
        self.assertIn("currentSlotBundleID",h)
        self.assertIn("if([self.sceneHandleReady[(NSUInteger)physical] boolValue])",c)
        self.assertIn("self.appPickerController.currentSlotBundleID=current;",c)
        self.assertIn("bundleIDForHostedView:surface",c)
    def test_original_localized_modes_and_inactive_palette(self):
        p=(ROOT/"DFAppPickerVC.m").read_text()
        self.assertIn('names=@[@"Ứng dụng",@"Bố cục",@"Đang mở"]',p)
        self.assertIn("[UIColor colorWithWhite:.68 alpha:1]",p)

if __name__=="__main__":unittest.main()
