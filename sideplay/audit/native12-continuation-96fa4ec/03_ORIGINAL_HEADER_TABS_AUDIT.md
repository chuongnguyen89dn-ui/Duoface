# Native12 Inner Header — immutable original audit
2026-10-22. Original SHA256 DEB 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad; Dashboard SHA256 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea.
Source: 02_ORIGINAL_SETUP_CARD_CONTENT.txt, 1281 instructions, original setupCardContent @0xa2a58.
Original a2c24 chooses headerHeight=32 for cardH<260 else38. Icon x14,y=(headerHeight-18)/2,size18; system symbols mode0 square.grid.2x2.fill, mode1 rectangle.split.2x1.fill, mode2 app.badge.fill @a2d28..a2d58.
Title UILabel x36,centered h20, minimum width80 @a2e04..a2e28. X button is image xmark, action dismissOverlay, short 24x24 at W-32,y4, tall 26x26 at W-34,y6 @a2fcc..a3210.
Original mode tabs are THREE (a33e0..a33f8 formula floor((tabZoneWidth-4)/3)), TAB_APPS / TAB_LAYOUT / TAB_RECENT with selectors switchToAppPickerMode / switchToLayoutChooserMode / switchToRecentMode @a34e8, a3800, a3af0. This inner three-tab switcher is DIFFERENT from outer four actions App/Zoom/Style/Close; do not conflate. Distinct mode titles not fabricated.
Original separator at y=headerHeight with height .5, contentY=headerHeight+.5 passed to app/Style/recent @a3d40..a3dec. Independent Style gallery y46 is wrong by 13.5/7.5 pt.
Width literals d15 @VM0x311830/0x311838 and threshold @0x311770 NOT decoded yet. This checkpoint saves exact call-chain and adds SHA-pinned decoder before UI changes. No invented width, no code/device success claim.
Next: decode original header literals via GitHub Actions, read output, then implement original inner modal header atomically and run regression and actual iOS16 clang source-only workflow. Preserve single final DEB policy.

## Original SHA-decoded numeric proof (CI #39773723186)
- GitHub Actions 39773723186, job 119807330659 completed SUCCESS. Exact original DEB SHA and Dashboard Mach-O SHA checked before decoding, output saved in `CARD_HEADER_LITERALS.json` (blob `6e542e99ae2513523ae37f973155e0ae59f4d449`).
- VM0x311768=260 height threshold; VM0x311770=440 **width threshold**, modes: width<440 => VM0x311838 **tab zone190**, otherwise VM0x311830 **tab zone210**; VM0x311758 fallback card width680; VM0x311760 fallback card height380.
- Original title width `max(cardW-tabZone-74,80)` from a2dd4..a2df8; title x36, y=(headerHeight-20)/2, h20. Original icon 18x18 at x14,y=(headerHeight-18)/2. Original tab container initWithFrame at a3238..a3248: `(cardW-36-tabZone, short?4:5, tabZone, short?24:28)`; three child tabs frame based on `w=floorf((tabZone-4)/3)`: first `(1,1,w,H-2)`; second `(1+w,1,w,H-2)`; third `(1+2*w,1,tabZone-2*w-3,H-2)`. Original X is separate at far right, outside tab container.
- Original separator uses UIColor white alpha.12 (VM0x310cd0) at y=headerH, 0.5 tall. Original tab selected-color constants include R=.08 (VM0x311720), G=.52 (VM0x311728), B=1, alpha=1. Exact three-mode UI no invented fourth tab.
- Implement original **inner** card geometry in Style modal next; do not delete outer four App/Zoom/Style/Close user controls. This is static byte parity only, device not verified.
