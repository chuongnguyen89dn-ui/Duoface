// First-party menu for an existing single SpringBoard-owned DF144Solo scene.
// Included INSIDE @implementation DF144Solo; no extra SBAppViewController.
// The native Home callback still runs. Only our manager-owned SOLO surface
// is retired, and its own first-party chooser becomes the visible destination.
// Native CarPlay Music/Calendar never pass this SpringBoard live-owner gate.
- (BOOL)df157ReturnHomeToPicker {
 if(!self.window || self.window.hidden || !self.emittedManager ||
    !self.surface || !self.soloPicker || !DFHome145Enabled() ||
    ![[DFSceneHost sharedHost] isLiveSceneForHostedView:self.surface])return NO;
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
- (void)df157SoloPillPressed:(UIButton *)sender {
 (void)sender;
 if(!self.window || self.window.hidden || !self.surface || !self.emittedManager ||
    !self.soloPicker ||
    ![[DFSceneHost sharedHost] isLiveSceneForHostedView:self.surface])return;
 self.soloPicker.currentSlotBundleID=self.bundle;
 self.soloPicker.pendingSlotBundleID=nil;
 self.soloPicker.otherSlotBundleIDs=@[];
 [self.soloPicker presentInstalledApps];
 [self.soloPicker refreshInstalledApps];
 self.soloPicker.view.hidden=NO;
 self.soloPill.hidden=YES;
 [self.root.view bringSubviewToFront:self.soloPicker.view];
 DF144Log(@"solo-own-pill-app-picker-open",self.bundle);
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
 if(picker!=self.soloPicker || (!self.emittedManager && !self.homeChooser) ||
    !self.request.length || !self.carDisplayID.length ||
    !self.window || self.window.hidden || !DF144Allowed(bundle))return;
 if(!self.homeChooser && (!self.surface ||
    ![[DFSceneHost sharedHost] isLiveSceneForHostedView:self.surface]))return;
 if(!self.homeChooser && [bundle isEqual:self.bundle]) { [self appPickerDidCancel:picker];return; }
 NSDictionary *p=@{@"Version":@1,@"RequestID":self.request,
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
 // Real content rect starts to the RIGHT of native Apple Dock.
 UIButton *pill=[UIButton buttonWithType:UIButtonTypeSystem];
 pill.frame=CGRectMake(CGRectGetMinX(usable)+8,CGRectGetMinY(usable)+4,62,27);
 pill.backgroundColor=[UIColor colorWithWhite:.08 alpha:.86];
 pill.layer.cornerRadius=13.5;
 pill.layer.borderColor=[UIColor colorWithWhite:1 alpha:.28].CGColor;
 pill.layer.borderWidth=.5;
 [pill setTitle:@"•••" forState:UIControlStateNormal];
 [pill setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
 pill.titleLabel.font=[UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];
 pill.accessibilityLabel=@"DuoFace: chọn ứng dụng";
 [pill addTarget:self action:@selector(df157SoloPillPressed:)
              forControlEvents:UIControlEventTouchUpInside];
 pill.hidden=YES;self.soloPill=pill;
 [self.root.view addSubview:pill];
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
 DF144Log(@"solo-one-owner-pill-picker-installed",
     @"one-window-one-SBAppViewController-no-global-layout-mutation");
}
