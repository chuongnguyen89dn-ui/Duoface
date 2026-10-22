#!/usr/bin/env python3
"""Extract original Native12 App/Recent/Close UI callsites, SHA-verified only.
This is disassembly evidence; do not copy vendor runtime code or license.
"""
import pathlib, runpy
source=pathlib.Path(__file__).resolve().parents[2]/"audit/native12-layout-forensic-20261021/extract_layout_imp.py"
module=runpy.run_path(str(source))
module["main"].__globals__["METHODS"]=[
 ("CBMultitaskingOverlayView","setupAppPickerCardsInCardW:cardH:contentY:"),
 ("CBMultitaskingOverlayView","setupRecentAppsCardsInCardW:cardH:contentY:"),
 ("CBMultitaskingOverlayView","setupCardContent"),
 ("CBMultitaskingOverlayView","layoutSubviews"),
 ("CBMultitaskingOverlayView","pageControlChanged:"),
 ("CBMultitaskingOverlayView","appSelected:"),
 ("CBMultitaskingOverlayView","closeSingleAppTapped:"),
 ("CBMultitaskingOverlayView","closeAllBridgedAppsTapped:"),
 ("CBMultitaskingOverlayView","restartSingleAppTapped:"),
 ("CBMultitaskingOverlayView","showAppPickerForSlot:parentView:"),
 ("CBMultitaskingOverlayView","showRecentAppsInParentView:"),
 ("CBMultitaskingOverlayView","switchToAppPickerMode"),
 ("CBMultitaskingOverlayView","switchToRecentMode"),
 ("CBMultitaskingOverlayView","dismissOverlay"),
]
if __name__=="__main__":module["main"]()
