#!/usr/bin/env python3
"""Static native CarPlay scene and workspace admission contracts; NOT car-test."""
from pathlib import Path
import plistlib
import unittest
P=Path(__file__).resolve().parents[1]
def s(name):return (P/name).read_text(encoding='utf8')
class NativeScene(unittest.TestCase):
    def test_first_party_shell_and_carplay_role(self):
        data=plistlib.loads((P/'shell/Info.plist').read_bytes())
        self.assertEqual(data['CFBundleIdentifier'],'com.duoface.mytweak.shell')
        self.assertEqual(data['CFBundleExecutable'],'MTDuoFaceShell')
        self.assertIn('UIWindowSceneSessionRoleCarPlay',data['UIApplicationSceneManifest']['UISceneConfigurations'])
        self.assertTrue(data['UIApplicationSceneManifest']['UIApplicationSupportsMultipleScenes'])
        a=s('shell/MTDuoFaceShell.m')
        for name in ('initWithWindowScene:','sceneDidBecomeActive:',
                     'sceneDidEnterBackground:','sceneDidDisconnect:',
                     'NativeContentExcludesChrome','NativeCarPlayWindowScene'):
            if name=="initWithWindowScene:":
                self.assertIn('initWithWindowScene:ws',a)
            elif name=="HasNonzeroInsets":
                self.assertIn(name,a)
            else:self.assertIn(name,a)
        self.assertNotIn('DBDockWindow',a)
        self.assertNotIn('CBBridgeManager',a)
    def test_shell_geometry_not_guessing_pixels(self):
        a=s('MTNativeShellGeometry.m')
        for term in ('CarPlayRole','GeometryValid','NativeContentExcludesChrome',
                     'age>4.0','IndependentDuoFaceShell',
                     'NativeCarPlayWindowScene','CGRectEqualToRect(content,bounds)'):
            self.assertIn(term,a)
        b=s('MTBridgeCoordinator.m')
        for term in ('MTNativeShellUsableRect(window.frame,shell,&nativeContent)',
                     'native-shell-frame-rejected','native-shell-awaiting',
                     'MTNativeShellUsableRect(full,shell,&desired)',
                     'stopAllHosts'):
            self.assertIn(term,b)
        self.assertNotIn('MTDashboardUsableRect(full,context,&desired)',b)
        self.assertNotIn('MTDockContentRect(full,data,&desired)',b)
    def test_native_ownership_and_home_transitions(self):
        a=s('MTDashboardActivation.m')
        for term in ('DBApplicationController','DBMutableWorkspaceStateChangeRequest',
                     'applicationWithBundleIdentifier:','activateApplication:',
                     'requestStateChange:','MTDashboardWorkspace liveDashboardWorkspace',
                     'notify_register_dispatch','com.apple.CarPlay.dashboard',
                     'com.duoface.mytweak.shell'):
            self.assertIn(term,a)
        self.assertIn('[MTDashboardActivation requestNativeHomeFromSpringBoard]',s('MTBridgeCoordinator.m'))
    def test_only_own_bundle_is_admitted(self):
        a=s('MTCarPlayAdmission.m')
        for term in ('kOurShell','com.duoface.mytweak.shell',
                     'LSBundleProxy','LSBundleInfoCachedValues',
                     'CARCapableApp','SBStarkCapable','MTIsOwnProxy',
                     'objc_addLoadImageFunc'):
            self.assertIn(term,a)
        self.assertNotIn('com.duonavi',a)
        self.assertNotIn('Airaw.dylib',a)
        self.assertNotIn('CarSurf.dylib',a)
        self.assertIn('[MTCarPlayAdmission installIfNeeded]',s('V1ATweak.x'))
    def test_packaging_still_one_package(self):
        m=s('Makefile')
        self.assertIn('SUBPROJECTS += shell',m)
        self.assertIn('MTNativeShellGeometry.m',m)
        self.assertIn('MTCarPlayAdmission.m',m)
        self.assertIn('MTDashboardActivation.m',m)
        self.assertIn('aggregate.mk',m)
        self.assertIn('APPLICATION_NAME = MTDuoFaceShell',s('shell/Makefile'))
        self.assertEqual(s('control').count('Package:'),1)
        self.assertIn('0.2.5~shell1',s('control'))
        self.assertTrue((P/'layout/DEBIAN/postinst').exists())
if __name__=='__main__':unittest.main(verbosity=2)
