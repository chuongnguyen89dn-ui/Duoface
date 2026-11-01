// First-party menu for an existing single SpringBoard-owned DF144Solo scene.
// Included INSIDE @implementation DF144Solo; no extra SBAppViewController.
// The native Home callback still runs. Only our manager-owned SOLO surface
// is retired, and its own first-party chooser becomes the visible destination.
// Native CarPlay Music/Calendar never pass this SpringBoard live-owner gate.
- (BOOL)df157ReturnHomeToPicker {
 // The outgoing scene may already be invalid when SpringBoard receives
 // the genuine CarPlay Home event. Guard the owned window/display instead.
 if(self.homeChooser || !self.window || self.window.hidden ||
    !self.emittedManager || !self.surface || !self.soloPicker || !self.root ||
    !self.request.length || !self.carDisplayID.length || !DFHome145Enabled() ||
    self.window.rootViewController!=self.root ||
    !self.window.screen || self.window.screen==UIScreen.mainScreen ||
    ![self currentCarDisplayWithID:self.carDisplayID])return NO;
 BOOL outgoingSceneLive=[[DFSceneHost sharedHost]
     isLiveSceneForHostedView:self.surface];
 DF144Log(@"solo-native-home-chooser-owner",
     [NSString stringWithFormat:@"req=%@ bid=%@ outgoingSceneLive=%d",
       self.request,self.bundle,outgoingSceneLive]);
 [self publishGeneralAppState:NO];
 ++self.generation;
 UIView *previous=self.surface;
 self.surface=nil;
 [previous removeFromSuperview];
 [[DFSceneHost sharedHost] releaseHostedView:previous];
 self.emittedHosted=NO;self.emittedManager=NO;
 self.homeChooser=YES;
 self.soloPill.hidden=YES;
 self.soloPicker.currentSlotBundleID=nil;
 self.soloPicker.pendingSlotBundleID=nil;
 self.soloPicker.otherSlotBundleIDs=@[];
 [self.soloPicker presentInstalledApps];
 [self.soloPicker refreshInstalledApps];
 self.soloPicker.view.hidden=NO;
 [self.root.view bringSubviewToFront:self.soloPicker.view];
 NSDictionary *lease=@{@"Version":@1,@"Role":@"SpringBoard-Standalone144",
     @"Alive":@YES,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
     @"PickerVisible":@YES,@"PickerRequestID":self.request?:@"",
     @"CarDisplayID":self.carDisplayID?:@""};
 BOOL wrote=[lease writeToFile:DF144LeasePath atomically:YES];
 DF144Log(@"solo-home-return-to-first-party-picker",
     [NSString stringWithFormat:@"req=%@ lease=%d",self.request,wrote]);
 [self reply:@"stopped" reason:@"native-Home-exit"];
 return YES;
}
- (void)appPickerDidCancel:(DFAppPickerVC *)picker {
 if(picker!=self.soloPicker)return;
 if(self.homeChooser) {
    DF144Log(@"solo-home-chooser-cancel",@"return-to-native-CarPlay");
    [self stop:@"solo-home-chooser-cancel"];
    return;
 }
 picker.view.hidden=YES;self.soloPill.hidden=NO;
 DF144Log(@"solo-own-pill-app-picker-closed",self.bundle);
}
- (void)appPicker:(DFAppPickerVC *)picker
 didSelectBundleID:(NSString *)bundle displayName:(NSString *)name {
 (void)name;
 // Only a real native Home-return chooser can select another app.
 if(picker!=self.soloPicker || !self.homeChooser ||
    !self.request.length || !self.carDisplayID.length ||
    !self.window || self.window.hidden || !DF144Allowed(bundle))return;
 NSDictionary *p=@{@"Version":@1,@"SelectionID":NSUUID.UUID.UUIDString,@"RequestID":self.request,
    @"FromBundle":self.bundle,@"BundleID":bundle,
    @"CarDisplayID":self.carDisplayID,
    @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
 if([p writeToFile:DF144PickerRequest atomically:YES]) {
   int rc=notify_post(DF144PickerNotify);
   DF144Log(@"solo-picker-switch-notified",[NSString stringWithFormat:
        @"from=%@ to=%@ rc=%d",self.bundle,bundle,rc]);
 } else DF144Log(@"solo-picker-switch-refused",@"write-failed");
}
// Other shared picker modes are not exposed as a second split/zoom owner.
// Fail safe to the real installed-app list, never alter global split presets.
- (void)appPickerDidRequestLayout:(DFAppPickerVC *)picker {
 if(picker==self.soloPicker)[picker presentInstalledApps];
}
- (void)appPickerDidRequestRunningApps:(DFAppPickerVC *)picker {
 if(picker==self.soloPicker)[picker presentInstalledApps];
}
- (void)appPickerDidRequestZoom:(DFAppPickerVC *)picker {
 if(picker==self.soloPicker)[picker presentInstalledApps];
}
- (void)appPicker:(DFAppPickerVC *)picker closeRunningBundleID:(NSString *)bundle {
 (void)bundle;if(picker==self.soloPicker)[picker presentInstalledApps];
}
- (void)appPicker:(DFAppPickerVC *)picker restartRunningBundleID:(NSString *)bundle {
 (void)bundle;if(picker==self.soloPicker)[picker presentInstalledApps];
}
- (void)appPickerCloseAllRunning:(DFAppPickerVC *)picker {
 if(picker==self.soloPicker)[picker presentInstalledApps];
}
- (void)appPicker:(DFAppPickerVC *)picker rotateRunningClockwise:(BOOL)clockwise {
 (void)clockwise;if(picker==self.soloPicker)[picker presentInstalledApps];
}
- (void)df157InstallSoloMenuWithUsableRect:(CGRect)usable {
 // App chooser belongs to native Home return only, never a redundant
 // three-dot overlay or a split-mode switch on the running app.
 self.soloPill=nil;
 DFAppPickerVC *picker=[DFAppPickerVC new];
 picker.delegate=self;
 picker.currentSlotBundleID=self.bundle;
 picker.otherSlotBundleIDs=@[];
 [self.root addChildViewController:picker];
 picker.view.frame=usable;
 picker.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
 [self.root.view addSubview:picker.view];
 [picker didMoveToParentViewController:self.root];
 picker.view.hidden=YES;self.soloPicker=picker;
 DF144Log(@"solo-one-owner-home-picker-installed",
     @"one-window-one-SBAppViewController-no-global-layout-mutation");
}
