"""Protect recovered GOFA geometry while collecting exact app-side evidence."""
from pathlib import Path
import plistlib
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PassiveGofa140(unittest.TestCase):
    def test_observer_cannot_change_layout_orientation_or_screen(self):
        source = (ROOT / 'DFGofaLayoutObserver140.m').read_text()
        for token in ('layoutIfNeeded', 'setNeedsLayout', 'setFrame:',
                      'setBounds:', 'requestGeometryUpdate', 'setInterfaceOrientation:',
                      'method_setImplementation', 'MSHookMessageEx',
                      'BKSDisplayServicesSetScreenBlanked'):
            self.assertNotIn(token, source)
        for token in ('rootBounds', 'rootFrame', 'rootTransform', 'screenBounds',
                      'screenScale', 'rootSafeArea', 'horizontalTrait',
                      'sceneActivation', 'pid', 'generation', 'read-only'):
            self.assertIn(token, source)
        with (ROOT / 'DFGofaLayoutObserver140.plist').open('rb') as file:
            self.assertEqual(plistlib.load(file), {'Filter': {'Bundles': ['com.lumi.GOFA']}})

    def test_recovered_scene_geometry_transaction_unchanged(self):
        current = (ROOT / 'DFSceneHost.m').read_text()
        baseline = subprocess.check_output([
            'git', 'show', '46a138c2:sideplay/duoface-native-scene-host/DFSceneHost.m'
        ], cwd=ROOT, text=True)
        def commit_method(text):
            start = text.index('- (void)commitSceneGeometry:', text.index('@implementation DFSceneSurface'))
            end = text.find('\n- (', start + 3)
            return text[start:end]
        self.assertEqual(commit_method(current), commit_method(baseline))

    def test_withdrawn_138_dylibs_are_not_reintroduced(self):
        build = (ROOT / 'build.sh').read_text()
        self.assertNotIn('DFHomeAdmission138.m', build)
        self.assertNotIn('DFGofaLayoutRelay.m', build)
        self.assertIn('DFHomeAdmission140.m', build)
        self.assertIn('DFGofaLayoutObserver140.m', build)


if __name__ == '__main__':
    unittest.main()
