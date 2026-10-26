"""Regression contract for the own app-side renderer handshake.

These tests do not assert device pixels: they verify that the original .71
missing application-process link is actually built and fully gated.
"""
import plistlib
import unittest
from pathlib import Path

R=Path(__file__).resolve().parents[1]
P=R.parent/"jb-embedded-appbridge"


class AppOwnedViewport(unittest.TestCase):
    def test_exact_app_allowlist_not_global_injection(self):
        d=plistlib.loads((R/"DFAppViewportRelay.plist").read_bytes())
        self.assertEqual(set(d["Filter"]["Bundles"]),{
            "com.openai.chat","com.google.ios.youtube",
            "com.banyac.midrive.intl","com.google.Maps"})
        self.assertNotIn("Executables",d["Filter"])
        src=(R/"DFAppViewportRelay.m").read_text()
        for forbidden in ("MSHookMessageEx", "method_setImplementation",
                          "setInterfaceOrientation:", "setUserInterfaceIdiom:",
                          "setSceneClass:", "setWindowScene:",
                          "UIWindowSceneSessionRoleCarPlay"):
            self.assertNotIn(forbidden,src)

    def test_request_must_be_remote_host_accepted_before_app_layout(self):
        host=(R/"DFSceneHost.m").read_text()
        app=(R/"DFAppViewportRelay.m").read_text()
        self.assertIn("DFReadOwnedSceneFrame(scene,&actual)",host)
        self.assertIn("DFSceneFrameMatches(actual,expected)",host)
        self.assertIn('@"isHostingAnApp"',host)
        self.assertIn("self.appController.view.window==self.window",host)
        self.assertIn("notify_set_state(self.viewportNotifyToken,payload)",host)
        self.assertIn("notify_cancel(self.viewportNotifyToken)",host)
        self.assertIn("DFVPUnpack(raw,now,&width,&height,&active)",app)
        self.assertLess(app.index("DFVPMatches(scene.coordinateSpace.bounds.size,requested)"),
                        app.index("window.frame=target"))
        self.assertIn("if(window.hidden || window.windowScene!=scene)continue;",app)
        self.assertIn("rootViewController.view setNeedsLayout",app)
        self.assertIn('DFVPLog(@"app-scene-rejected-host-frame"',app)

    def test_inactive_and_expiry_is_fail_closed_not_phone_overwrite(self):
        protocol=(R/"DFAppViewportProtocol.h").read_text()
        host=(R/"DFSceneHost.m").read_text()
        self.assertIn("#define DFVP_MARKER 0xD2ULL",protocol)
        self.assertIn("if(age>3 || (a && (w<100 || h<100)))return 0;",protocol)
        self.assertIn("if(!active)return;",(R/"DFAppViewportRelay.m").read_text())
        self.assertIn("DFVPPack(0,0,",host)
        self.assertIn("notify_post(name.UTF8String)",host)

    def test_one_signed_rootless_deb_contains_real_app_receiver(self):
        build=(R/"build.sh").read_text()
        package=(P/"package_integrated.py").read_text()
        workflow=(R.parent.parent/".github/workflows/duoface-jb-embedded-appbridge-package.yml").read_text()
        self.assertIn('-o "$APP_DYLIB" DFAppViewportRelay.m',build)
        self.assertIn('cp DFAppViewportRelay.plist',build)
        self.assertIn('ldid -S "$APP_DYLIB"',build)
        self.assertIn('DFAppViewportRelay.dylib" not in seen',package)
        self.assertIn("DFAppViewportRelay.dylib",workflow)
        self.assertIn('VERSION="0.0.72~appscene1"',package)


if __name__=="__main__":
    unittest.main()
