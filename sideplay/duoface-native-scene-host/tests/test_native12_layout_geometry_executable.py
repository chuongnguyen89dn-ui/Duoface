"""Execute the shipped independent DFLayoutEngine.m as portable C.
This checks actual frame arithmetic, not selector strings or demo rendering.
Original Native12 function/ABI and real device parity remain separate gates.
"""
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SHIM=r"""
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
typedef double CGFloat;
typedef long NSInteger;
typedef int BOOL;
#define YES 1
#define NO 0
typedef struct {CGFloat x,y;} CGPoint;
typedef struct {CGFloat width,height;} CGSize;
typedef struct {CGPoint origin;CGSize size;} CGRect;
static const CGRect CGRectNull={{INFINITY,INFINITY},{0,0}};
static CGRect CGRectMake(CGFloat x,CGFloat y,CGFloat w,CGFloat h) {
    return (CGRect){{x,y},{w,h}};
}
static BOOL CGRectIsNull(CGRect r) {return isinf(r.origin.x);}
static BOOL CGRectIsEmpty(CGRect r) {
    return CGRectIsNull(r)||r.size.width<=0||r.size.height<=0;
}
static CGFloat CGRectGetMinX(CGRect r) {return r.origin.x;}
static CGFloat CGRectGetMinY(CGRect r) {return r.origin.y;}
static CGFloat CGRectGetWidth(CGRect r) {return r.size.width;}
static CGFloat CGRectGetHeight(CGRect r) {return r.size.height;}
"""
HARNESS=r"""
static void check(int ok,const char *text) {
 if(!ok){fprintf(stderr,"REAL_LAYOUT_GEOMETRY_FAIL %s\n",text);exit(1);}
}
static double area(CGRect r){return CGRectIsNull(r)?0:r.size.width*r.size.height;}
static double overlap(CGRect a,CGRect b) {
 double left=fmax(a.origin.x,b.origin.x);
 double top=fmax(a.origin.y,b.origin.y);
 double right=fmin(a.origin.x+a.size.width,b.origin.x+b.size.width);
 double bottom=fmin(a.origin.y+a.size.height,b.origin.y+b.size.height);
 return fmax(0,right-left)*fmax(0,bottom-top);
}
int main(void) {
 const CGFloat ratios[]={1.0/3,0.4,0.5,0.6,2.0/3};
 const CGRect screens[]={
   {{0,0},{507.333333,240}}, {{64,0},{443.33333,240}},
   {{5,10},{1024,380}}
 };
 check(DFNative12DefaultPrimaryRatio(3)==1.0/3,"three columns 1/3 default");
 check(DFNative12DefaultSecondaryRatio(3)==0.5,"three columns remaining half");
 for(int screen=0;screen<3;screen++)for(int preset=0;preset<8;preset++)
 for(int r=0;r<5;r++)for(int s=0;s<5;s++) {
   CGRect bounds=screens[screen],frames[4];
   CGFloat p=ratios[r],secondary=ratios[s];
   DFComputePresetFramesWithSecondary(bounds,preset,p,secondary,frames);
   int count=(int)DFSlotCountForPreset(preset);
   check(count>=1&&count<=3,"only original 1/2/3 panes");
   double total=0;
   for(int i=0;i<4;i++) {
      if(i>=count){check(CGRectIsNull(frames[i]),"unused frame must be CGRectNull");continue;}
      CGRect f=frames[i];
      check(!CGRectIsEmpty(f),"nonempty frame");
      check(f.origin.x>=bounds.origin.x-0.001&&f.origin.y>=bounds.origin.y-0.001,
            "scene starts within usable CarPlay area");
      check(f.origin.x+f.size.width<=bounds.origin.x+bounds.size.width+0.001,
            "scene exceeds CarPlay width");
      check(f.origin.y+f.size.height<=bounds.origin.y+bounds.size.height+0.001,
            "scene exceeds CarPlay height");
      total+=area(f);
      for(int prev=0;prev<i;prev++)
        check(overlap(f,frames[prev])<1e-6,"two app panes overlap");
   }
   check(fabs(total-area(bounds))<0.001,"usable area has a gap or duplication");
   CGRect second=DFSecondaryDividerRect(bounds,preset,p,secondary);
   if(count<=2)check(CGRectIsNull(second),"solo/two panes cannot have second divider");
   else {
      check(!CGRectIsNull(second),"three panes must have second divider");
      if(DFSecondaryDividerIsVertical(preset))
         check(fabs(second.size.width)<1e-9&&second.size.height>0,"second vertical line wrong");
      else check(fabs(second.size.height)<1e-9&&second.size.width>0,"second horizontal line wrong");
   }
 }
 CGRect screen=CGRectMake(64,0,600,240),frames[4];
 DFComputePresetFramesWithSecondary(screen,3,
     DFNative12DefaultPrimaryRatio(3),DFNative12DefaultSecondaryRatio(3),frames);
 for(int i=0;i<3;i++)
   check(fabs(frames[i].size.width-200)<1e-9,
         "native12 three-column card must start with equal widths");
 CGRect separator=DFSecondaryDividerRect(screen,3,1.0/3,0.5);
 check(fabs(separator.origin.x-464)<1e-9,
       "second divider not aligned with third-column boundary");
 check(DFSlotCountForPreset(0)==1,"one-pane mode lost");
 printf("NATIVE12_REAL_C_LAYOUT_8_PRESETS_600_GEOMETRY_CASES_PASS\n");
 return 0;
}
"""

class Native12ExecutableLayout(unittest.TestCase):
 def test_compile_and_execute_actual_first_party_layout_math(self):
  compiler=shutil.which("cc") or shutil.which("clang")
  self.assertTrue(compiler,"C compiler needed to exercise actual DFLayoutEngine")
  actual=(ROOT/"DFLayoutEngine.m").read_text()
  self.assertIn('#import "DFLayoutEngine.h"',actual)
  self.assertIn("void DFComputePresetFramesWithSecondary",actual)
  # Only drop the Objective-C UIKit header; ship and execute all C math
  # function bodies unchanged against a minimal C typedef of CGRect.
  real_c=actual.replace('#import "DFLayoutEngine.h"','',1).replace(
               "#import <math.h>","#include <math.h>",1)
  with tempfile.TemporaryDirectory() as temp:
   source=Path(temp)/"native12_layout_test.c"
   output=Path(temp)/"native12_layout_test"
   source.write_text(SHIM+"\n"+real_c+"\n"+HARNESS)
   build=subprocess.run([compiler,"-std=c11","-Wall","-Wextra",
        str(source),"-lm","-o",str(output)],capture_output=True,text=True)
   self.assertEqual(build.returncode,0,build.stderr)
   run=subprocess.run([str(output)],capture_output=True,text=True)
   self.assertEqual(run.returncode,0,run.stdout+"\n"+run.stderr)
   self.assertIn("NATIVE12_REAL_C_LAYOUT_8_PRESETS_600_GEOMETRY_CASES_PASS",run.stdout)

if __name__=="__main__":
 unittest.main()
