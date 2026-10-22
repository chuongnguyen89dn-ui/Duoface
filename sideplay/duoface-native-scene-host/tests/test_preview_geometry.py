"""Execute the production C geometry against manually decoded ARM64 vectors.
No UIKit, raster pixel comparison, or physical device test is claimed.
"""
import ctypes, pathlib, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Rect(ctypes.Structure):
    _fields_=[(n,ctypes.c_double) for n in ('x','y','w','h')]
class PreviewGeometry(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory()
        p=pathlib.Path(cls.tmp.name)
        (p/'probe.c').write_text('#include "DFNative12PreviewGeometry.h"\nint probe(int p,double w,double h,DFNative12PreviewRect *r){return DFNative12PreviewRects(p,w,h,r);}\n')
        subprocess.run(['cc','-std=c99','-shared','-fPIC','-I',str(ROOT),str(p/'probe.c'),'-lm','-o',str(p/'probe.so')],check=True)
        cls.lib=ctypes.CDLL(str(p/'probe.so'));cls.fn=cls.lib.probe
        cls.fn.argtypes=[ctypes.c_int,ctypes.c_double,ctypes.c_double,ctypes.POINTER(Rect)]
    @classmethod
    def tearDownClass(cls): cls.tmp.cleanup()
    def check_rects(self,p,w,h,expected):
        out=(Rect*4)();self.assertEqual(self.fn(p,w,h,out),len(expected))
        for actual,want in zip(out,expected):
            for field,value in zip(('x','y','w','h'),want):self.assertAlmostEqual(getattr(actual,field),value,places=10)
    def test_all_nine_original_cases_86x54(self):
        # Original case order 9f290,9f2fc,9f384,9f408,9f4f4,
        # 9f5c4,9f690,9f760,9fdd4. Half rounds through float.
        f=(5,5,76,44);l=(5,5,37,44);r=(43.8,5,37.2,44)
        t=(5,5,76,21);b=(5,27.8,76,21.2)
        tl=(5,5,37,21);tr=(43.8,5,37.2,21)
        bl=(5,27.8,37,21.2);br=(43.8,27.8,37.2,21.2)
        cases=[[f],[l,r],[t,b],[(5,5,24,44),(30.8,5,24,44),(56.6,5,24.4,44)],
               [l,tr,br],[tl,bl,r],[t,bl,br],[tl,tr,b],[tl,tr,bl,br]]
        for p,expected in enumerate(cases):
            with self.subTest(preset=p):self.check_rects(p,86,54,expected)
    def test_large_canvas_and_rounding(self):
        self.check_rects(8,120,54,[(6,6,53,20),(61.5,6,52.5,20),(6,28.5,53,19.5),(61.5,28.5,52.5,19.5)])
        self.check_rects(1,100,54,[(5,5,44,44),(50.8,5,44.2,44)])
        self.check_rects(1,101,54,[(6,6,43,42),(51.5,6,43.5,42)])
    def test_invalid_input(self):
        for p,w,h in [(-1,86,54),(9,86,54),(1,float('nan'),54),(1,9,54),(1,86,0)]:
            self.assertEqual(self.fn(p,w,h,(Rect*4)()),0)
if __name__=='__main__':unittest.main()
