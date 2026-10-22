# Native12 Inner Header — immutable original audit
2026-10-22. Original SHA256 DEB 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad; Dashboard SHA256 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea.
Source: 02_ORIGINAL_SETUP_CARD_CONTENT.txt, 1281 instructions, original setupCardContent @0xa2a58.
Original a2c24 chooses headerHeight=32 for cardH<260 else38. Icon x14,y=(headerHeight-18)/2,size18; system symbols mode0 square.grid.2x2.fill, mode1 rectangle.split.2x1.fill, mode2 app.badge.fill @a2d28..a2d58.
Title UILabel x36,centered h20, minimum width80 @a2e04..a2e28. X button is image xmark, action dismissOverlay, short 24x24 at W-32,y4, tall 26x26 at W-34,y6 @a2fcc..a3210.
Original mode tabs are THREE (a33e0..a33f8 formula floor((tabZoneWidth-4)/3)), TAB_APPS / TAB_LAYOUT / TAB_RECENT with selectors switchToAppPickerMode / switchToLayoutChooserMode / switchToRecentMode @a34e8, a3800, a3af0. This inner three-tab switcher is DIFFERENT from outer four actions App/Zoom/Style/Close; do not conflate. Distinct mode titles not fabricated.
Original separator at y=headerHeight with height .5, contentY=headerHeight+.5 passed to app/Style/recent @a3d40..a3dec. Independent Style gallery y46 is wrong by 13.5/7.5 pt.
Width literals d15 @VM0x311830/0x311838 and threshold @0x311770 NOT decoded yet. This checkpoint saves exact call-chain and adds SHA-pinned decoder before UI changes. No invented width, no code/device success claim.
Next: decode original header literals via GitHub Actions, read output, then implement original inner modal header atomically and run regression and actual iOS16 clang source-only workflow. Preserve single final DEB policy.
