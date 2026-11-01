// First-party QA152: optional, runtime-ABI-verified Dashboard native preparation.
// The actual Apple Dashboard-owned workspace and current official app MUST both
// be identified before a deactivation. Every path resumes launch exactly once.
// No SpringBoard phone eviction or unsupported selector guesses are done here.
#ifndef DF_NATIVE_WORKSPACE_PREPARE_152_H
#define DF_NATIVE_WORKSPACE_PREPARE_152_H
#import "DFNativePrepOnce152.h"

static DF152Preparation DF152Prep;
static NSString *DF152CurrentRID;

static BOOL DF152ExactInstance(id obj,const char *method,const char *encoding) {
 if(!obj)return NO;
 Method m=class_getInstanceMethod(object_getClass(obj),sel_registerName(method));
 return m && !strcmp(method_getTypeEncoding(m),encoding);
}
static BOOL DF152ShowNativeApp(id dashboard,BOOL *value) {
 return DF151SafeBoolGetter(dashboard,"showingApp",value);
}
static void DF152RevokeNativePreparation(void) {
 DF152Revoke(&DF152Prep);
 DF152CurrentRID=nil;
}
static void DF152ResumeNative(uint64_t generation,NSString *rid,
                              NSString *cause,void (^continuation)(void)) {
 if(!NSThread.isMainThread) {
  dispatch_async(dispatch_get_main_queue(),^{
    DF152ResumeNative(generation,rid,cause,continuation);
  });
  return;
 }
 if(![DF152CurrentRID isEqualToString:rid] ||
    !DF152FinishOnce(&DF152Prep,generation)) {
   DF144Log(@"qa152-prep-stale-or-duplicate",
     [NSString stringWithFormat:@"req=%@ cause=%@",rid,cause]);
   return;
 }
 DF144Log(@"qa152-native-prep-resume",
   [NSString stringWithFormat:@"req=%@ cause=%@",rid,cause]);
 if(continuation)continuation();
}

