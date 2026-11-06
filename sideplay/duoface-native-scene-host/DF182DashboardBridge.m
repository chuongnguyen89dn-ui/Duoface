// New first-party B1 route through the captured Apple Dashboard workspace.
#import "DF182NativeMapAssignment.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <string.h>
static __weak id DF182LiveLibrary;
void DF182CaptureLibrary(id library) {
 if([NSProcessInfo.processInfo.processName isEqual:@"CarPlay"] &&
    [library isKindOfClass:objc_getClass("FBSApplicationLibrary")])DF182LiveLibrary=library;
}
static BOOL DF182Exact(id obj,const char *name,const char *type) {
 Method m=obj?class_getInstanceMethod(object_getClass(obj),sel_registerName(name)):NULL;
 return m && !strcmp(method_getTypeEncoding(m),type);
}
// Returns evidence only. Issuing a request is not native scene acceptance.
NSDictionary *DF182CatalogAndLaunch(NSDictionary *assignment) {
 if(!NSThread.isMainThread || ![NSProcessInfo.processInfo.processName isEqual:@"CarPlay"] ||
    ![assignment[@"AssignmentID"] isEqual:DF182Assignment()[@"AssignmentID"]])
  return @{@"Catalog":@"UNVERIFIED",@"Launch":@"UNVERIFIED",@"Reason":@"stale-or-wrong-owner"};
 @try {
  id library=DF182LiveLibrary?:DF182ExistingApplicationLibrary();
  NSString *reason=nil;
  id info=DF182ReconcileNativeMaps(library,&reason);
  DF182Log(@"catalog-reconciled",assignment,[NSString stringWithFormat:
   @"catalog=%@ library=%@ reason=%@ declaration=original-unmodified launch=UNVERIFIED",
   info?@"PASS":@"FAIL",library?NSStringFromClass([library class]):@"unknown",reason?:@"unknown"]);
  if(!info)return @{@"Catalog":@"FAIL",@"Launch":@"UNVERIFIED",@"Reason":reason?:@"catalog-failed"};
  id workspace=DF182CapturedDashboardWorkspace();
  id request=[objc_getClass("DBMutableWorkspaceStateChangeRequest") new];
  if(!DF182Exact(workspace,"requestStateChange:","v24@0:8@16") ||
     !DF182Exact(request,"activateApplication:","v24@0:8@16"))
   return @{@"Catalog":@"PASS",@"Launch":@"FAIL",@"Reason":@"native-workspace-launch-ABI-missing-or-mismatched"};
  ((void(*)(id,SEL,id))objc_msgSend)(request,sel_registerName("activateApplication:"),info);
  ((void(*)(id,SEL,id))objc_msgSend)(workspace,sel_registerName("requestStateChange:"),request);
  DF182Log(@"launch-issued",assignment,[NSString stringWithFormat:
    @"workspace=%@ info=%@ launch=UNVERIFIED acceptance=UNVERIFIED fallback=forbidden",
    NSStringFromClass([workspace class]),NSStringFromClass([info class])]);
  return @{@"Catalog":@"PASS",@"Launch":@"UNVERIFIED",@"Issued":@YES,@"Reason":@"request-issued-await-native-scene"};
 } @catch(NSException *exception) {
  return @{@"Catalog":@"UNVERIFIED",@"Launch":@"FAIL",@"Reason":exception.name?:@"native-launch-exception"};
 }
}
