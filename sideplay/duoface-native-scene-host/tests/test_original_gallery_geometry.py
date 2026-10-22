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
if __name__=="__main__":unittest.main()
