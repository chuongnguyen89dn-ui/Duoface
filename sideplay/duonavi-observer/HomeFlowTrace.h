// First-party observational interposition. Each typed wrapper calls its saved
// IMP exactly once, preserving receiver/selector/arguments and exceptions.
#import <objc/message.h>
#import <dlfcn.h>
#import <stdatomic.h>
#import <string.h>
#import <stdlib.h>
static NSDictionary *DNFlowSnapshot(id receiver);
typedef void (*DNFlowHookAPI)(Class,SEL,IMP,IMP *);
typedef enum { DNFlowVoid,DNFlowObjectArg,DNFlowTwoObjects,DNFlowBool,
 DNFlowUInt,DNFlowObjectBool,DNFlowSignedSlot,DNFlowFactoryFrame } DNFlowKind;
typedef struct { const char *className,*selector,*encoding;DNFlowKind kind;
 IMP original,replacement;BOOL installed,refused; } DNFlowSpec;
// Vendor signatures below read from pinned genuine DuoNavi104 metadata.
// Apple signatures require exact target runtime ABI, never inferred by name.
static DNFlowSpec dnFlowSpecs[]={
 {"CBBridgeManagerDashboard","startBridging:withCompletion:","v32@0:8@16@?24",DNFlowTwoObjects,0,0,0,0},
 {"CBBridgeManagerDashboard","prepareHomeScreenForBridge:","v24@0:8@?16",DNFlowObjectArg,0,0,0,0},
 {"CBBridgeManagerDashboard","closeOfficialTopApp:","v24@0:8@?16",DNFlowObjectArg,0,0,0,0},
 {"CBBridgeManagerDashboard","requestActivation:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"CBBridgeManagerDashboard","requestDismiss","v16@0:8",DNFlowVoid,0,0,0,0},
 {"CBBridgeManagerDashboard","stopBridging","v16@0:8",DNFlowVoid,0,0,0,0},
 {"CBBridgeManagerDashboard","handleStateDict:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"CBBridgeManagerDashboard","bridgeDidActivate:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"CBBridgeManagerDashboard","bridgeDidDeactivate","v16@0:8",DNFlowVoid,0,0,0,0},
 {"CBBridgeManagerDashboard","setAppDockActiveBundleID:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"CBBridgeManagerDashboard","setHomeButtonInApp:","v20@0:8B16",DNFlowBool,0,0,0,0},
 {"CBBridgeManager","requestStateChangeWithDictionary:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"CBBridgeManager","notifyStateUpdated","v16@0:8",DNFlowVoid,0,0,0,0},
 // ABI from the SHA-pinned genuine DuoNavi 1.0.4 ObjC method table.
 // These are observation-only: the original IMP is forwarded exactly once.
 {"CBBridgeManager","appForBundleIdentifier:frame:","@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24",DNFlowFactoryFrame,0,0,0,0},
 {"CBBridgeManager","showAppPickerForSlot:","v24@0:8q16",DNFlowSignedSlot,0,0,0,0},
 {"CBBridgeManager","deactivateCurrentApp","v16@0:8",DNFlowVoid,0,0,0,0},
 {"DBRootStatusBarViewController","homeButtonUp:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"CARRootStatusBarViewController","homeButtonUp:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"DBMutableWorkspaceStateChangeRequest","activateApplication:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"DBMutableWorkspaceStateChangeRequest","deactivateApplication:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"CARMutableWorkspaceStateChangeRequest","activateApplication:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"CARMutableWorkspaceStateChangeRequest","deactivateApplication:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"DBWorkspace","requestStateChange:","v24@0:8@16",DNFlowObjectArg,0,0,0,0},
 {"DBStatusBarHomeButton","setDisplayState:","v24@0:8Q16",DNFlowUInt,0,0,0,0},
 {"DBAppDockViewController","setActiveBundleIdentifier:animated:","v28@0:8@16B24",DNFlowObjectBool,0,0,0,0},
 {"DBDashboardHomeViewController","iconManager:launchIcon:","v32@0:8@16@24",DNFlowTwoObjects,0,0,0,0},
 {"DBDashboardHomeViewController","iconManager:launchIconForIconView:","v32@0:8@16@24",DNFlowTwoObjects,0,0,0,0}
};
static atomic_uint_fast64_t dnFlowSequence;
static _Thread_local BOOL dnFlowObserving;
static NSString *DNFlowIdentity(id object) {
 return object?[NSString stringWithFormat:@"%@:%p",NSStringFromClass(object_getClass(object)),(__bridge void *)object]:@"nil";
}
static BOOL DNFlowExact(id object,const char *name,const char *type) {
 Method m=object?class_getInstanceMethod(object_getClass(object),sel_registerName(name)):NULL;
 return m&&!strcmp(method_getTypeEncoding(m),type);
}
static id DNFlowGet(id object,const char *name) {
 if(!DNFlowExact(object,name,"@16@0:8"))return nil;
 @try {return ((id(*)(id,SEL))objc_msgSend)(object,sel_registerName(name));}
 @catch(__unused NSException *e){return nil;}
}
static id DNFlowBoolGet(id object,const char *name) {
 @try {
  if(DNFlowExact(object,name,"B16@0:8"))return @(((BOOL(*)(id,SEL))objc_msgSend)(object,sel_registerName(name)));
  if(DNFlowExact(object,name,"c16@0:8"))return @(((signed char(*)(id,SEL))objc_msgSend)(object,sel_registerName(name))!=0);
 } @catch(__unused NSException *e){}
 return @"unavailable";
}
static NSDictionary *DNFlowArgument(id object) {
 @try {
 NSMutableDictionary *d=[NSMutableDictionary dictionaryWithObject:DNFlowIdentity(object) forKey:@"identity"];
 if([object isKindOfClass:NSString.class] && [object length]<180)d[@"string"]=object;
 // Never dump dictionaries, descriptions, blocks, URLs, license data or app content.
 if([object isKindOfClass:NSDictionary.class]) {
  for(NSString *key in @[@"bundleIdentifier",@"bundleID",@"bundleId",@"bundle",@"activated",@"pending",@"isSplit"]) {
   id value=object[key];
   if([value isKindOfClass:NSNumber.class] || ([value isKindOfClass:NSString.class]&&[value length]<180))d[key]=value;
  }
 } else {
  id bundle=DNFlowGet(object,"bundleIdentifier");
  if([bundle isKindOfClass:NSString.class]&&[bundle length]<180)d[@"bundleIdentifier"]=bundle;
 }
 return d;
 } @catch(__unused NSException *e){return @{@"unavailable":@"argument-read-failed"};}
}
static void DNFlowRecord(DNFlowSpec *spec,id receiver,uint64_t call,NSString *phase,NSDictionary *args) {
 if(!call || dnFlowObserving)return;
 dnFlowObserving=YES;
 @try {
  NSMutableDictionary *d=[NSMutableDictionary dictionaryWithDictionary:args?:@{}];
  d[@"call"]=@(call);d[@"phase"]=phase;d[@"selector"]=@(spec->selector);
  d[@"declared_owner"]=@(spec->className);d[@"receiver"]=DNFlowIdentity(receiver);
  d[@"main"]=@(NSThread.isMainThread);
  if(NSThread.isMainThread)d[@"snapshot"]=DNFlowSnapshot(receiver);
  DNLog(@"home_flow_call",d);
 } @catch(__unused NSException *e){} // Observer failure must not affect original.
 @finally {dnFlowObserving=NO;}
}
static uint64_t DNFlowEnter(DNFlowSpec *spec,id receiver,NSDictionary *args) {
 if(dnFlowObserving)return 0;
 uint64_t n=atomic_fetch_add(&dnFlowSequence,1)+1;
 if(n>10000)return 0;
 DNFlowRecord(spec,receiver,n,@"enter",args);return n;
}
static void DNFlowExit(DNFlowSpec *spec,id receiver,uint64_t call,BOOL returned) {
 DNFlowRecord(spec,receiver,call,returned?@"return":@"throw-unwind",nil);
 if(!call || !NSThread.isMainThread ||
    (strcmp(spec->selector,"homeButtonUp:") && strcmp(spec->selector,"bridgeDidActivate:") &&
     strcmp(spec->selector,"bridgeDidDeactivate") && strcmp(spec->selector,"handleStateDict:")))return;
 // Do not retain native receiver/controller ownership after the intercepted call.
 __weak id weakReceiver=receiver;
 for(NSNumber *delay in @[@50,@250,@1000])dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
   (int64_t)(delay.doubleValue*NSEC_PER_MSEC)),dispatch_get_main_queue(),^{
    DNFlowRecord(spec,weakReceiver,call,[NSString stringWithFormat:@"after-%@ms",delay],nil);
 });
}
static IMP DNFlowMakeWrapper(DNFlowSpec *s) {
 SEL sel=sel_registerName(s->selector);
 switch(s->kind) {
 case DNFlowVoid:return imp_implementationWithBlock(^(id r){
  uint64_t c=DNFlowEnter(s,r,nil);BOOL done=NO;
  @try{((void(*)(id,SEL))s->original)(r,sel);done=YES;}@finally{DNFlowExit(s,r,c,done);}
 });
 case DNFlowObjectArg:return imp_implementationWithBlock(^(id r,id a){
  uint64_t c=DNFlowEnter(s,r,@{@"argument":DNFlowArgument(a)});BOOL done=NO;
  @try{((void(*)(id,SEL,id))s->original)(r,sel,a);done=YES;}@finally{DNFlowExit(s,r,c,done);}
 });
 case DNFlowTwoObjects:return imp_implementationWithBlock(^(id r,id a,id b){
  uint64_t c=DNFlowEnter(s,r,@{@"argument1":DNFlowArgument(a),@"argument2":@{@"identity":DNFlowIdentity(b)}});BOOL done=NO;
  @try{((void(*)(id,SEL,id,id))s->original)(r,sel,a,b);done=YES;}@finally{DNFlowExit(s,r,c,done);}
 });
 case DNFlowBool:return imp_implementationWithBlock(^(id r,BOOL a){
  uint64_t c=DNFlowEnter(s,r,@{@"bool":@(a)});BOOL done=NO;
  @try{((void(*)(id,SEL,BOOL))s->original)(r,sel,a);done=YES;}@finally{DNFlowExit(s,r,c,done);}
 });
 case DNFlowUInt:return imp_implementationWithBlock(^(id r,NSUInteger a){
  uint64_t c=DNFlowEnter(s,r,@{@"displayState":@(a)});BOOL done=NO;
  @try{((void(*)(id,SEL,NSUInteger))s->original)(r,sel,a);done=YES;}@finally{DNFlowExit(s,r,c,done);}
 });
 case DNFlowObjectBool:return imp_implementationWithBlock(^(id r,id a,BOOL b){
  uint64_t c=DNFlowEnter(s,r,@{@"argument":DNFlowArgument(a),@"animated":@(b)});BOOL done=NO;
  @try{((void(*)(id,SEL,id,BOOL))s->original)(r,sel,a,b);done=YES;}@finally{DNFlowExit(s,r,c,done);}
 });
 case DNFlowSignedSlot:return imp_implementationWithBlock(^(id r,NSInteger slot){
  uint64_t c=DNFlowEnter(s,r,@{@"slotIndex":@(slot)});BOOL done=NO;
  @try{((void(*)(id,SEL,NSInteger))s->original)(r,sel,slot);done=YES;}
  @finally{DNFlowExit(s,r,c,done);}
 });
 case DNFlowFactoryFrame:return imp_implementationWithBlock(^id(id r,id bundle,CGRect frame){
  uint64_t c=DNFlowEnter(s,r,@{@"argument":DNFlowArgument(bundle),
     @"frame":NSStringFromCGRect(frame)});BOOL done=NO;
  id host=nil;
  @try{host=((id(*)(id,SEL,id,CGRect))s->original)(r,sel,bundle,frame);done=YES;}
  @finally{
   if(done)DNFlowRecord(s,r,c,@"factory-return",
        @{@"factoryResult":DNFlowIdentity(host)});
   DNFlowExit(s,r,c,done);
  }
  return host;
 });
 }return NULL;
}
static BOOL DNFlowInstallOne(DNFlowSpec *s,Class cls,DNFlowHookAPI hook) {
 if(s->installed)return YES;
 if(s->refused || !cls || !hook)return NO;
 SEL selector=sel_registerName(s->selector);Method method=class_getInstanceMethod(cls,selector);
 if(!method)return NO; // Retry when original vendor/Apple class appears.
 // Only declared owners, so superclass alias installations cannot double-hook.
 unsigned count=0;Method *list=class_copyMethodList(cls,&count);BOOL declared=NO;
 for(unsigned i=0;i<count;i++)if(method_getName(list[i])==selector)declared=YES;
 free(list);if(!declared)return NO;
 if(strcmp(method_getTypeEncoding(method),s->encoding)) {
  s->refused=YES;DNLog(@"home_flow_hook_refused",@{@"class":@(s->className),@"selector":@(s->selector),
   @"expected":@(s->encoding),@"actual":@(method_getTypeEncoding(method))});return NO;
 }
 s->replacement=DNFlowMakeWrapper(s);if(!s->replacement)return NO;
 hook(cls,selector,s->replacement,&s->original);s->installed=s->original!=NULL;
 DNLog(@"home_flow_hook_ready",@{@"class":@(s->className),@"selector":@(s->selector),
  @"encoding":@(s->encoding),@"installed":@(s->installed)});
 return s->installed;
}
static void DNHomeFlowInstall(void) {
 DNFlowHookAPI hook=(DNFlowHookAPI)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 for(unsigned i=0;i<sizeof(dnFlowSpecs)/sizeof(dnFlowSpecs[0]);i++)
  DNFlowInstallOne(&dnFlowSpecs[i],NSClassFromString(@(dnFlowSpecs[i].className)),hook);
}
