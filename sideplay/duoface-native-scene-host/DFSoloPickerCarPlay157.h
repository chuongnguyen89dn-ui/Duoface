// First-party SOLO pill requests never bypass the native CarPlay Dock owner.
// Included by DFHomeStandalone144.m only under DF144_CARPLAY, after Dock147.
static void DF157HandleSoloPickerRequest(void) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:DF144PickerRequest];
 if(![p isKindOfClass:NSDictionary.class])return;
 NSNumber *stamp=p[@"Timestamp"];
 NSString *bundle=p[@"BundleID"];
 NSTimeInterval age=NSDate.date.timeIntervalSince1970-[stamp doubleValue];
 NSDictionary *lease=[NSDictionary dictionaryWithContentsOfFile:DF144LeasePath];
 NSTimeInterval leaseAge=NSDate.date.timeIntervalSince1970-[lease[@"Timestamp"] doubleValue];
 BOOL liveDock=DF147Life.active && !DF147Life.pending &&
   [p[@"RequestID"] isEqual:DF147RequestID] &&
   [p[@"FromBundle"] isEqual:DF147Bundle] &&
   [p[@"CarDisplayID"] isEqual:DF147Session] &&
   ![bundle isEqual:DF147Bundle];
 // Home has reset the native Dock; the SpringBoard-owned chooser explicitly
 // renews its own lease while alive. Never treat an old plist as authority.
 BOOL liveChooser=!DF147Life.active &&
   [lease[@"Role"] isEqual:@"SpringBoard-Standalone144"] &&
   [lease[@"Alive"] isEqual:@YES] &&
   [lease[@"PickerVisible"] isEqual:@YES] &&
   [lease[@"PickerRequestID"] isEqual:p[@"RequestID"]] &&
   [lease[@"CarDisplayID"] isEqual:p[@"CarDisplayID"]] &&
   [lease[@"Timestamp"] isKindOfClass:NSNumber.class] &&
   isfinite(leaseAge) && leaseAge>=0 && leaseAge<=2;
 BOOL valid=[p[@"Version"] isEqual:@1] &&
    [p[@"RequestID"] isKindOfClass:NSString.class] &&
    [p[@"FromBundle"] isKindOfClass:NSString.class] &&
    [p[@"CarDisplayID"] isKindOfClass:NSString.class] &&
    [stamp isKindOfClass:NSNumber.class] &&
    isfinite(age) && age>=0 && age<=2 &&
    (liveDock || liveChooser) && DF144Allowed(bundle) &&
    DF144LiveReceiver();
 if(!valid) {
    DF144Log(@"solo-picker-carplay-refused",@"stale-or-unowned");
    return;
 }
 id home=nil;
 id dock=DF147FindDock(p[@"CarDisplayID"],&home);
 if(!DF147DockABI(dock) || (liveChooser &&
      [DF144Get(dock,"activeBundleIdentifier") isKindOfClass:NSString.class] &&
      ![@[@"com.apple.CarPlay.dashboard",@"com.apple.dashboard"] containsObject:
            DF144Get(dock,"activeBundleIdentifier")])) {
   DF144Log(@"solo-picker-carplay-refused",@"dock-abi-unavailable");
   return;
 }
 // Reuse existing native Dashboard workspace prep, single SpringBoard owner,
 // result ACK and Dock lifecycle; do NOT directly make an SB app active.
 BOOL ok=DF144BeginSelectedBridge(bundle,home?:dock,@"CarPlayDockStandalone144");
 DF144Log(ok?@"solo-picker-carplay-switch-requested":@"solo-picker-carplay-refused",bundle);
}
static void DF157RegisterSoloPickerReceiver(void) {
 static int token=-1;
 int rc=notify_register_dispatch(DF144PickerNotify,&token,
      dispatch_get_main_queue(),^(__unused int t){DF157HandleSoloPickerRequest();});
 DF144Log(rc==0?@"solo-picker-carplay-listener-ready":@"solo-picker-carplay-listener-failed",
          [NSString stringWithFormat:@"result=%d",rc]);
}
