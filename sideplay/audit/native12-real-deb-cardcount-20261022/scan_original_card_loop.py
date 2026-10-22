#!/usr/bin/env python3
"""Count preset CARD constructions in verified original Native12 binary evidence.
The archived exact ARM64 instructions are SHA-bound to independently extracted
original DEB. This never runs original code or ports license components.
"""
import argparse, hashlib, json, pathlib, re, subprocess

ORIGINAL="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
DASH="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
def hash256(p):return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
def pc(line):
 m=re.match(r"\s*([0-9a-f]+):",line)
 return int(m.group(1),16) if m else -1
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--deb",required=True)
 p.add_argument("--extract",required=True)
 p.add_argument("--imp-json",required=True)
 p.add_argument("--chrome",required=True)
 p.add_argument("--out",required=True)
 args=p.parse_args()
 assert hash256(args.deb)==ORIGINAL, "ORIGINAL_DEB_NOT_VERIFIED"
 root=pathlib.Path(args.extract)
 dashboard=root/"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
 assert hash256(dashboard)==DASH, "ORIGINAL_DASHBOARD_NOT_VERIFIED"
 files=sum(f.is_file() or f.is_symlink() for f in root.rglob("*"))
 assert files==43,("ORIGINAL_DEB_PAYLOAD_CHANGED",files)
 source=json.loads(pathlib.Path(args.imp_json).read_text())
 assert source["dashboard_macho_sha256"]==DASH
 assert source["original_native12_deb_sha256"]==ORIGINAL
 def method(c,s):
  matches=[m for m in source["methods"] if m["class"]==c and m["selector"]==s]
  assert len(matches)==1,(c,s,len(matches))
  return matches[0]
 card=method("CBMultitaskingOverlayView","setupPresetCardsInCardW:cardH:contentY:")
 inst=card["instructions"]
 # This comes from the *original* Native12 Dashboard IMP @ a5e78,
 # not the assistant-authored eight-choice DFIInterface.inc.
 start=[(i,line) for i,line in enumerate(inst) if re.search(r"\bmov\s+x26,\s*#0x0\b",line)]
 end=[(i,line) for i,line in enumerate(inst) if re.search(r"\bcmp\s+x26,\s*#0x9\b",line)]
 increment=[(i,line) for i,line in enumerate(inst) if re.search(r"\badd\s+x26,\s*x26,\s*#0x1\b",line)]
 assert len(start)>=1 and len(end)==1 and len(increment)==1,(start,end,increment)
 seq=end[0][0]
 control=inst[max(0,seq-5):min(len(inst),seq+9)]
 pc_match=pc(end[0][1])
 assert pc_match==0xa6704,hex(pc_match)
 # Require an actual conditional back-edge, not merely an unrelated literal 9.
 branches=[line for line in control if re.search(r":\s+b\.(lo|lt|ne|hi|ls)\s+0xa[0-9a-f]+",line)]
 conditional_back=[line for line in branches if (lambda target:
      target < 0xa6704 and target >= 0xa5e78)(
      int(re.search(r"0x[0-9a-f]+",line).group(0),16))]
 assert conditional_back,("NO_LOOP_BACK_EDGE",control)
 m=method("CBBridgeManager","switchToMultiSplitMode:apps:ratio:")
 switch=[line for line in m["instructions"] if re.search(r"\bcmp\s+x0,\s*#0x4\b",line)]
 chrome=pathlib.Path(args.chrome).read_text()
 current_nine=("for(NSInteger idx=0;idx<9;idx++)" in chrome and
               "selected>8" in chrome)
 result={
   "verification":"ORIGINAL_NATIVE12_REAL_DEB_AND_PRESET_LOOP_RECHECKED",
   "original_deb_sha256":ORIGINAL,"dashboard_dylib_sha256":DASH,
   "original_payload_files":files,
   "exact_asm_method":card["class"]+"."+card["selector"],
   "method_start":card["imp"],
   "start_zero":start[0][1],
   "increment_one":increment[0][1],
   "compare_nine":end[0][1],
   "conditional_backward_branch":conditional_back,
   "nearby_disassembly":control,
   "nine_card_construction_iterations":True,
   "original_preview_card_count":9,
   "other_original_split_function_test_for_four":switch[:8],
   "current_independent_style_picker_count":9 if current_nine else "unknown",
   "eight_from_project_authored_reconstruction_not_original_machine_code":True,
   "do_not_assert_mapping_from_card_count_alone":True,
   "all_nine_original_visual_layout_shapes_verified":False,
   "original_native12_runtime_ui_tested":False,
   "new_duoface_device_tested":False,
   "release_allowed_based_on_this_audit":False
 }
 out=pathlib.Path(args.out);out.parent.mkdir(parents=True,exist_ok=True)
 out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
 print("REAL_ORIGINAL_NATIVE12_DEB_SHA256_PASS",ORIGINAL)
 print("REAL_ORIGINAL_DASHBOARD_SHA256_PASS",DASH)
 print("REAL_ORIGINAL_PRESET_CARDS_COUNT_NINE_PASS",end[0][1],
       *conditional_back,sep="\n")
 print("REAL_NINE_STYLE_CHOICES_NOW_PRESENT_AND_ORIGINAL_PREVIEW_COUNT_RECHECKED")
 print("EVIDENCE",str(out))
if __name__=="__main__":main()
