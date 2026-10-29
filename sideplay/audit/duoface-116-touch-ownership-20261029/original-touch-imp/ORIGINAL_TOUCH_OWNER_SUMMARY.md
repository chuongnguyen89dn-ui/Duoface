# Original Native12 touch owner and pane hitTest forensic evidence

- Read-only original machine code extraction, not a running or tested DuoFace fix.
- Original DEB SHA256: `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`
- Dashboard Mach-O SHA256: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`
- Original instruction ranges verified for 14 methods. The raw report is ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json.
- IMPORTANT: ObjC method presence and disassembly alone do NOT prove runtime touch forwarding.
- Next: decode hitTest/point-inside and CloneTouch caller ordering, compare independent DFSceneHost app view bounds/remote touch routing to actual car trace. No invented overlay or synthetic touch injection.

- `CBTouchCloneView.sendTouchEventAtPoint:isDown:` `0x82d4c..0x82ff8` instructions=171
- `CBTouchCloneView.touchesBegan:withEvent:` `0x82ff8..0x83058` instructions=24
- `CBTouchCloneView.touchesMoved:withEvent:` `0x83058..0x830b8` instructions=24
- `CBTouchCloneView.touchesEnded:withEvent:` `0x830b8..0x83118` instructions=24
- `CBTouchCloneView.touchesCancelled:withEvent:` `0x83118..0x83178` instructions=24
- `CBBridgedUIAppView.hitTest:withEvent:` `0xac940..0xaca6c` instructions=75
- `CBBridgedUIAppView.touchesBegan:withEvent:` `0xaca6c..0xacc28` instructions=111
- `CBBridgedUIAppView.setAppScale:` `0xac83c..0xac858` instructions=7
- `CBBridgedUIAppView.updateLayout` `0xacc6c..0xad24c` instructions=376
- `CBBridgedUIAppView.refreshSceneLayout` `0xade58..0xadf30` instructions=54
- `CBUIAppContainerView.hitTest:withEvent:` `0xb97cc..0xb9888` instructions=47
- `CBUIAppContainerView.touchesBegan:withEvent:` `0xb9888..0xb98f8` instructions=28
- `CBUIAppContainerView.layoutSubviews` `0xb9730..0xb97cc` instructions=39
- `CBWindow.resizeWindows` `0xb1aac..0xb1d98` instructions=187
