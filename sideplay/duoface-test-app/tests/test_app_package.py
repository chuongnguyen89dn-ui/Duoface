#!/usr/bin/env python3
from pathlib import Path
import plistlib, unittest, re
ROOT=Path(__file__).resolve().parents[1]
def source(path):return (ROOT/path).read_text()
class InstalledAppContract(unittest.TestCase):
    def test_actual_launchable_app_not_settings_panel(self):
        v=plistlib.loads((ROOT/'App/Info.plist').read_bytes())
        self.assertEqual(v['CFBundleExecutable'],'DuoFaceTest')
        self.assertEqual(v['CFBundleIdentifier'],'com.duoface.testapp')
        self.assertEqual(v['CFBundlePackageType'],'APPL')
        self.assertIn('CFBundleIcons',v)
        self.assertIn('UIApplicationMain',source('App/main.m'))
        self.assertIn('makeKeyAndVisible',source('App/DFAppDelegate.m'))
        self.assertIn('UIScrollView',source('App/DFAppDelegate.m'))
    def test_actions_are_wired_to_real_user_controls(self):
        a=source('App/DFAppDelegate.m')
        for m in ('startTest','stopTest','checkStatus','shareLog','DFPost(DFStart)','DFPost(DFStop)','DFPost(DFStatus)',
                  'UIActivityViewController','DFReceive','UIAlertController'):
            self.assertIn(m,a)
        self.assertIn('DuoFace Test',a)
        self.assertNotIn('Filza',a)
    def test_springboard_only_no_boot_admission_hooks(self):
        s=source('Controller/DFTestSpringBoardController.m')
        for bad in ('LSBundleProxy','FBSDisplayConfiguration','%hook','UIRootSceneWindow',
                    'method_setImplementation','UIApplicationDidFinishLaunchingNotification'):
            self.assertNotIn(bad,s)
        p=plistlib.loads((ROOT/'Controller/DFTestSpringBoardController.plist').read_bytes())
        self.assertEqual(p['Filter']['Executables'],['SpringBoard'])
        self.assertIn('CFNotificationCenterAddObserver',s)
    def test_explicit_45s_optin_auto_restores(self):
        s=source('Controller/DFTestSpringBoardController.m')
        self.assertIn('case',source('DEBIAN/postinst'))
        self.assertNotIn('sbreload',source('DEBIAN/postinst'))
        self.assertNotIn('ldrestart',source('DEBIAN/postinst'))
        self.assertIn('scheduledTimerWithTimeInterval:45',s)
        self.assertIn('DFRestore(YES)',s)
        self.assertIn('DFRestore(NO)',s)
        self.assertIn('bridge[@"Enabled"]=@NO',s)
        self.assertIn('bridge[@"NativeSidebarTrial"]=@NO',s)
        self.assertIn('base[@"Enabled"]=former',s)
        self.assertIn('@"BaseHadKey"',s)
        self.assertNotIn('NSNull null',s)
        self.assertIn('DFTestActive',s)
        self.assertIn('DFAckEnabled',s)
    def test_single_sileo_app_with_auto_dependencies(self):
        c=source('DEBIAN/control')
        self.assertIn('Package: com.duoface.testapp',c)
        self.assertIn('Name: DuoFace Test',c)
        self.assertIn('Version: 0.1.0~app1',c)
        self.assertIn('com.duoface.carplay.nativebridgeqa (>= 0.0.4~nativegeometry1)',c)
        self.assertIn('com.duoface.mytweak.v1a.preflight',c)
        for x in ('Conflicts:','Replaces:','Breaks:'):self.assertNotIn(x,c)
    def test_app_icon_generated_independently(self):
        s=source('scripts/make_icon.py')
        self.assertIn('AppIcon60x60@2x.png',s)
        self.assertIn('AppIcon60x60@3x.png',s)
        self.assertNotIn('SidePlay',s)
    def test_installer_never_activates_on_install(self):
        s=source('DEBIAN/postinst')
        self.assertIn('uicache',s)
        for x in ('Enabled=true','Enabled = YES','NativeSidebarTrial=true','killall','launchctl','sbreload'):
            self.assertNotIn(x,s)
if __name__=='__main__':unittest.main(verbosity=2)
