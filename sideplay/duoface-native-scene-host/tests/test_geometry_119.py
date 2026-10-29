from pathlib import Path
import copy
import importlib.util
import unittest

HOST=Path(__file__).resolve().parents[1]
SCRIPT=HOST.parent/'audit/dock-geometry-119/analyze_geometry.py'
spec=importlib.util.spec_from_file_location('geometry',SCRIPT)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

def fixture():
    screen='{{0, 0}, {800, 480}}'
    w={'ScreenBounds':screen,'Scale':2,'Hidden':False,'WindowInScreen':'{{60, 0}, {370, 480}}'}
    payloads={
      'DuoFaceNativeHost':{'CPWindow':dict(w)},
      'SpringBoard':{'PhysicalGeometry':{'Windows':[dict(w)],'Fullscreen':False,'Startup':False}},
      'CarPlayApp':{'DockCandidates':[{'OwnerWindow':dict(w),'FrameInScreen':'{{0, 0}, {50, 480}}'}]}}
    return [{'Schema':119,'Kind':'geometry-readonly','Session':'test-session','Sample':'test-sample',
             'SampleTime':100,'Timestamp':100+i*.2,'Process':p,'Measurements':v}
            for i,(p,v) in enumerate(payloads.items())]

class Geometry119(unittest.TestCase):
    def test_joins_candidate_without_claiming_fix(self):
        r=m.analyze(fixture())[0]
        self.assertEqual(r['pane_dock_gap_points'],10)
        self.assertFalse(r['layout_change_authorized']);self.assertFalse(r['device_pass'])
    def test_rejects_cross_session(self):
        f=fixture();f[-1]['Session']='other'
        self.assertTrue(all(r['status']=='unresolved' for r in m.analyze(f)))
    def test_rejects_stale_or_clock_skew(self):
        for stamp in (98,105,float('nan')):
            f=fixture();f[-1]['Timestamp']=stamp
            self.assertEqual(m.analyze(f)[0]['status'],'unresolved')
    def test_rejects_duplicate_dock_and_process(self):
        f=fixture();f[-1]['Measurements']['DockCandidates']*=2
        self.assertEqual(m.analyze(f)[0]['status'],'unresolved')
        f=fixture();f.append(copy.deepcopy(f[0]))
        self.assertEqual(m.analyze(f)[0]['status'],'unresolved')
    def test_rejects_screen_scale_and_fullscreen(self):
        f=fixture();f[-1]['Measurements']['DockCandidates'][0]['OwnerWindow']['Scale']=3
        self.assertEqual(m.analyze(f)[0]['status'],'unresolved')
        f=fixture();f[1]['Measurements']['PhysicalGeometry']['Fullscreen']=True
        self.assertEqual(m.analyze(f)[0]['status'],'unresolved')
    def test_negative_overlap_reported_not_clamped(self):
        f=fixture();f[-1]['Measurements']['DockCandidates'][0]['FrameInScreen']='{{0,0},{65,480}}'
        self.assertEqual(m.analyze(f)[0]['pane_dock_gap_points'],-5)
    def test_invalid_rect(self):
        for value in ('unavailable','{{nan,0},{10,20}}','{{0,0},{-10,20}}',None):
            self.assertIsNone(m.rect(value))
    def test_probe_is_observational(self):
        src=(HOST/'DFGeometrySnapshot119.h').read_text()
        for forbidden in ('setFrame:', 'setHidden:', 'makeKeyAndVisible','method_setImplementation','addGestureRecognizer','layoutIfNeeded'):
            self.assertNotIn(forbidden,src)
        self.assertIn('sampleAge<=3.5',src)
        self.assertIn('method_getNumberOfArguments(m)!=2',src)
        self.assertIn('DuoFaceGeometry119-',(HOST/'DFNativeDiagnostics.m').read_text())

if __name__=='__main__':unittest.main()
