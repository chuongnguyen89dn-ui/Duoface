import json, pathlib, shutil, subprocess, tempfile, unittest
R=pathlib.Path(__file__).resolve().parents[1]
class OriginalGalleryGeometry(unittest.TestCase):
    def test_executed_gallery_against_original_binary_values(self):
        evidence=json.loads((R.parent/"audit/native12-continuation-4888299/constants-v2/GALLERY_CONSTANTS.json").read_text())
        c=evidence["constants"]
        compiler=shutil.which("cc")
        self.assertIsNotNone(compiler, "C compiler required for executed gallery geometry")
        with tempfile.TemporaryDirectory() as tmp:
            p=pathlib.Path(tmp)
            (p/"test.c").write_text('#include <stdio.h>\n#include "DFNative12GalleryGeometry.h"\nint main(void){double w[]={320,450.3333333,470,559.999,560,600,960};for(int i=0;i<7;i++){DFNative12GalleryMetrics m=DFNative12Gallery(w[i]);printf("%.9f %d %.9f %.9f %.9f %.9f %.9f\\n",w[i],m.columns,m.cardWidth,m.cardHeight,m.rowStride,m.contentHeight,m.previewWidth);}return 0;}\n')
            subprocess.run([compiler,"-std=c99","-Wall","-Werror","-I",str(R),str(p/"test.c"),"-lm","-o",str(p/"test")],check=True)
            rows=subprocess.check_output([str(p/"test")],text=True).splitlines()
        self.assertEqual(len(rows),7)
        for row in rows:
            width,cols,cw,ch,stride,height,pw=map(float,row.split())
            self.assertEqual(cols,6 if width>=c["gallery_six_column_threshold"]["double"] else 5)
            self.assertEqual(ch,c["gallery_card_height"]["double"])
            self.assertEqual(stride,c["gallery_row_stride"]["double"])
            self.assertEqual(height,c["gallery_content_height"]["double"])
            self.assertAlmostEqual(cols*cw+(cols-1)*10+28,width,places=6)
            self.assertGreater(pw,0)
            self.assertLess(pw,cw)
            for tag in range(9):
                x=14+(tag%int(cols))*(cw+10)
                y=22+(tag//int(cols))*stride
                self.assertLessEqual(x+cw,width-14+1e-6)
                self.assertLessEqual(y+ch,height)
    def test_cards_keep_real_selection_and_accessibility(self):
        chrome=(R/"DFNative12Chrome.m").read_text()
        section=chrome.split("DFNative12GalleryMetrics metrics=")[1].split("self.styleChoices=choices;")[0]
        self.assertNotIn("UILabel",section)
        self.assertIn("action:@selector(selectStylePreset:)",section)
        self.assertIn("button.accessibilityLabel=styleNames",section)
        self.assertIn('checkmark.circle.fill',section)
        self.assertIn("self.styleSelectionBadges[(NSUInteger)choice.tag].hidden=!selected",chrome)

    def test_original_outer_style_layout_executable_and_source_wired(self):
        evidence=json.loads((R.parent/"audit/native12-continuation-4888299/outer-constants/ORIGINAL_OUTER_LAYOUT_CONSTANTS.json").read_text())
        self.assertEqual(evidence["original_macho_sha256"],"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea")
        c={k:v["double"] for k,v in evidence["literals"].items()}
        self.assertEqual(c["outer_width_breakpoint"],500)
        self.assertEqual(c["outer_height_breakpoint"],300)
        compiler=shutil.which("cc")
        self.assertIsNotNone(compiler)
        with tempfile.TemporaryDirectory() as tmp:
            p=pathlib.Path(tmp)
            (p/"test_outer.c").write_text(
                '#include <stdio.h>\\n#include "DFNative12OuterGeometry.h"\\n'
                'int main(void){double wh[][2]={{320,240},{507.3333333,240},{480,320},{960,540},{800,299},{500,300},{499.99,299.99}};'
                'for(int i=0;i<7;i++){DFNative12OuterSheetRect s=DFNative12OuterGeometry(wh[i][0],wh[i][1]);'
                'printf("%.9f %.9f %.9f %.9f %.9f %.9f\\\\n",wh[i][0],wh[i][1],s.width,s.height,s.x,s.y);}return 0;}')
            subprocess.run([compiler,"-std=c99","-Wall","-Werror","-I",str(R),str(p/"test_outer.c"),"-lm","-o",str(p/"outer")],check=True)
            rows=subprocess.check_output([str(p/"outer")],text=True).splitlines()
        self.assertEqual(len(rows),7)
        for row in rows:
            w,h,rw,rh,rx,ry=map(float,row.split())
            expected_w=min(w-(10 if w<c["outer_width_breakpoint"] else 24),c["outer_max_card_width"])
            expected_h=min(h-(8 if h<c["outer_height_breakpoint"] else 18),c["outer_max_card_height"])
            self.assertAlmostEqual(rw,expected_w,places=5)
            self.assertAlmostEqual(rh,expected_h,places=5)
            self.assertAlmostEqual(rx,round((w-expected_w)/2),places=4)
            self.assertAlmostEqual(ry,round((h-expected_h)/2),places=4)
        chrome=(R/"DFNative12Chrome.m").read_text()
        self.assertIn("DFNative12OuterGeometry(cr.size.width,cr.size.height)",chrome)
        self.assertNotIn("CGFloat styleW=MIN(cr.size.width-12,470)",chrome)
if __name__=="__main__":unittest.main()
