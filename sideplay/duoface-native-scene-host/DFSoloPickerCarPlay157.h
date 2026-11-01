// First-party SOLO pill requests never bypass the native CarPlay Dock owner.
// Included by DFHomeStandalone144.m only under DF144_CARPLAY, after Dock147.
static void DF157HandleSoloPickerRequest(void) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:DF144PickerRequest];
 if(![p isKindOfClass:NSDictionary.class])return;
 NSNumber *stamp=p[@"Timestamp"];
 NSString *bundle=p[@"BundleID"];
 NSTimeInterval age=NSDate.date.timeIntervalSince1970-[stamp doubleValue];
 BOOL valid=[p[@"Version"] isEqual:@1] &&
    [p[@"RequestID"] isKindOfClass:NSString.class] &&
    [p[@"FromBundle"] isKindOfClass:NSString.class] &&
    [p[@"CarDisplayID"] isKindOfClass:NSString.class] &&
    [stamp isKindOfClass:NSNumber.class] &&
    isfinite(age) && age>=0 && age<=2 &&
    DF147Life.active && !DF147Life.pending &&
    [p[@"RequestID"] isEqual:DF147RequestID] &&
    [p[@"FromBundle"] isEqual:DF147Bundle] &&
    [p[@"CarDisplayID"] isEqual:DF147Session] &&
    DF144Allowed(bundle) && ![bundle isEqual:DF147Bundle] &&
    DF144LiveReceiver();
 if(!valid) {
    DF144Log(@"solo-picker-carplay-refused",@"stale-or-unowned");
    return;
 }
 id home=nil;
 id dock=DF147FindDock(DF147Session,&home);
 if(!DF147DockABI(dock)) {
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
