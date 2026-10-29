"""Execute production drag arithmetic; does not simulate UIKit or certify CarPlay."""
import ctypes
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class DividerDrag(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        root = pathlib.Path(cls.tmp.name)
        (root / 'drag.c').write_text('''
#include "DFDividerDrag.h"
void run(int vertical, int grip, double width, double height, double *xy, int count,
         int cancelled, double *out) {
    DFDividerDrag d=DFDragBegin(100,100,vertical,.5,.5,width,height);
    d.allowLogo=grip;
    for(int i=0;i<count-1;i++) DFDragMove(&d,xy[2*i],xy[2*i+1]);
    bool tap=DFDragFinish(&d,xy[2*(count-1)],xy[2*(count-1)+1],cancelled);
    out[0]=d.ratio;out[1]=d.logo;out[2]=d.axis;out[3]=tap;out[4]=d.active;
}
''')
        subprocess.run(['cc', '-std=c99', '-Wall', '-Wextra', '-Werror',
                        '-shared', '-fPIC', '-I', str(ROOT), str(root/'drag.c'),
                        '-lm', '-o', str(root/'drag.so')], check=True)
        cls.lib = ctypes.CDLL(str(root/'drag.so'))
        cls.fn = cls.lib.run
        cls.fn.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_double, ctypes.c_double,
                           ctypes.POINTER(ctypes.c_double), ctypes.c_int,
                           ctypes.c_int, ctypes.POINTER(ctypes.c_double)]

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def drag(self, points, vertical=True, grip=True, cancelled=False, width=400, height=200):
        xy=(ctypes.c_double*(len(points)*2))(*[v for p in points for v in p])
        out=(ctypes.c_double*5)()
        self.fn(vertical,grip,width,height,xy,len(points),cancelled,out)
        self.assertEqual(out[4],0)
        return list(out)[:4]

    def test_logo_drag_parallel_moves_grip_only_without_3_second_hold(self):
        self.assertEqual(self.drag([(100,120),(100,140)]),[.5,.7,2,0])
        self.assertEqual(self.drag([(100,80),(100,60)]),[.5,.3,2,0])
        self.assertEqual(self.drag([(100,140)],grip=False),[.5,.5,0,0])

    def test_ratio_track_drag_cannot_reposition_logo(self):
        self.assertEqual(self.drag([(100,140),(140,140)],grip=False),[.6,.5,1,0])
        self.assertEqual(self.drag([(120,100)],grip=False),[.55,.5,1,0])

    def test_horizontal_ratio_keeps_logo(self):
        self.assertEqual(self.drag([(120,100),(140,100)]),[.6,.5,1,0])
        self.assertEqual(self.drag([(80,100),(60,100)]),[.4,.5,1,0])

    def test_final_event_applies_even_without_moved_events(self):
        self.assertEqual(self.drag([(100,140)]),[.5,.7,2,0])
        self.assertEqual(self.drag([(140,100)]),[.6,.5,1,0])

    def test_ambiguous_diagonal_waits_then_locks_one_axis(self):
        self.assertEqual(self.drag([(110,110),(120,120)]),[.5,.5,0,0])
        self.assertEqual(self.drag([(110,110),(110,130),(180,140)]),[.5,.7,2,0])
        self.assertEqual(self.drag([(120,100),(140,180)]),[.6,.5,1,0])

    def test_tap_jitter_and_return_after_drag(self):
        self.assertEqual(self.drag([(102,103),(100,100)]),[.5,.5,0,1])
        self.assertEqual(self.drag([(100,130),(100,100)]),[.5,.5,2,0])

    def test_cancel_restores_both_values_and_never_taps(self):
        self.assertEqual(self.drag([(140,100),(180,100)],cancelled=True),[.5,.5,1,0])
        self.assertEqual(self.drag([(100,140),(100,180)],cancelled=True),[.5,.5,2,0])

    def test_horizontal_divider_reverses_axes(self):
        self.assertEqual(self.drag([(100,140)],vertical=False),[.6,.5,1,0])
        self.assertEqual(self.drag([(140,100)],vertical=False),[.5,.7,2,0])

    def test_edge_clamps_and_invalid_geometry(self):
        self.assertEqual(self.drag([(100,1000)]),[.5,.9,2,0])
        self.assertEqual(self.drag([(100,-1000)]),[.5,.1,2,0])
        self.assertAlmostEqual(self.drag([(1000,100)])[0],2/3)
        self.assertAlmostEqual(self.drag([(-1000,100)])[0],1/3)
        self.assertEqual(self.drag([(100,140)],height=0),[.5,.5,0,0])

    def test_nonfinite_move_does_not_corrupt_position(self):
        self.assertEqual(self.drag([(100,120),(float('nan'),140),(100,140)]),[.5,.7,2,0])

if __name__ == '__main__':
    unittest.main()
