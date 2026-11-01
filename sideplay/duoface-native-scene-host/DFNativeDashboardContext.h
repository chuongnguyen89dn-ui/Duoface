// First-party native context resolution, learned from the pinned original's
// dashboard -> workspace route, not the unrelated Home grid controller.
#ifndef DF_NATIVE_DASHBOARD_CONTEXT_H
#define DF_NATIVE_DASHBOARD_CONTEXT_H
static id DFNativeCarApplication(void) {
 Class cls=objc_getClass("UIApplication");
 Method m=cls?class_getClassMethod(cls,sel_registerName("sharedApplication")):NULL;
 if(!m || strcmp(method_getTypeEncoding(m),"@16@0:8"))return nil;
 @try{return ((id(*)(id,SEL))objc_msgSend)(cls,sel_registerName("sharedApplication"));}
 @catch(__unused NSException *e){return nil;}
}
static id DFResolveNativeDashboard(id anchor,BOOL homeGrid,NSString *rid) {
 if(!NSThread.isMainThread || !anchor || !DF151IsDashboardOwner(DF151DashboardOwner) ||
    !DF151DashboardWorkspace)return nil;
 id app=DFNativeCarApplication(),dashboard=nil;
 const char *used="none";
 // Both literal selectors are present in original CBDashboardShared.dashboard.
 for(NSString *name in @[@"_currentDashboard",@"currentDashboard"]) {
  id value=nil;
  if(DF151SafeObjectGetter(app,name.UTF8String,&value) && value) {
   dashboard=value;used=name.UTF8String;break;
  }
 }
 id workspace=nil,root=nil,rootView=nil,rootWindow=nil,rootScreen=nil;
 id anchorView=nil,anchorWindow=nil,anchorScreen=nil;
 Class screenClass=objc_getClass("UIScreen");
 Method mainGetter=screenClass?class_getClassMethod(screenClass,sel_registerName("mainScreen")):NULL;
 id mainScreen=nil;
 if(mainGetter && !strcmp(method_getTypeEncoding(mainGetter),"@16@0:8"))
   mainScreen=((id(*)(id,SEL))objc_msgSend)(screenClass,sel_registerName("mainScreen"));
 BOOL verified=dashboard &&
   DF151SafeObjectGetter(dashboard,"workspace",&workspace) && workspace==DF151DashboardWorkspace &&
   DF151SafeObjectGetter(dashboard,"rootViewController",&root) && root &&
   DF151SafeObjectGetter(root,"viewIfLoaded",&rootView) &&
   DF151SafeObjectGetter(rootView,"window",&rootWindow) &&
   DF151SafeObjectGetter(rootWindow,"screen",&rootScreen) &&
   DF151SafeObjectGetter(anchor,"viewIfLoaded",&anchorView) &&
   DF151SafeObjectGetter(anchorView,"window",&anchorWindow) &&
   DF151SafeObjectGetter(anchorWindow,"screen",&anchorScreen) &&
   mainScreen && rootScreen && rootScreen!=mainScreen && rootScreen==anchorScreen;
 // Home grid must belong to this actual dashboard root. Dock lives in its
 // separate statusbar hierarchy; there we require the same external screen.
 BOOL related=!homeGrid;
 id cursor=anchor;
 for(unsigned n=0;verified && homeGrid && cursor && n<32;n++) {
  if(cursor==root){related=YES;break;}
  id parent=nil;
  if(!DF151SafeObjectGetter(cursor,"parentViewController",&parent) || parent==cursor)break;
  cursor=parent;
 }
 verified=verified&&related;
 DF144Log(verified?@"native-dashboard-context-verified":@"native-dashboard-context-refused",
   [NSString stringWithFormat:@"req=%@ getter=%s anchor=%@ dashboard=%@ workspaceSame=%d externalSame=%d rootRelated=%d",
    rid,used,NSStringFromClass([anchor class]),dashboard?NSStringFromClass([dashboard class]):@"missing",
    workspace&&workspace==DF151DashboardWorkspace,rootScreen&&rootScreen==anchorScreen&&rootScreen!=mainScreen,related]);
 return verified?dashboard:nil;
}
#endif
