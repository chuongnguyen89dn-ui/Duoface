// Read-only CarPlay metadata and public scene-tree observation. No private calls.
#import <stdlib.h>
static NSUInteger dnDockSamples;
static NSString *DNText(const char *value) {
 return value ? [NSString stringWithUTF8String:value] : @"missing";
}
static NSArray<NSString *> *DNDockSelectors(void) {
 return @[@"appDockVC",@"appHistory",@"homeButton",@"workspace",@"state",
  @"_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:",
  @"setActiveBundleIdentifier:animated:",@"_refreshAppDock",@"setDisplayState:",
  @"requestStateChange:",@"activateApplication:",@"deactivateApplication:",
  @"_foregroundActiveScene"];
}
static BOOL DNDockClass(Class cls) {
 NSString *n=DNText(class_getName(cls));
 // Apple owners only; never inspect commercial bridge internals at runtime.
 return [n hasPrefix:@"DB"] || [n hasPrefix:@"CAR"] || [n hasPrefix:@"CR"];
}
static NSArray *DNDockDeclarations(Class cls) {
 NSMutableArray *result=[NSMutableArray array];
 unsigned int count=0;
 Ivar *ivars=class_copyIvarList(cls,&count);
 for(unsigned int i=0;i<count;i++) {
  NSString *n=DNText(ivar_getName(ivars[i]));
  NSString *lower=n.lowercaseString;
  if([lower containsString:@"dock"] || [lower containsString:@"history"] ||
     [lower containsString:@"workspace"] || [lower containsString:@"homebutton"])
   [result addObject:@{@"name":n,@"encoding":DNText(ivar_getTypeEncoding(ivars[i])),
      @"offset":@(ivar_getOffset(ivars[i]))}];
 }
 free(ivars);
 return result;
}
static NSArray *DNDockMethods(Class cls) {
 NSMutableArray *result=[NSMutableArray array];
 unsigned int count=0;
 // Declared methods only: do not mislabel inherited methods as owners.
 Method *methods=class_copyMethodList(cls,&count);
 for(unsigned int i=0;i<count;i++) {
  NSString *name=NSStringFromSelector(method_getName(methods[i]));
  if(![DNDockSelectors() containsObject:name])continue;
  [result addObject:@{@"selector":name,@"encoding":DNText(method_getTypeEncoding(methods[i])),
    @"argument_count":@(method_getNumberOfArguments(methods[i]))}];
 }
 free(methods);
 return result;
}
static void DNDockSceneTree(NSUInteger sample) {
 NSUInteger nodes=0;
 for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
  if(![scene isKindOfClass:UIWindowScene.class])continue;
  UIWindowScene *ws=(UIWindowScene *)scene;
  for(UIWindow *window in ws.windows) {
   if(nodes>=64)return;
   NSMutableArray *queue=[NSMutableArray array];
   if(window.rootViewController)[queue addObject:window.rootViewController];
   NSHashTable *seen=[NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
   for(NSUInteger cursor=0;cursor<queue.count && nodes<64;cursor++) {
    UIViewController *vc=queue[cursor];
    if([seen containsObject:vc])continue;
    [seen addObject:vc];nodes++;
    DNLog(@"native_dock_scene_node",@{@"sample":@(sample),
      @"scene_role":ws.session.role?:@"missing",@"scene_state":@(ws.activationState),
      @"orientation":@(ws.interfaceOrientation),@"window_class":DNText(class_getName(object_getClass(window))),
      @"window_hidden":@(window.hidden),@"window_level":@(window.windowLevel),
      @"external":@(window.screen!=UIScreen.mainScreen),
      @"window_frame":NSStringFromCGRect(window.frame),
      @"controller_class":DNText(class_getName(object_getClass(vc))),
      @"parent_class":vc.parentViewController?DNText(class_getName(object_getClass(vc.parentViewController))):@"none"});
    // Public existing containment only. Do not load vc.view or private getters.
    for(UIViewController *child in vc.childViewControllers)
     if(queue.count<64 && ![seen containsObject:child])[queue addObject:child];
    if(vc.presentedViewController && queue.count<64)[queue addObject:vc.presentedViewController];
   }
  }
 }
}
static void DNNativeDockSample(void) {
 if(![NSThread isMainThread] ||
    ![@[@"CarPlay",@"CarPlayApp"] containsObject:dnProcess] || dnDockSamples>=24)return;
 NSUInteger sample=++dnDockSamples;
 unsigned int count=0,owners=0;
 Class *classes=objc_copyClassList(&count);
 for(unsigned int i=0;i<count;i++) {
  Class cls=classes[i];
  if(!DNDockClass(cls))continue;
  NSArray *methods=DNDockMethods(cls);
  NSArray *ivars=DNDockDeclarations(cls);
  if(!methods.count && !ivars.count)continue;
  owners++;
  DNLog(@"native_dock_class_abi",@{@"sample":@(sample),@"class":DNText(class_getName(cls)),
    @"superclass":DNText(class_getName(class_getSuperclass(cls))),
    @"image":DNText(class_getImageName(cls)),@"declared_methods":methods,@"declared_ivars":ivars});
 }
 free(classes);
 DNDockSceneTree(sample);
 DNLog(@"native_dock_sample_complete",@{@"sample":@(sample),@"owner_classes":@(owners),
   @"complete":@(dnDockSamples==24),@"private_methods_invoked":@NO,
   @"private_ivar_values_read":@NO,@"does_not_measure":@"call arguments, ACK, first touch, app-side scene"});
}
