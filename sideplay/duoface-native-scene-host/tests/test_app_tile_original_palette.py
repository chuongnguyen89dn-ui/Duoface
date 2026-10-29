"""Static regression against SHA-pinned Native12 APP state audit, not pixel/device parity."""
import json
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
    def test_original_dark_material_sheet_and_shadow(self):
        p=(ROOT/"DFAppPickerVC.m").read_text()
        self.assertIn("UIBlurEffectStyleSystemMaterialDark",p)
        self.assertIn("self.sheet.layer.cornerRadius=20;",p)
        self.assertIn("self.sheet.layer.borderWidth=1;",p)
        self.assertIn("[UIColor colorWithWhite:1 alpha:.18]",p)
        self.assertIn("self.sheet.layer.shadowOpacity=.65;",p)
        self.assertIn("self.sheet.layer.shadowRadius=26;",p)
        self.assertIn("self.sheet.layer.shadowOffset=CGSizeMake(0,10);",p)
        self.assertIn("self.view.backgroundColor=[UIColor colorWithWhite:0 alpha:.65];",p)
    def test_original_dark_material_sheet_and_shadow(self):
        p=(ROOT/"DFAppPickerVC.m").read_text()
        self.assertIn("UIBlurEffectStyleSystemMaterialDark",p)
        self.assertIn("self.sheet.layer.cornerRadius=20;",p)
        self.assertIn("self.sheet.layer.borderWidth=1;",p)
        self.assertIn("[UIColor colorWithWhite:1 alpha:.18]",p)
        self.assertIn("self.sheet.layer.shadowOpacity=.65;",p)
        self.assertIn("self.sheet.layer.shadowRadius=26;",p)
        self.assertIn("self.sheet.layer.shadowOffset=CGSizeMake(0,10);",p)
        self.assertIn("self.view.backgroundColor=[UIColor colorWithWhite:0 alpha:.65];",p)
    def test_real_badge_states_and_geometry(self):
        p=(ROOT/"DFAppPickerVC.m").read_text()
        self.assertIn("card.appBadgeKind=selectedApp?1:(otherSlotApp?2:0);",p)
        self.assertIn("checkmark.circle.fill",p)
        self.assertIn("arrow.left.arrow.right.circle.fill",p)
        self.assertIn("[UIColor colorWithRed:.08 green:.52 blue:1 alpha:1]",p)
        self.assertIn("[UIColor colorWithRed:1 green:.62 blue:.04 alpha:1]",p)
        self.assertIn("configurationWithPaletteColors:@[UIColor.whiteColor,badgeAccent]",p)
        self.assertIn("CGRectGetMaxX(self.icon.frame)-.65*badgeSide",p)
        self.assertIn("CGRectGetMinY(self.icon.frame)-.20*badgeSide",p)
        self.assertIn("iconSide<40?14:(self.appGridColumns==6?16:18)",p)
        self.assertIn("self.appStateBadge.layer.shadowOpacity=.5",p)
        self.assertIn("self.appStateBadge.layer.shadowRadius=2.5",p)
        self.assertIn("self.appStateBadge.layer.shadowOffset=CGSizeMake(0,1)",p)
        self.assertIn("card.appBadgeKind=0;",p)
        self.assertIn("self.appStateBadge.hidden=self.runningControls || self.appBadgeKind==0;",p)
    def test_other_slot_from_scene_ready_only_and_swapped(self):
        c=(ROOT/"DFNative12Chrome.m").read_text()
        h=(ROOT/"DFAppPickerVC.h").read_text()
        self.assertIn("otherSlotBundleIDs",h)
        self.assertIn("if(visual==slot)continue;",c)
        self.assertIn("(self.swapped && visual<2)?1-visual:visual",c)
        self.assertIn("if(![self.sceneHandleReady[(NSUInteger)otherPhysical] boolValue])continue;",c)
        self.assertIn("bundleIDForHostedView:otherScene",c)
        self.assertIn("self.appPickerController.otherSlotBundleIDs=others.array;",c)
    def test_exact_original_arm64_badge_anchor(self):
        # Actual SHA-pinned Native12 disassembly and VM float evidence,
        # not an assertion based on current first-party source comments.
        audit=ROOT.parent/"audit/native12-app-2debs-20261023/runs/39896596511"
        imp=json.loads((audit/"extra-original-app-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json").read_text())
        self.assertEqual(imp["original_native12_deb_sha256"],
            "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad")
        m=next(v for v in imp["methods"]
            if v["selector"]=="setupAppPickerCardsInCardW:cardH:contentY:")
        self.assertEqual(m["imp"],"0xa3e5c")
        code="\\n".join(m["instructions"])
        for pc,needle in [
            ("a4a70","mov.16b"),
            ("a4a80","cmp"),
            ("a4c24","fcmp"),
            ("a4c28","fmov"),
            ("a4c2c","fcsel"),
            ("a4c38","fmul"),
            ("a4c40","fmul"),
            ("a4c44","fadd"),
            ("a4c48","stp"),
            ("a522c","cbz"),
            ("a5374","ldr"),
            ("a52e0","checkmark.circle.fill"),
            ("a542c","arrow.left.arrow.right.circle.fill"),
            ("a54fc","fmov"),
            ("a5528","fmov"),
        ]:
            self.assertTrue(any(line.startswith(pc+":") and needle in line
                for line in m["instructions"]),pc)
        numeric=json.loads((audit/"actual-original-numerics/RAW_APP_LITERALS_AND_CALLSITES.json").read_text())
        floats={v["pc"]:v["value"] for v in
            numeric["methods"]["setupAppPickerCardsInCardW:cardH:contentY:"]["literal_floats"]}
        self.assertAlmostEqual(floats["0xa4c08"],-.65)
        self.assertAlmostEqual(floats["0xa4c10"],-.20)
        self.assertAlmostEqual(floats["0xa493c"],.225)
    def test_original_localized_modes_and_inactive_palette(self):
        p=(ROOT/"DFAppPickerVC.m").read_text()
        self.assertIn('names=@[DFLocalize(@"Ứng dụng",@"Apps")',p)
        self.assertIn('DFLocalize(@"Bố cục",@"Layouts")',p)
        self.assertIn('DFLocalize(@"Đang mở",@"Running")',p)
        self.assertIn("[UIColor colorWithWhite:.68 alpha:1]",p)

if __name__=="__main__":unittest.main()
