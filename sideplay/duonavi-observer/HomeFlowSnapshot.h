// ABI-checked read-only native state at the actual call boundary. Main thread only.
#import <mach-o/dyld.h>
static id DNFlowText(id value) {
 return [value isKindOfClass:NSString.class]&&[value length]<180?value:@"unavailable";
}
static NSDictionary *DNFlowImages(void) {
 BOOL original=NO,duoface=NO;
 for(uint32_t i=0;i<_dyld_image_count();i++) {
  const char *name=_dyld_get_image_name(i);if(!name)continue;
  if(strstr(name,"/DuoNaviDashboard.dylib"))original=YES;
  if(strstr(name,"/DFCarPlayDockOwner.dylib") || strstr(name,"/DFTouchOwnerProbe.dylib"))duoface=YES;
 }
 return @{@"DuoNaviDashboard":@(original),@"DuoFace_active_modules":@(duoface),
   @"mixed_bridge_warning":@(original&&duoface)};
}
static NSArray *DNFlowVisibleTree(void) {
 NSMutableArray *nodes=[NSMutableArray array];
 for(UIScene *s in UIApplication.sharedApplication.connectedScenes) {
  if(![s isKindOfClass:UIWindowScene.class])continue;
  UIWindowScene *scene=(UIWindowScene *)s;
  for(UIWindow *window in scene.windows) {
   if(window.screen==UIScreen.mainScreen || window.hidden || window.alpha<.01)continue;
   NSMutableArray *queue=[NSMutableArray array];
   if(window.rootViewController)[queue addObject:window.rootViewController];
   NSHashTable *seen=[NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
   for(NSUInteger i=0;i<queue.count && nodes.count<48;i++) {
    UIViewController *vc=queue[i];if([seen containsObject:vc])continue;[seen addObject:vc];
    UIView *v=vc.viewIfLoaded; // Never load a view just to observe it.
    BOOL visible=v&&v.window==window&&!v.hidden&&v.alpha>.01;
    for(UIView *p=v.superview;p&&visible;p=p.superview)if(p.hidden||p.alpha<=.01)visible=NO;
    [nodes addObject:@{@"controller":DNFlowIdentity(vc),@"parent":DNFlowIdentity(vc.parentViewController),
     @"window":DNFlowIdentity(window),@"scene":scene.session.persistentIdentifier?:@"unavailable",
     @"role":scene.session.role?:@"unavailable",@"scene_state":@(scene.activationState),
     @"visible":@(visible),@"frame":v?NSStringFromCGRect(v.frame):@"unloaded",
     @"presented":DNFlowIdentity(vc.presentedViewController)}];
    for(UIViewController *child in vc.childViewControllers)
     if(queue.count<48&&![seen containsObject:child])[queue addObject:child];
    if(vc.presentedViewController&&queue.count<48)[queue addObject:vc.presentedViewController];
   }
   if(nodes.count>=48)return nodes;
  }
 }return nodes;
}
// The manager's ACTUAL received instance is supplied by the forwarded SB hook.
// Do not conjure a singleton, assume private ivar offsets, or turn a method name
// into evidence that a hosted app/window exists. Exact getter encodings only.
static NSDictionary *DNFlowBridgeHostReadback(id receiver) {
 if(!receiver || ![NSStringFromClass(object_getClass(receiver))
                      isEqualToString:@"CBBridgeManager"])
   return @{@"status":@"not-original-manager-receiver"};
 BOOL hasApp=DNFlowExact(receiver,"currentApp","@16@0:8");
 BOOL hasWindow=DNFlowExact(receiver,"window","@16@0:8");
 BOOL hasBundle=DNFlowExact(receiver,"bundleIdentifier","@16@0:8");
 if(!hasApp || !hasWindow)
   return @{@"status":@"manager-getter-abi-missing",
            @"currentAppGetter":@(hasApp),@"windowGetter":@(hasWindow),
            @"bundleGetter":@(hasBundle)};
 id current=DNFlowGet(receiver,"currentApp");
 id bridgeWindow=DNFlowGet(receiver,"window");
 id appBundle=DNFlowGet(current,"bundleIdentifier");
 id managerBundle=hasBundle?DNFlowGet(receiver,"bundleIdentifier"):nil;
 // CBWindow's rootWindow getter is optional. Never dereference a guessed ivar.
 BOOL hasRoot=bridgeWindow&&DNFlowExact(bridgeWindow,"rootWindow","@16@0:8");
 id root=hasRoot?DNFlowGet(bridgeWindow,"rootWindow"):nil;
 NSMutableDictionary *result=[@{@"status":@"runtime-manager-getters",
    @"manager":DNFlowIdentity(receiver),
    @"managerBundle":DNFlowText(managerBundle),
    @"currentApp":DNFlowIdentity(current),
    @"currentAppBundle":DNFlowText(appBundle),
    @"bridgeWindow":DNFlowIdentity(bridgeWindow),
    @"rootWindowGetter":@(hasRoot),
    @"rootWindow":DNFlowIdentity(root),
    @"activated":DNFlowBoolGet(receiver,"activated")} mutableCopy];
 if([root isKindOfClass:UIWindow.class]) {
   UIWindow *win=(UIWindow *)root;
   result[@"rootWindowHidden"]=@(win.hidden);
   result[@"rootWindowAlpha"]=@(win.alpha);
   result[@"rootWindowFrame"]=NSStringFromCGRect(win.frame);
   result[@"rootWindowScene"]=win.windowScene.session.persistentIdentifier?:@"unavailable";
 }
 return result;
}
static NSDictionary *DNFlowSnapshot(id receiver) {
 if(!NSThread.isMainThread)return @{@"unavailable":@"not-main-thread"};
 id app=UIApplication.sharedApplication;
 id dashboard=DNFlowGet(app,"_currentDashboard")?:DNFlowGet(app,"currentDashboard");
 id workspace=DNFlowGet(dashboard,"workspace"),state=DNFlowGet(workspace,"state");
 id scene=DNFlowGet(dashboard,"_foregroundActiveScene"),sceneBundle=nil;
 if(scene&&DNFlowExact(dashboard,"_activeBundleIdentifierForScene:","@24@0:8@16"))
  @try{sceneBundle=((id(*)(id,SEL,id))objc_msgSend)(dashboard,sel_registerName("_activeBundleIdentifierForScene:"),scene);}
  @catch(__unused NSException *e){}
 id status=DNFlowGet(dashboard,"statusBarViewController")?:DNFlowGet(dashboard,"rootViewController");
 id dock=DNFlowGet(status,"appDockVC"),home=DNFlowGet(status,"homeButton");
 id receiverHome=DNFlowGet(receiver,"homeButton");
 id receiverHomeState=@"unavailable",receiverState=@"unavailable";
 if(DNFlowExact(receiverHome,"displayState","Q16@0:8"))
  @try{receiverHomeState=@(((NSUInteger(*)(id,SEL))objc_msgSend)(receiverHome,sel_registerName("displayState")));}
  @catch(__unused NSException *e){}
 if(DNFlowExact(receiver,"displayState","Q16@0:8"))
  @try{receiverState=@(((NSUInteger(*)(id,SEL))objc_msgSend)(receiver,sel_registerName("displayState")));}
  @catch(__unused NSException *e){}
 id homeState=@"unavailable";
 if(DNFlowExact(home,"displayState","Q16@0:8"))
  @try{homeState=@(((NSUInteger(*)(id,SEL))objc_msgSend)(home,sel_registerName("displayState")));}
  @catch(__unused NSException *e){}
 return @{@"dashboard":DNFlowIdentity(dashboard),@"showingApp":DNFlowBoolGet(dashboard,"showingApp"),
  @"workspace":DNFlowIdentity(workspace),@"activeBundle":DNFlowText(DNFlowGet(state,"activeBundleIdentifier")),
  @"foregroundScene":DNFlowIdentity(scene),@"foregroundBundle":DNFlowText(sceneBundle),
  @"statusbar":DNFlowIdentity(status),@"dock":DNFlowIdentity(dock),
  @"dockBundle":DNFlowText(DNFlowGet(dock,"activeBundleIdentifier")),
  @"homeButton":DNFlowIdentity(home),@"homeDisplayState":homeState,
  @"receiverHomeButton":DNFlowIdentity(receiverHome),@"receiverHomeState":receiverHomeState,
  @"receiverDisplayState":receiverState,@"receiverDockBundle":DNFlowText(DNFlowGet(receiver,"activeBundleIdentifier")),
  @"receiverActivated":DNFlowBoolGet(receiver,"activated"),@"receiverPending":DNFlowBoolGet(receiver,"pending"),
  @"visible_native_tree":DNFlowVisibleTree(),@"images":DNFlowImages(),
  @"bridge_owner":DNFlowBridgeHostReadback(receiver),
  @"limits":@"readback; visible tree is not pixel proof or a named page without reference comparison"};
}
