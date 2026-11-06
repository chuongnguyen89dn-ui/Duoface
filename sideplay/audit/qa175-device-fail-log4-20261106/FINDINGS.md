# QA175 device failure - latest Log4 only - 2026-11-06

Scope: ONLY newest upload commit 2066903f4b04eaa93ddd74085810558fe52ed066, files sideplay/log/DuoFaceAudit 4.txt plus the three * 4.ips reports. No older log files used for diagnosis.

Runtime is confirmed 0.0.175~wakepick1 in current traces.

1. Hidden-logo wake still fails in the new gate path.
- Current log contains zero qa180-wake-contact records.
- The old app-side relay still emits qa177-recall source=app-touch for Google Maps/Waze, but QA180 DFOwnedWakeSurface180 never owns a delivered hidden contact.
- Therefore the shipped DFOwnedWakeSurface180 placement/predicate is not on the real touch-dispatch path for the hosted pane in this device configuration. Do not keep tuning the 4-second timer. Next repair must instrument/attach at the actual SpringBoard-owned host surface that receives pane contact, with first hidden contact consumed through Ended/Cancelled and visible contacts passed unchanged.
- Direct logo raw-began/raw-ended events continue to exist, matching user report that only touching the logo itself recalls it.

2. Native map replacement now reaches picker/coordinator, but coordinator rejects every sampled replacement.
- QA180 card-entry and map-replace-prepared are present.
- Real qa178-native-map-picker-request exists for Waze and Google Maps.
- Every completed replacement shown in current run finishes applied=0 restore=1 current=1 reason=native-launch-owned-base-view-unverified.
- Summary: Native Map ACK applied=NO attached=NO reason=native-launch-owned-base-view-unverified owner=CarPlay.
- Source fd7e428c... shows this reason comes from DFNativeMapLaunchRuntime DFLaunchPresentationReady when currentBaseViewController is the exact DuoFace base but DFLaunchViewVisibleWithinRoot(base.viewIfLoaded, rootView, window) returns false. Thus the failure is now AFTER picker dispatch and before launch event submission. The visible blink is explained by QA180 withdrawing the old phone host then restoring it on rejected ACK.
- Next source change must correct/observe the actual CarPlay Dashboard ownership/view hierarchy contract; do not remove all ownership validation blindly and do not rework picker again.

3. CarPlay Home icons remain unimplemented at the actual icon-grid stage.
- Current PID2811 logs selected-LS-inclusion for GOFA, Google Maps, Wyn, YouTube, TikTok, Facebook, Waze.
- Four bridge records are attached and original-DashBoard-factory returns FBSApplicationLibrary newRecords=4; the log itself says not-icon-proof.
- selected-original-policy for bridge apps reports launch=0 capable=1 display=1 phone=1; icon-and-tap-unverified.
- Repeated ABI observation shows -[DBDashboardHomeViewController iconManager:launchIcon:] is absent while iconManager:launchIconForIconView: exists.
- User confirms zero new Home icons. Therefore library declaration/LS inclusion is not enough. Home publication must be implemented separately through the real Dashboard icon model/data source/update path learned from DuoNavi/OmniCar traces, not by adding more synthetic declarations alone.

4. Three IPS files are disk-writes resource reports from Nov 2/4, not new QA175 crashes. Do not use them as crash evidence.

Decision: QA175 fails physical acceptance on all three requested behaviors. No further old-log request. Next coding priorities: A) actual pane touch owner for hidden first-contact wake; B) fix native launch visibility/ownership reconciliation at DFNativeMapLaunchRuntime; C) separate real Home icon publication path. Preserve GOFA, keyboard/media/divider and lifecycle unless new evidence requires changes.
