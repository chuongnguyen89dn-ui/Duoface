"""Execute real independent C logo gate. Not a claim of CarPlay device parity."""
import ctypes
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class LogoHoldGate(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        here = pathlib.Path(cls.tmp.name)
        (here / "gate.c").write_text(r"""
#include "DFLogoHoldGate.h"
void run(int vertical, double *events, int count,
         int inside, int cancelled, int wake, double *out) {
    DFLogoHoldGate g=DFLogoHoldBegin(events[0],events[1],events[2]);
    for(int i=1;i<count;i++) {
        DFLogoHoldAdvance(&g,events[3*i],events[3*i+1],events[3*i+2],vertical);
    }
    double now=events[3*(count-1)];
    double x=events[3*(count-1)+1],y=events[3*(count-1)+2];
    out[0]=g.unlocked;out[1]=g.rejected;
    out[2]=DFLogoHoldIsQuickTap(&g,now,x,y,inside,cancelled,wake);
}
""")
        subprocess.run(
            ["cc", "-std=c99", "-Wall", "-Wextra", "-Werror",
             "-shared", "-fPIC", "-I", str(ROOT), str(here / "gate.c"),
             "-lm", "-o", str(here / "gate.so")], check=True)
        cls.lib = ctypes.CDLL(str(here / "gate.so"))
        cls.fn = cls.lib.run
        cls.fn.argtypes = [
            ctypes.c_int, ctypes.POINTER(ctypes.c_double), ctypes.c_int,
            ctypes.c_int, ctypes.c_int, ctypes.c_int,
            ctypes.POINTER(ctypes.c_double)]

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def check_gate(self, sequence, *, vertical=True, inside=True,
                   cancelled=False, wake=False):
        ev = (ctypes.c_double * (len(sequence) * 3))(
            *(v for item in sequence for v in item))
        out = (ctypes.c_double * 3)()
        self.fn(vertical, ev, len(sequence), inside, cancelled, wake, out)
        return tuple(bool(v) for v in out)

    def test_quick_clean_tap_swaps(self):
        self.assertEqual(self.check_gate([(10, 100, 100),
                                          (10.3, 102, 103)]),
                         (False, False, True))

    def test_hidden_first_tap_wakes_only(self):
        self.assertEqual(self.check_gate([(10, 100, 100),
                                          (10.2, 100, 100)], wake=True),
                         (False, False, False))

    def test_early_drag_cancels_even_if_held_later(self):
        self.assertEqual(self.check_gate([(10, 100, 100),
                                          (11, 100, 121),
                                          (13.5, 100, 145)]),
                         (False, True, False))

    def test_hold_three_seconds_then_vertical_move(self):
        self.assertEqual(self.check_gate([(10, 100, 100),
                                          (12.9, 101, 102),
                                          (13, 101, 120)]),
                         (True, False, False))

    def test_hold_three_seconds_then_horizontal_move(self):
        self.assertEqual(self.check_gate([(10, 100, 100),
                                          (13.3, 120, 101)], vertical=False),
                         (True, False, False))

    def test_sideways_after_hold_cannot_resize_divider(self):
        self.assertEqual(self.check_gate([(10, 100, 100),
                                          (13.3, 130, 100),
                                          (14, 100, 140)]),
                         (False, True, False))

    def test_stationary_long_press_does_not_swap(self):
        self.assertEqual(self.check_gate([(10, 100, 100),
                                          (14, 100, 100)]),
                         (False, False, False))

    def test_cancel_outside_never_swaps(self):
        short = [(10, 100, 100), (10.2, 100, 100)]
        self.assertEqual(self.check_gate(short, cancelled=True),
                         (False, False, False))
        self.assertEqual(self.check_gate(short, inside=False),
                         (False, False, False))

    def test_ambiguous_diagonal_does_not_lock(self):
        self.assertEqual(self.check_gate([(10, 100, 100),
                                          (13.4, 115, 115)]),
                         (False, False, False))

    def test_chrome_routes_raw_logo_touch_through_gate_not_ratio(self):
        s = (ROOT / "DFNative12Chrome.m").read_text()
        self.assertIn("DFLogoHoldAdvance(&self->_logoHoldGate", s)
        self.assertIn("self->_dividerDrag.axis=DFDragLogo", s)
        self.assertIn("DFLogoHoldIsQuickTap(&self->_logoHoldGate", s)
        self.assertIn("DFLogoHoldBegin(", s)


if __name__ == "__main__":
    unittest.main()
