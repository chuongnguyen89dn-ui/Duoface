# DuoFace full immutable DEB scan — Native12 vs QA7 and DuoNavi 1.0.4

Read-only archive and ObjC static metadata, not device parity or vendor code reuse.

| Package | Files | Directories | PNG | App icon PNG | UI PNG | Dylib | Plist | ObjC classes listed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| native12 | 43 | 21 | 25 | 18 | 7 | 6 | 7 | 492 |
| qa7 | 23 | 15 | 14 | 5 | 9 | 1 | 4 | 224 |
| original104 | 50 | 38 | 21 | 18 | 3 | 2 | 2 | 497 |

## Six core UI families from actual binary, not six total UI files
- **window**: CBWindow ({'CBWindow': 37} ObjC methods); QA owner DFINativeWindowSurface + DFIStart; full parity **NO**
- **split**: CBBridgedSplitApp ({'CBBridgedSplitApp': 49} ObjC methods); QA owner DFV12SplitController + DFIFramesMake; full parity **NO**
- **scene**: CBBridgedUIAppView ({'CBBridgedUIAppView': 29} ObjC methods); QA owner DFV12SceneHost; full parity **NO**
- **overlay_picker**: CBMultitaskingOverlayView ({'CBMultitaskingOverlayView': 66} ObjC methods); QA owner DFINativePickerCard/MenuBar/PickerCardsController; full parity **NO**
- **per_slot_pill**: CBSlotPillView ({'CBSlotPillView': 36} ObjC methods); QA owner DFINativeSlotPillView; full parity **NO**
- **divider**: CBDividerView ({'CBDividerView': 27} ObjC methods); QA owner DFINativeDividerTrack/Logo; full parity **NO**

## Native12 images present in DEB (pixel sizes, asset color swatches)

| Asset name | PNG pixels | Kind | dominant PNG RGB bin |
| --- | --- | --- | --- |
| AppIcon29x29.png | 29×29 | app_icon | [0, 0, 0] |
| AppIcon29x29@2x.png | 58×58 | app_icon | [0, 0, 0] |
| AppIcon29x29@3x.png | 87×87 | app_icon | [0, 0, 0] |
| AppIcon40x40.png | 40×40 | app_icon | [0, 0, 0] |
| AppIcon40x40@2x.png | 80×80 | app_icon | [0, 0, 0] |
| AppIcon40x40@3x.png | 120×120 | app_icon | [0, 0, 0] |
| AppIcon50x50.png | 50×50 | app_icon | [0, 0, 0] |
| AppIcon50x50@2x.png | 100×100 | app_icon | [0, 0, 0] |
| AppIcon57x57.png | 57×57 | app_icon | [0, 0, 0] |
| AppIcon57x57@2x.png | 114×114 | app_icon | [0, 0, 0] |
| AppIcon57x57@3x.png | 171×171 | app_icon | [0, 0, 0] |
| AppIcon60x60.png | 60×60 | app_icon | [0, 0, 0] |
| AppIcon60x60@2x.png | 120×120 | app_icon | [0, 0, 0] |
| AppIcon60x60@3x.png | 180×180 | app_icon | [0, 0, 0] |
| AppIcon72x72.png | 72×72 | app_icon | [0, 0, 0] |
| AppIcon72x72@2x.png | 144×144 | app_icon | [0, 0, 0] |
| AppIcon76x76.png | 76×76 | app_icon | [0, 0, 0] |
| AppIcon76x76@2x.png | 152×152 | app_icon | [0, 0, 0] |
| duoface-fullscreen.png | 88×88 | ui_asset | [0, 0, 0] |
| duoface-picker.png | 256×70 | ui_asset | [0, 0, 0] |
| duoface-swap.png | 120×120 | ui_asset | [0, 0, 0] |
| duoface-icon.png | 256×256 | ui_asset | [0, 0, 0] |
| duoface-logo-picker-alpha-v2.png | 627×228 | ui_asset | [0, 0, 0] |
| duoface-logo-vert.png | 640×640 | ui_asset | [0, 0, 0] |
| duoface-logo.png | 960×240 | ui_asset | [0, 0, 0] |

## Differences vs QA7
- Native image names absent QA7: ['AppIcon29x29.png', 'AppIcon29x29@2x.png', 'AppIcon29x29@3x.png', 'AppIcon40x40.png', 'AppIcon40x40@2x.png', 'AppIcon40x40@3x.png', 'AppIcon50x50.png', 'AppIcon50x50@2x.png', 'AppIcon57x57.png', 'AppIcon57x57@2x.png', 'AppIcon57x57@3x.png', 'AppIcon60x60.png', 'AppIcon72x72.png', 'AppIcon72x72@2x.png', 'AppIcon76x76.png', 'AppIcon76x76@2x.png']
- QA7-only image names: ['Icon.png', 'Icon@2x.png', 'Icon@3x.png', 'duoface-logo-picker-alpha.png', 'duoface-logo-picker-grabcut-preview.png']
- Common names with different image SHA: ['AppIcon60x60@2x.png', 'AppIcon60x60@3x.png']

## Why current QA7 is NOT restored DuoFace Native12
- QA relies on its custom DFV12SplitController/native analogs; merely including PNG or matching 38/44/64/72/76/80pt pills cannot reproduce Native12 input behavior.
- The image color bins above cannot establish compiled UIColor, gradient, blur, window/safe-area, dynamic states, or true physical screen geometry.
- QA-only alpha floating controls must be deleted, not hidden; bridge/scene playback may be kept if device verified; no original/vendor/licensed runtime linked.
- Continue by mapping every Native12 UI class/method into an independent owner, testing layout/interaction at real head-unit resolution.

## Full inventories
- Complete file names, byte sizes and SHA256, all PNG dimensions/bboxes/colors, all ObjC class names and per-class selectors (as objdump can expose) are in `audit/native12-complete-deb-inventory/INVENTORY.json`.