static void DF152PrepareThenContinue(NSString *rid,NSString *selectedBundle,
                                      NSString *carDisplay,id dashboard,
                                      void (^continuation)(void)) {
 // Only called in CarPlay main-thread after explicit user selection and full
 // request validation; fails open to the older standalone host *without*
 // altering native state if an API, owner, or receiver is unknown.
 uint64_t generation=DF152Begin(&DF152Prep);
 DF152CurrentRID=[rid copy];
 if(!NSThread.isMainThread || !rid.length || !selectedBundle.length ||
    !carDisplay.length || !continuation) {
   DF152ResumeNative(generation,rid,@"invalid-context",continuation);
   return;
 }
 id workspace=DF151DashboardWorkspace;
 id owner=DF151DashboardOwner;
 id homeWorkspace=nil;
 BOOL workspaceMatched=DF151IsDashboardOwner(owner) && workspace &&
   DF151SafeObjectGetter(dashboard,"workspace",&homeWorkspace) &&
   homeWorkspace==workspace;
 if(!workspaceMatched) {
   DF152ResumeNative(generation,rid,@"dashboard-workspace-unverified",continuation);
   return;
 }
 BOOL showing=NO;
 if(!DF152ShowNativeApp(dashboard,&showing)) {
   DF152ResumeNative(generation,rid,@"native-showing-app-ABI-unverified",continuation);
   return;
 }
 if(!showing) {
   DF152ResumeNative(generation,rid,@"native-chooser-ready",continuation);
   return;
 }
 id state=nil,activeBundle=nil;
 if(!DF151SafeObjectGetter(workspace,"state",&state) ||
    !DF151SafeObjectGetter(state,"activeBundleIdentifier",&activeBundle) ||
    ![activeBundle isKindOfClass:NSString.class] ||
    ![activeBundle length] || [activeBundle isEqualToString:selectedBundle]) {
   DF152ResumeNative(generation,rid,@"foreground-bundle-unknown-or-target",continuation);
   return;
 }
 // The original resolves the FOREGROUND SCENE's bundle, not an arbitrary
 // active app or the Home grid. Cross-check it against captured workspace state.
 id scene=nil,sceneBundle=nil;
 if(!DF151SafeObjectGetter(dashboard,"_foregroundActiveScene",&scene) || !scene ||
    !DF152ExactInstance(dashboard,"_activeBundleIdentifierForScene:","@24@0:8@16")) {
   DF152ResumeNative(generation,rid,@"native-foreground-scene-unverified",continuation);return;
 }
 @try {sceneBundle=((id(*)(id,SEL,id))objc_msgSend)(dashboard,
     sel_registerName("_activeBundleIdentifierForScene:"),scene);}
 @catch(__unused NSException *e){sceneBundle=nil;}
 if(![sceneBundle isKindOfClass:NSString.class] || ![sceneBundle isEqualToString:activeBundle]) {
   DF152ResumeNative(generation,rid,@"native-scene-workspace-bundle-mismatch",continuation);return;
 }
 Class requestClass=objc_getClass("DBMutableWorkspaceStateChangeRequest");
 if(!DF152ExactInstance(workspace,"requestStateChange:","v24@0:8@16") || !requestClass) {
   DF152ResumeNative(generation,rid,@"native-workspace-ABI-missing",continuation);return;
 }
 Method deactivate=class_getInstanceMethod(requestClass,sel_registerName("deactivateApplication:"));
 Method callback=class_getInstanceMethod(requestClass,sel_registerName("setCompletionHandler:"));
 const char *callbackType=callback?method_getTypeEncoding(callback):NULL;
 if(!deactivate || strcmp(method_getTypeEncoding(deactivate),"v24@0:8@16") ||
    !callback || (strcmp(callbackType,"v24@0:8@?16") &&
                  strcmp(callbackType,"v24@0:8@16"))) {
   DF152ResumeNative(generation,rid,@"deactivation-completion-ABI-missing",continuation);
   return;
 }
 id library=nil,officialApp=nil;
 @try {
   id app=DFNativeCarApplication();
   if(!DF151SafeObjectGetter(app,"sharedApplicationLibrary",&library) ||
      !DF152ExactInstance(library,"applicationInfoForBundleIdentifier:","@24@0:8@16")) {
     DF152ResumeNative(generation,rid,@"native-app-lookup-ABI-missing",continuation);return;
   }
   officialApp=((id(*)(id,SEL,id))objc_msgSend)(library,
      sel_registerName("applicationInfoForBundleIdentifier:"),activeBundle);
   id actualBundle=nil;
   if(!DF151SafeObjectGetter(officialApp,"bundleIdentifier",&actualBundle) ||
      ![actualBundle isEqualToString:activeBundle]) {
     DF152ResumeNative(generation,rid,@"native-foreground-app-unverified",continuation);
     return;
   }
   // An object typed request is required, not a custom CarPlay overlay.
   id request=[requestClass new];
   if(!request) {
     DF152ResumeNative(generation,rid,@"request-allocation-failed",continuation);
     return;
   }
   // The original DuoNavi route uses a completion plus a bounded fallback;
   // calling either twice or after a replacement may NEVER trigger a new host.
   void (^finish)(void)=^{
     DF152ResumeNative(generation,rid,@"workspace-completion",continuation);
   };
   ((void(*)(id,SEL,id))objc_msgSend)(request,
      sel_registerName("deactivateApplication:"),officialApp);
   ((void(*)(id,SEL,id))objc_msgSend)(request,
      sel_registerName("setCompletionHandler:"),[finish copy]);
   DF144Log(@"qa152-native-workspace-deactivate-request",
      [NSString stringWithFormat:@"req=%@ official=%@ target=%@",rid,activeBundle,selectedBundle]);
   ((void(*)(id,SEL,id))objc_msgSend)(workspace,
      sel_registerName("requestStateChange:"),request);
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.25*NSEC_PER_SEC)),
     dispatch_get_main_queue(),^{
       DF152ResumeNative(generation,rid,@"native-workspace-fallback-250ms",continuation);
     });
 } @catch(NSException *e) {
   DF144Log(@"qa152-workspace-exception",
      [NSString stringWithFormat:@"req=%@ name=%@ reason=%@",rid,e.name,e.reason]);
   DF152ResumeNative(generation,rid,@"native-workspace-exception",continuation);
 }
}
#endif
