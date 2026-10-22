# Item 1 — Style card container / selected badge

2026-10-22. Base remote 96fa4ec6e0b20685921aa654639337ba51746b4b, branch feature/duoface-jb-embedded-appbridge-20261020.
User instruction: process one item at a time and persist each finding to GitHub immediately, before continuing; do not wait for end of session or credits.

Read complete 581 instructions of original setupPresetCardsInCardW:cardH:contentY: (0xa5e78) in sideplay/audit/native12-continuation-4888299/ORIGINAL_GALLERY_AND_CALLBACK.json. Compared current DFNative12GalleryGeometry.h, DFNative12Chrome.m setup/layoutControls. Original Dashboard SHA256 rechecked: 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea.

CONFIRMED matching source properties: 5/6 columns threshold560, margin14, gap10, height66, row stride78, top22, content height194; card radius12/continuous/clipping; image height54,y6, rounded centering; selected background(.04,.2,.45,.95), border(.12,.58,1,1)/width2; unselected background(.14,.15,.19,.95), white alpha.18 border/width1; checkmark.circle.fill palette white + (.08,.52,1,1), badge17x17 at cardWidth-21,y4.

CONFIRMED missing property: original badge.layer.shadowOpacity is float .45. ARM64 a6174 loads s0 from VM0x310ce0, saved at sp+0x3c; a6668 loads selector at sp+0x28 (setShadowOpacity:), a666c reloads s0, a6670 dispatches. Original black shadowColor and radius3 are already set in independent code but shadowOpacity is absent, leaving CALayer default0. Decoder of original SHA-verified file gives .44999998807907104. This is a narrow concrete visual mismatch, not a new UI idea.

Implementation pending at first finding checkpoint: set only badge.layer.shadowOpacity=.45f beside existing shadowColor/radius. Further original gallery contentY/header geometry remains separate; do not mark full Style/device parity complete.

IMPLEMENTED after analysis commit e2d1efc: added original shadowOpacity=.45f in DFNative12Chrome.m. No other card behavior changed. Existing source-contract suite run: 45 tests PASS. Source-only remote iOS syntax CI pending; no hardware visual check.
