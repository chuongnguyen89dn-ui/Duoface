#!/usr/bin/env python3
"""Extract the actual ORIGINAL Native12 nine-card image-rendering helper.
This uses the real SHA-pinned extracted original Dashboard binary and preserves
entire ARM64 helper disassembly + nearby instructions; no guessed shapes.
"""
import argparse, hashlib, json, pathlib, re, subprocess
ORIGINAL="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
IMP_START=0x9efe0
# static function immediately preceding CBOverlayScrollView.initWithFrame: @ 0x9ff68
IMP_END=0x9ff68
INSTR=re.compile(r"^\s*([0-9a-fA-F]+):\s+(\w[\w.]*)\s*(.*)$")
def main():
 a=argparse.ArgumentParser()
 a.add_argument("--dashboard",required=True,type=pathlib.Path)
 a.add_argument("--out",required=True,type=pathlib.Path)
 v=a.parse_args()
 assert hashlib.sha256(v.dashboard.read_bytes()).hexdigest()==ORIGINAL,"not real original Dashboard"
 p=subprocess.run(["llvm-objdump","--macho","--disassemble","--no-show-raw-insn",str(v.dashboard)],
                  text=True,capture_output=True,encoding="utf8",errors="replace")
 assert p.returncode==0,p.stderr[-3000:]
 found=[]
 for line in p.stdout.splitlines():
  m=INSTR.match(line)
  if m:
   pc=int(m.group(1),16)
   if IMP_START<=pc<IMP_END:found.append(line.strip())
 assert len(found)>100,("short helper disassembly",len(found))
 assert int(INSTR.match(found[0]).group(1),16)==IMP_START,found[0]
 target=[x for x in found if re.search(r":\s+(?:cmp|subs|cbz|cbnz|b\.|adrp|ldr|fmov|fdiv|fmul|fadd)",x)]
 payload={
 "source":"REAL_ORIGINAL_NATIVE12_Dashboard_MachO_ARM64_RENDERER",
 "original_dashboard_sha256":ORIGINAL,
 "preview_image_callsite":"CBMultitaskingOverlayView.setupPresetCardsInCardW:cardH:contentY: 0xa6484 bl 0x9efe0",
 "renderer_function_entry":"0x9efe0",
 "renderer_boundary_before_CBOverlayScrollView":"0x9ff68",
 "instruction_count":len(found),
 "function_is_static_not_objc_selector":True,
 "actual_control_flow_decoded":False,
 "all_nine_card_visual_shapes_verified":False,
 "instructions":found,
 "control_flow_samples":target,
 }
 v.out.mkdir(parents=True,exist_ok=True)
 (v.out/"ORIGINAL_PRESET_IMAGE_RENDERER_ARM64.json").write_text(json.dumps(payload,indent=2)+"\n")
 (v.out/"ORIGINAL_PRESET_IMAGE_RENDERER_ARM64.txt").write_text("\n".join(found)+"\n")
 print("ORIGINAL_NINE_CARD_PREVIEW_RENDERER_EXTRACTED",len(found))
 print("CALLSITE 0xa6484 bl 0x9efe0")
 print("BRANCHES",*[x for x in found if "cmp" in x or "cbz" in x or "cbnz" in x][:40],sep="\n")
if __name__=="__main__":main()
