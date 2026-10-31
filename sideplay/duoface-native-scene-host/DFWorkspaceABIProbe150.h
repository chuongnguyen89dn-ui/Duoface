// DuoFace independent, read-only runtime ABI inventory for exact iOS16 builds.
// Never instantiate private workspace requests or change foreground state.
// Included by DFHomeStandalone144.m, after DF144Log and objc/runtime imports.
#ifndef DF_WORKSPACE_ABI_PROBE_150_H
#define DF_WORKSPACE_ABI_PROBE_150_H

static void DF150RecordABI(NSString *rid,const char *className,
                           const char *methodName,BOOL classMethod) {
 Class cls=objc_getClass(className);
 SEL sel=sel_registerName(methodName);
 Method m=cls?(classMethod?class_getClassMethod(cls,sel):
                           class_getInstanceMethod(cls,sel)):NULL;
 const char *type=m?method_getTypeEncoding(m):NULL;
 // A missing class/selector is reported as missing, not assumed equivalent.
 DF144Log(@"qa150-native-workspace-abi",
     [NSString stringWithFormat:@"req=%@ class=%s kind=%s selector=%s present=%d type=%s",
       rid?:@"",className,classMethod?"class":"instance",methodName,
       m!=NULL,type?: "missing"]);
}

static void DF150ProbeWorkspaceForRequest(NSString *rid,NSString *bundle,
                                          NSString *display,BOOL springboard) {
 if(!rid.length || !bundle.length || !display.length)return;
 DF144Log(@"qa150-native-workspace-probe-start",
   [NSString stringWithFormat:@"req=%@ bid=%@ display=%@ role=%@",
     rid,bundle,display,springboard?@"SpringBoard":@"CarPlay"]);
 if(springboard) {
  DF150RecordABI(rid,"SBMainWorkspace","sharedInstance",YES);
  DF150RecordABI(rid,"SBMainWorkspace","executeTransitionRequest:",NO);
  DF150RecordABI(rid,"SBMainWorkspace","createRequestWithOptions:",NO);
  DF150RecordABI(rid,"SBMainWorkspace","createRequestForApplicationActivation:options:",NO);
  DF150RecordABI(rid,"SBMainWorkspace","_executeTransitionRequest:options:validator:",NO);
  DF150RecordABI(rid,"SBMainWorkspaceTransitionRequest","setCompletionHandler:",NO);
  DF150RecordABI(rid,"SBMainWorkspaceTransitionRequest","setActivatingEntity:",NO);
  DF150RecordABI(rid,"SBMainWorkspaceTransitionRequest","setApplicationContext:",NO);
  DF150RecordABI(rid,"SBUIController","sharedInstance",YES);
  DF150RecordABI(rid,"SBUIController","clickedMenuButton",NO);
  DF150RecordABI(rid,"SBApplicationController","sharedInstance",YES);
  DF150RecordABI(rid,"SBApplicationController","applicationWithBundleIdentifier:",NO);
  DF150RecordABI(rid,"SBApplication","processState",NO);
  DF150RecordABI(rid,"SBApplicationProcessState","pid",NO);
 } else {
  DF150RecordABI(rid,"DBMutableWorkspaceStateChangeRequest","init",NO);
  DF150RecordABI(rid,"DBMutableWorkspaceStateChangeRequest","deactivateApplication:",NO);
  DF150RecordABI(rid,"DBMutableWorkspaceStateChangeRequest","setCompletionHandler:",NO);
  DF150RecordABI(rid,"DBWorkspace","requestStateChange:",NO);
  DF150RecordABI(rid,"DBWorkspace","sharedInstance",YES);
  DF150RecordABI(rid,"DBDashboardHomeViewController","workspace",NO);
  DF150RecordABI(rid,"DBDashboardHomeViewController","showingApp",NO);
  DF150RecordABI(rid,"DBDashboardHomeViewController","_foregroundActiveScene",NO);
  DF150RecordABI(rid,"DBRootStatusBarViewController","homeButtonUp:",NO);
  DF150RecordABI(rid,"DBAppDockViewController","_dockButtonPressed:",NO);
  DF150RecordABI(rid,"DBAppDockViewController","activeBundleIdentifier",NO);
 }
 DF144Log(@"qa150-native-workspace-probe-complete",
   [NSString stringWithFormat:@"req=%@ role=%@",rid,
      springboard?@"SpringBoard":@"CarPlay"]);
}
#endif
