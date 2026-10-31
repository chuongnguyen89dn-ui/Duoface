// Independent DuoFace QA151. Passive native DBWorkspace owner capture only.
// No App activation, deactivation, workspace request construction, or Dock mutation.
// Source-method precedent: CarSurf sbtweak/CSCarLaunch.m (read-only, compared);
// original DuoNavi binary audit independently confirms DBWorkspace request stage.
#ifndef DF_WORKSPACE_OWNER_CAPTURE_151_H
#define DF_WORKSPACE_OWNER_CAPTURE_151_H
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach-o/loader.h>

// Only the Dashboard owner can arbitrate the main CarPlay display. Reject
// a later instrument-cluster workspace instead of overwriting the reference.
static __weak id DF151DashboardWorkspace;
static __weak id DF151DashboardOwner;
static id (*DF151OriginalWorkspaceInit)(id,SEL,id);
static BOOL DF151WorkspaceHookInstalled;
static BOOL DF151ImageCallbackInstalled;

static BOOL DF151IsDashboardOwner(id owner) {
 Class ownerClass=objc_getClass("DBDashboardWorkspaceOwner");
 return owner && ownerClass && [owner isKindOfClass:ownerClass];
}
static BOOL DF151SafeObjectGetter(id obj,const char *method,id *result) {
 if(result)*result=nil;
 if(!obj)return NO;
 SEL selector=sel_registerName(method);
 Method m=class_getInstanceMethod(object_getClass(obj),selector);
 if(!m || strcmp(method_getTypeEncoding(m),"@16@0:8"))return NO;
 @try {
  id value=((id(*)(id,SEL))objc_msgSend)(obj,selector);
  if(result)*result=value;
  return YES;
 } @catch(NSException *error) {
  DF144Log(@"qa151-native-getter-exception",
     [NSString stringWithFormat:@"sel=%s name=%@",method,error.name]);
  return NO;
 }
}
static id DF151WorkspaceInitWithOwner(id workspace,SEL selector,id owner) {
 id actual=DF151OriginalWorkspaceInit(workspace,selector,owner);
 if(actual && DF151IsDashboardOwner(owner)) {
  DF151DashboardOwner=owner;
  DF151DashboardWorkspace=actual;
  DF144Log(@"qa151-dashboard-workspace-captured",
   [NSString stringWithFormat:@"owner=%@ workspace=%@",
      NSStringFromClass([owner class]),NSStringFromClass([actual class])]);
 }
 return actual;
}
static BOOL DF151InstallWorkspaceCapture(void) {
 if(DF151WorkspaceHookInstalled)return YES;
 Class cls=objc_getClass("DBWorkspace");
 SEL selector=sel_registerName("initWithOwner:");
 Method m=cls?class_getInstanceMethod(cls,selector):NULL;
 DF144Hook hook=(DF144Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(!m || !hook)return NO;
 // Fail-closed if the actual target runtime changes argument / return ABI.
 if(strcmp(method_getTypeEncoding(m),"@24@0:8@16")) {
  DF144Log(@"qa151-workspace-init-abi-unsupported",
    [NSString stringWithFormat:@"actual=%s",method_getTypeEncoding(m)]);
  return NO;
 }
 hook(cls,selector,(IMP)DF151WorkspaceInitWithOwner,
      (IMP *)&DF151OriginalWorkspaceInit);
 DF151WorkspaceHookInstalled=DF151OriginalWorkspaceInit!=NULL;
 if(DF151WorkspaceHookInstalled)
  DF144Log(@"qa151-workspace-owner-hook-installed",@"read-only; requires DBDashboardWorkspaceOwner");
 return DF151WorkspaceHookInstalled;
}
static void DF151WorkspaceImageLoaded(const struct mach_header *header) {
 (void)header;
 if(!DF151WorkspaceHookInstalled)DF151InstallWorkspaceCapture();
}
static void DF151StartCapture(void) {
 if(DF151InstallWorkspaceCapture())return;
 if(!DF151ImageCallbackInstalled) {
   DF151ImageCallbackInstalled=YES;
   objc_addLoadImageFunc(DF151WorkspaceImageLoaded);
 }
 DF144Log(@"qa151-workspace-capture-wait-image",@"no arbitrary workspace will be constructed");
}
static void DF151WorkspaceSnapshot(NSString *requestID,NSString *bundle,
                                    NSString *display,id home) {
 id workspace=DF151DashboardWorkspace, owner=DF151DashboardOwner;
 BOOL captured=workspace && DF151IsDashboardOwner(owner);
 id homeWorkspace=nil;
 BOOL hasHomeGetter=DF151SafeObjectGetter(home,"workspace",&homeWorkspace);
 id showingApp=nil;
 BOOL hasShowingApp=DF151SafeObjectGetter(home,"showingApp",&showingApp);
 id state=nil,activeBundle=nil;
 BOOL hasState=captured && DF151SafeObjectGetter(workspace,"state",&state);
 BOOL hasActive=hasState && DF151SafeObjectGetter(state,"activeBundleIdentifier",&activeBundle);
 // Strong readback at the *real* selected CarPlay Home tap, not static metadata.
 DF144Log(@"qa151-native-workspace-live-owner",
   [NSString stringWithFormat:
     @"req=%@ bid=%@ display=%@ captured=%d dashboardOwner=%d workspaceClass=%@ homeGetter=%d workspaceSame=%d showingAppGetter=%d showingApp=%@ stateGetter=%d activeGetter=%d activeBundle=%@",
     requestID,bundle,display,captured,DF151IsDashboardOwner(owner),
     workspace?NSStringFromClass([workspace class]):@"missing",
     hasHomeGetter,hasHomeGetter&&homeWorkspace==workspace,hasShowingApp,
     showingApp?NSStringFromClass([showingApp class]):@"missing",
     hasState,hasActive,[activeBundle isKindOfClass:NSString.class]?activeBundle:@"unknown"]);
}
#endif
