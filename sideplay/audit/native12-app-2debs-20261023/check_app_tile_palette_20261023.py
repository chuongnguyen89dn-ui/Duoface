#!/usr/bin/env python3
"""Static SHA-pinned original ARM64 + raw VM constant App tile-state verifier."""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser()
for opt in ("original-arm64","literal-values","independent-source","out"):
    p.add_argument("--"+opt,type=Path,required=True)
a=p.parse_args()
e=json.loads(a.original_arm64.read_text())
f=json.loads(a.literal_values.read_text())
src=a.independent_source.read_text()
SHA="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
assert e["dashboard_macho_sha256"]==f["dashboard_sha256"]==SHA
m=next(x for x in e["methods"] if x["selector"]=="setupAppPickerCardsInCardW:cardH:contentY:")
assert len(m["instructions"])>=1800
code=dict(x.split(":",1) for x in m["instructions"])
anchors={
 "a4b00":"Objc selector ref: clearColor","a4cfc":"mov\tx20, x27",
 "a4e68":"mov\tx1, x20","a4e80":"[sp, #0x1c8]",
 "a4e88":"bl\t0x2ecd00",
 "a4ff0":"cbz\tw23, 0xa5084",
 "a4ffc":"fmov\td0, #2.00000000",
 "a5084":"fmov\td0, xzr",
 "a50dc":"tbnz\tw8, #0x0, 0xa522c",
 "a5184":"tbz\tw23, #0x0, 0xa51ac",
 "a518c":"[x8, #0x7c0]","a5194":"[x8, #0xac8]",
 "a51b0":"[x8, #0xaf8]",
 "a49e8":"[sp, #0xe0]","a4a20":"[sp, #0x68]",
 "a5278":"[sp, #0xe0]","a53c4":"[sp, #0x68]",
 "a52e0":"checkmark.circle.fill","a542c":"arrow.left.arrow.right.circle.fill",
 "a5014":"[x8, #0x9a8]","a501c":"[sp, #0xd8]",
 "a4a0c":"[sp, #0xd8]",
 "a54fc":"fmov\ts0, #0.50000000",
 "a5528":"fmov\td0, #2.50000000",
 "a5550":"fmov\td0, xzr",
 "a5558":"mov.16b\tv1, v8",
 "a4a80":"cmp\tx8, #0x6",
 "a4a84":"fmov\td0, #18.00000000",
 "a4a88":"fmov\td1, #16.00000000",
 "a4a8c":"fcsel\td0, d1, d0, eq",
 "a4934":"fmax\td11, d0, d1","a4940":"fmul\td0, d11, d0",
}
for pc,expected in anchors.items():
    assert pc in code and expected in code[pc],(pc,code.get(pc),expected)
floats={v["address"]:v["value"] for method in f["methods"].values()
        for v in method["literal_floats"] if v["value"] is not None}
for addr,value in {"0x311720":.08,"0x311728":.52,
    "0x311700":.62,"0x3116c8":.04,"0x30f9a8":.15,
    "0x3117c0":.55,"0x30fac8":.8,"0x30faf8":.95,
    "0x3117a8":.225}.items():
    assert abs(floats[addr]-value)<.001,(addr,floats.get(addr))
assert "self.contentView.backgroundColor=[UIColor colorWithWhite:.19 alpha:.96]" in src
assert "CGFloat iconSide=MIN(43,MAX(24,h-(self.runningControls?68:29)))" in src
assert "card.title.text=app.displayName;" in src
result={
 "status":"ORIGINAL_ARM64_CALLSITE_AND_RAW_FLOAT_ASSERTIONS_PASS_STATIC_ONLY",
 "source_macho_sha256":SHA,
 "UIButton_card_background":"clearColor: a4b00→a4cfc→a4e68→a4e80→a4e88",
 "selected_icon_outline":{"width_pt":2,"rgba":[.15,.62,1,1]},
 "inactive_icon_outline_width_pt":0,
 "selected_name_rgba":[.55,.8,1,1],
 "unselected_name_white":.95,
 "selected_badge":{"symbol":"checkmark.circle.fill","rgba":[.08,.52,1,1],
                   "other_palette_color":"white"},
 "other_slot_badge":{"symbol":"arrow.left.arrow.right.circle.fill",
                     "rgba":[1,.62,.04,1],"other_palette_color":"white"},
 "badge_shadow":{"opacity":.5,"radius_pt":2.5,"offset":[0,1]},
 "badge_size_candidates":{"six_columns_pt":16,"other_pt":18},
 "icon_corner_radius_multiplier":.225,
 "label_hiding_branch":"a50dc",
 "independent_current_gray_tile":[.19,.19,.19,.96],
 "independent_current_icon_size_limits":[24,43],
 "visual_parity":"FAIL_ON_STATIC_PROVEN_DIFFERENCES",
 "device_checked":False,
 "caution":"Conditional state ownership is inferred from nearby ARM64 branches and selector/object dataflow, not a screenshot; preserve raw evidence."}
a.out.mkdir(parents=True,exist_ok=True)
(a.out/"APP_TILE_STATE_CROSSWALK.json").write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
print("ORIGINAL_APP_TILE_STATE_TRACE_PASS",json.dumps(result))
