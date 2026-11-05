// Executes the shipped native-launch helper with Foundation fake receivers.
// This proves object flow, ABI refusals and cancellation, not a physical
// CarPlay launch, native map rendering or navigation continuity.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "../DFNativeMapLaunchRuntime.h"
#import "../DFNativeMapOwnedBasePolicy.h"
#import "../../duoface-native-scene-host/DFCarPlayOwnerSelection.h"
#include <stdlib.h>
#include <string.h>

static NSUInteger checks,lookupCalls,launchCalls,eventCalls,handleCalls,providerCalls;
static NSUInteger trapCalls,guardCalls;
static id nativeApplication,nativeLibrary,nativeInfo,nativeDeclaration,nativeDashboard;
static id nativeWorkspace,nativeOwner,nativeScreen,lastLaunchInput,lastEventContext,lastEvent;
static NSString *requestID,*throwStage;
static NSMutableArray<NSString *> *order;
static Class applicationType,libraryType,infoType,declarationType,launchType,eventType;
static uint64_t homeGeneration,lastEventType;
static BOOL homeHooksReady,requestCurrent,settingsWereNil;
static BOOL sessionRevoked;
static BOOL homeFromPresentationGetter;
static NSUInteger latePresentationMutation;
static NSTimeInterval fixtureNow;
static NSMutableDictionary *sessionPulse,*boundRecord,*visibleCandidate;
static NSInteger launchResultMode,eventResultMode,providerMode;
static void (^factoryCallback)(void);
static void (^handleCallback)(void);

static void check(BOOL condition,NSString *message) {
 checks++;
 if(!condition){NSLog(@"NATIVE_MAP_LAUNCH_FAIL %@",message);abort();}
}
static void maybeThrow(NSString *stage) {
 if([throwStage isEqual:stage])
  @throw [NSException exceptionWithName:@"DFLaunchTestException" reason:stage userInfo:nil];
}
@interface DFLaunchTestView:NSObject
@property(nonatomic,weak) id window;
@property(nonatomic,weak) id superview;
@property(nonatomic,assign,getter=isHidden) BOOL hidden;
@property(nonatomic,assign) double alpha;
@end
@implementation DFLaunchTestView
@end
@interface DFLaunchTestController:NSObject
@property(nonatomic,strong) id viewIfLoaded;
@property(nonatomic,weak) id parentViewController;
@property(nonatomic,copy) NSArray *childViewControllers;
@property(nonatomic,strong) id presentedViewController;
@property(nonatomic,strong) id currentBaseViewController;
@end
static DFLaunchTestController *nativeRoot;
@implementation DFLaunchTestController
@synthesize currentBaseViewController=_currentBaseViewController;
@synthesize presentedViewController=_presentedViewController;
- (instancetype)init {if((self=[super init]))_childViewControllers=@[];return self;}
- (id)currentBaseViewController {
 if(homeFromPresentationGetter){homeFromPresentationGetter=NO;homeGeneration++;}
 return _currentBaseViewController;
}
- (id)presentedViewController {
 if(self==nativeRoot && latePresentationMutation) {
  NSUInteger mutation=latePresentationMutation;latePresentationMutation=0;
  if(mutation==1)nativeRoot.currentBaseViewController=[NSObject new];
  if(mutation==2)homeFromPresentationGetter=YES;
  if(mutation==3)requestCurrent=NO;
 }
 return _presentedViewController;
}
@end
@interface DFLaunchTestHome:DFLaunchTestController
@end
@implementation DFLaunchTestHome
@end
@interface DFLaunchTestSceneController:DFLaunchTestController
@property(nonatomic,strong) id applicationInfo;
@end
@implementation DFLaunchTestSceneController
@end
static DFLaunchTestHome *nativeHome;
static DFLaunchTestView *nativeWindow,*rootView,*homeView;

@interface DFLaunchTestApplication:NSObject
+ (id)sharedApplication;
- (id)sharedApplicationLibrary;
@end
@implementation DFLaunchTestApplication
+ (id)sharedApplication {maybeThrow(@"application");return nativeApplication;}
- (id)sharedApplicationLibrary {maybeThrow(@"library");return nativeLibrary;}
@end
@interface DFLaunchTestLibrary:NSObject
- (id)applicationInfoForBundleIdentifier:(id)bundle;
@end
@implementation DFLaunchTestLibrary
- (id)applicationInfoForBundleIdentifier:(id)bundle {
 lookupCalls++;[order addObject:@"lookup"];maybeThrow(@"lookup");
 check([bundle isKindOfClass:NSString.class],@"lookup receives exact bundle string");
 return nativeInfo;
}
@end
@interface DFLaunchTestDeclaration:NSObject
@property(nonatomic,copy) NSString *value;
- (id)bundleIdentifier;
@end
@implementation DFLaunchTestDeclaration
- (id)bundleIdentifier {maybeThrow(@"declaration");return self.value;}
@end
@interface DFLaunchTestInfo:NSObject
@property(nonatomic,copy) NSString *value;
- (id)bundleIdentifier;
- (id)carPlayDeclaration;
@end
@implementation DFLaunchTestInfo
- (id)bundleIdentifier {maybeThrow(@"info");return self.value;}
- (id)carPlayDeclaration {maybeThrow(@"declaration-getter");return nativeDeclaration;}
@end
static id createLaunchInfo(Class cls,id info) {
 launchCalls++;[order addObject:@"launch"];lastLaunchInput=info;
 maybeThrow(@"launch");
 if(launchResultMode==1)return nil;
 if(launchResultMode==2)return [NSObject new];
 if(launchResultMode==3)return cls;
 return [cls new];
}
@interface DFLaunchTestLaunchInfo:NSObject
+ (id)launchInfoForApplication:(id)info;
@end
@implementation DFLaunchTestLaunchInfo
+ (id)launchInfoForApplication:(id)info {return createLaunchInfo(self,info);}
@end
@interface DFLaunchTestFallbackInfo:NSObject
+ (id)launchInfoForApplication:(id)info withActivationSettings:(id)settings;
@end
@implementation DFLaunchTestFallbackInfo
+ (id)launchInfoForApplication:(id)info withActivationSettings:(id)settings {
 settingsWereNil=settings==nil;return createLaunchInfo(self,info);
}
@end
static id createEvent(Class cls,uint64_t type,id context) {
 eventCalls++;[order addObject:@"event"];lastEventType=type;lastEventContext=context;
 maybeThrow(@"event");if(factoryCallback)factoryCallback();
 if(eventResultMode==1)return nil;
 if(eventResultMode==2)return [NSObject new];
 if(eventResultMode==3)return cls;
 return [cls new];
}
@interface DFLaunchTestEvent64:NSObject
+ (id)eventWithType:(int64_t)type context:(id)context;
@end
@implementation DFLaunchTestEvent64
+ (id)eventWithType:(int64_t)type context:(id)context{return createEvent(self,(uint64_t)type,context);}
@end
@interface DFLaunchTestEventU64:NSObject
+ (id)eventWithType:(uint64_t)type context:(id)context;
@end
@implementation DFLaunchTestEventU64
+ (id)eventWithType:(uint64_t)type context:(id)context{return createEvent(self,type,context);}
@end
@interface DFLaunchTestEvent32:NSObject
+ (id)eventWithType:(int32_t)type context:(id)context;
@end
@implementation DFLaunchTestEvent32
+ (id)eventWithType:(int32_t)type context:(id)context{return createEvent(self,(uint32_t)type,context);}
@end
@interface DFLaunchTestEventU32:NSObject
+ (id)eventWithType:(uint32_t)type context:(id)context;
@end
@implementation DFLaunchTestEventU32
+ (id)eventWithType:(uint32_t)type context:(id)context{return createEvent(self,type,context);}
@end
@interface DFLaunchTestDashboard:NSObject
- (void)handleEvent:(id)event;
@end
@implementation DFLaunchTestDashboard
- (void)handleEvent:(id)event {
 handleCalls++;[order addObject:@"handle"];lastEvent=event;
 maybeThrow(@"handle");if(handleCallback)handleCallback();
}
@end
static Class classNamed(const char *name) {
 if(!strcmp(name,"UIApplication"))return applicationType;
 if(!strcmp(name,"FBSApplicationLibrary"))return libraryType;
 if(!strcmp(name,"DBApplicationInfo"))return infoType;
 if(!strcmp(name,"CRCarPlayAppDeclaration"))return declarationType;
 if(!strcmp(name,"DBApplicationLaunchInfo"))return launchType;
 if(!strcmp(name,"DBEvent"))return eventType;
 if(!strcmp(name,"DBDashboardHomeViewController"))return DFLaunchTestHome.class;
 if(!strcmp(name,"DBApplicationSceneViewController"))return DFLaunchTestSceneController.class;
 if(!strcmp(name,"UIViewController"))return DFLaunchTestController.class;
 if(!strcmp(name,"UIView"))return DFLaunchTestView.class;
 return objc_getClass(name);
}
static DFNativeMapLaunchContext *contextSnapshot(void) {
 DFNativeMapLaunchContext *context=[DFNativeMapLaunchContext new];
 context.dashboard=nativeDashboard;context.workspace=nativeWorkspace;context.owner=nativeOwner;
 context.root=nativeRoot;context.window=nativeWindow;context.screen=nativeScreen;
 context.homeGeneration=homeGeneration;context.homeHooksReady=homeHooksReady;
 context.physicalSession=DFNativeMapFreshLaunchSession(sessionPulse,sessionRevoked,fixtureNow);
 if(DFNativeMapOwnedBaseRecordMatches(sessionPulse,boundRecord,visibleCandidate,sessionRevoked,fixtureNow) &&
    nativeRoot.currentBaseViewController==visibleCandidate[@"Controller"])
  context.ownedBase=visibleCandidate[@"Controller"];
 context.requestID=requestID;return context;
}
static DFNativeMapLaunchContext *contextProvider(id root,id window,NSString *rid,NSString **reason) {
 (void)root;(void)window;(void)rid;providerCalls++;
 maybeThrow(@"provider");
 if(providerMode==1){if(reason)*reason=@"test-context-missing";return nil;}
 if(providerMode==2)return (id)[NSObject new];
 DFNativeMapLaunchContext *context=contextSnapshot();
 if(providerMode==3)context.requestID=NSUUID.UUID.UUIDString;
 return context;
}
static uint64_t readHomeGeneration(void){return homeGeneration;}
static void reset(void) {
 lookupCalls=launchCalls=eventCalls=handleCalls=providerCalls=guardCalls=trapCalls=0;
 homeGeneration=7;homeHooksReady=YES;requestCurrent=YES;settingsWereNil=NO;
 sessionRevoked=NO;fixtureNow=1000;homeFromPresentationGetter=NO;latePresentationMutation=0;
 launchResultMode=eventResultMode=providerMode=0;
 factoryCallback=nil;handleCallback=nil;throwStage=nil;
 lastLaunchInput=nil;lastEventContext=nil;lastEvent=nil;lastEventType=0;
 order=[NSMutableArray new];requestID=NSUUID.UUID.UUIDString;
 sessionPulse=[@{@"Version":@1,@"Active":@YES,@"Session":NSUUID.UUID.UUIDString,
    @"HostSceneID":@"host-scene-fixture",@"Timestamp":@(fixtureNow)} mutableCopy];
 boundRecord=nil;visibleCandidate=nil;
 applicationType=DFLaunchTestApplication.class;libraryType=DFLaunchTestLibrary.class;
 infoType=DFLaunchTestInfo.class;declarationType=DFLaunchTestDeclaration.class;
 launchType=DFLaunchTestLaunchInfo.class;eventType=DFLaunchTestEvent64.class;
 nativeApplication=[applicationType new];nativeLibrary=[libraryType new];
 nativeInfo=[infoType new];[(DFLaunchTestInfo *)nativeInfo setValue:@"com.apple.Maps"];
 nativeDeclaration=[declarationType new];[(DFLaunchTestDeclaration *)nativeDeclaration setValue:@"com.apple.Maps"];
 nativeDashboard=[DFLaunchTestDashboard new];nativeWorkspace=[NSObject new];
 nativeOwner=[NSObject new];nativeScreen=[NSObject new];
 nativeWindow=[DFLaunchTestView new];nativeWindow.window=nativeWindow;nativeWindow.alpha=1;
 rootView=[DFLaunchTestView new];rootView.window=nativeWindow;rootView.superview=nativeWindow;rootView.alpha=1;
 homeView=[DFLaunchTestView new];homeView.window=nativeWindow;homeView.superview=rootView;homeView.alpha=1;
 nativeRoot=[DFLaunchTestController new];nativeRoot.viewIfLoaded=rootView;
 nativeHome=[DFLaunchTestHome new];nativeHome.viewIfLoaded=homeView;nativeHome.parentViewController=nativeRoot;
 nativeRoot.childViewControllers=@[nativeHome];
}
static DFLaunchTestSceneController *useOwnedBase(void) {
 DFLaunchTestSceneController *base=[DFLaunchTestSceneController new];
 DFLaunchTestInfo *info=[DFLaunchTestInfo new];info.value=@"com.duoface.native.scenehost";
 base.applicationInfo=info;
 DFLaunchTestView *view=[DFLaunchTestView new];view.window=nativeWindow;
 view.superview=rootView;view.alpha=1;base.viewIfLoaded=view;
 base.parentViewController=nativeRoot;
 nativeRoot.childViewControllers=@[nativeHome,base];nativeRoot.currentBaseViewController=base;
 homeView.hidden=YES;
 boundRecord=[@{@"Session":sessionPulse[@"Session"],@"HostSceneID":sessionPulse[@"HostSceneID"],
     @"NativeSceneID":@"verified-native-duoface-scene",@"Controller":base} mutableCopy];
 visibleCandidate=[@{@"Bundle":@"com.duoface.native.scenehost",
     @"SceneID":boundRecord[@"NativeSceneID"],@"Controller":base} mutableCopy];
 return base;
}
static BOOL perform(DFNativeMapLaunchContext *expected,NSString *bundle,NSString **reason) {
 DFNativeMapLaunchRuntime runtime={classNamed,contextProvider,readHomeGeneration};
 return DFNativeMapDispatchLaunchUsingRuntime(bundle,expected?:contextSnapshot(),runtime,^{
  guardCalls++;maybeThrow(@"guard");return requestCurrent;
 },reason);
}
static void refused(NSString *label) {
 NSString *reason=nil;
 check(!perform(nil,@"com.apple.Maps",&reason),label);
 check(reason.length>0,[label stringByAppendingString:@" reports a reason"]);
 check(handleCalls==0,[label stringByAppendingString:@" sends no event"]);
 check(trapCalls==0,[label stringByAppendingString:@" never invokes mismatched ABI"]);
}
static id trap(id receiver,SEL selector,...) {
 (void)receiver;(void)selector;trapCalls++;abort();return nil;
}
static Class badMethod(Class superclass,BOOL isClass,const char *selector,const char *encoding) {
 static NSUInteger next=0;
 NSString *name=[NSString stringWithFormat:@"DFBadNativeLaunch%lu",(unsigned long)++next];
 Class cls=objc_allocateClassPair(superclass,name.UTF8String,0);
 check(cls!=Nil,@"fake subclass allocated");
 check(class_addMethod(isClass?object_getClass(cls):cls,sel_registerName(selector),(IMP)trap,encoding),
       @"fake mismatched method installed");
 objc_registerClassPair(cls);return cls;
}

int main(void){@autoreleasepool{
 for(NSString *bundle in @[@"com.apple.Maps",@"com.google.Maps",@"com.waze.iphone"]) {
  reset();[(DFLaunchTestInfo *)nativeInfo setValue:bundle];
  [(DFLaunchTestDeclaration *)nativeDeclaration setValue:bundle];NSString *reason=nil;
  check(perform(nil,bundle,&reason),@"each explicit supported native map submits once");
  check(lookupCalls==1 && launchCalls==1 && eventCalls==1 && handleCalls==1,@"one exact launch chain");
  check(lastLaunchInput==nativeInfo && [lastEventContext isKindOfClass:launchType] &&
        [lastEvent isKindOfClass:eventType] && lastEventType==4,@"genuine info -> launch-info -> event4 -> actual dashboard");
  check([order isEqual:@[@"lookup",@"launch",@"event",@"handle"]],@"native flow order preserved");
  check([reason isEqual:@"native-launch-event-submitted-awaiting-observed-scene"],@"submission never claims scene adoption");
 }
 reset();launchType=DFLaunchTestFallbackInfo.class;
 check(perform(nil,@"com.apple.Maps",NULL) && settingsWereNil,@"proven fallback passes exact info and nil activation settings");
 for(Class cls in @[DFLaunchTestEvent64.class,DFLaunchTestEventU64.class,DFLaunchTestEvent32.class,DFLaunchTestEventU32.class]) {
  reset();eventType=cls;
  check(perform(nil,@"com.apple.Maps",NULL) && lastEventType==4 && handleCalls==1,@"verified integer width uses correct typed call");
 }
 reset();check(!perform(nil,@"com.example.other",NULL) && !lookupCalls,@"unsupported bundle never reaches native library");
 reset();launchType=Nil;refused(@"missing native factory class");
 reset();applicationType=badMethod(applicationType,YES,"sharedApplication","q16@0:8");refused(@"wrong shared application return ABI");
 reset();applicationType=badMethod(applicationType,NO,"sharedApplicationLibrary","q16@0:8");nativeApplication=[applicationType new];refused(@"wrong library getter ABI");
 reset();libraryType=badMethod(libraryType,NO,"applicationInfoForBundleIdentifier:","@24@0:8q16");nativeLibrary=[libraryType new];refused(@"wrong lookup argument ABI");
 reset();nativeInfo=[badMethod(infoType,NO,"bundleIdentifier","q16@0:8") new];refused(@"wrong app bundle getter ABI");
 reset();nativeInfo=[badMethod(infoType,NO,"carPlayDeclaration","q16@0:8") new];[(DFLaunchTestInfo *)nativeInfo setValue:@"com.apple.Maps"];refused(@"wrong declaration getter ABI");
 reset();nativeDeclaration=[badMethod(declarationType,NO,"bundleIdentifier","q16@0:8") new];refused(@"wrong declaration bundle ABI");
 reset();launchType=badMethod(launchType,YES,"launchInfoForApplication:","q24@0:8@16");refused(@"wrong launch factory return ABI");
 reset();launchType=badMethod(launchType,YES,"launchInfoForApplication:","@24@0:8q16");refused(@"wrong launch app-info argument ABI");
 reset();launchType=badMethod(launchType,YES,"launchInfoForApplication:","@24@0:8@?16");refused(@"block app-info argument ABI refused");
 reset();launchType=badMethod(launchType,YES,"launchInfoForApplication:","@32@0:8@16@24");refused(@"extra native factory argument refused");
 reset();launchType=badMethod(DFLaunchTestFallbackInfo.class,YES,"launchInfoForApplication:withActivationSettings:","@32@0:8@16q24");refused(@"wrong fallback settings ABI");
 reset();launchType=badMethod(DFLaunchTestFallbackInfo.class,YES,"launchInfoForApplication:","q24@0:8@16");refused(@"present incompatible primary never silently falls back");
 reset();eventType=badMethod(eventType,YES,"eventWithType:context:","@32@0:8@16@24");refused(@"object event type cannot be treated as integer");
 reset();eventType=badMethod(eventType,YES,"eventWithType:context:","@32@0:8d16@24");refused(@"floating event type ABI refused");
 reset();eventType=badMethod(eventType,YES,"eventWithType:context:","@32@0:8q16q24");refused(@"scalar event context ABI refused");
 reset();eventType=badMethod(eventType,YES,"eventWithType:context:","@32@0:8q16@?24");refused(@"block event context ABI refused");
 reset();eventType=badMethod(eventType,YES,"eventWithType:context:","q32@0:8q16@24");refused(@"non-object event result ABI refused");
 reset();nativeDashboard=[badMethod(DFLaunchTestDashboard.class,NO,"handleEvent:","@24@0:8@16") new];refused(@"wrong dashboard return ABI");
 reset();nativeDashboard=[badMethod(DFLaunchTestDashboard.class,NO,"handleEvent:","v24@0:8q16") new];refused(@"wrong dashboard event argument ABI");
 reset();nativeApplication=[NSObject new];refused(@"wrong shared application object");
 reset();nativeLibrary=[NSObject new];refused(@"wrong library object");
 reset();nativeInfo=[NSObject new];refused(@"wrong native app-info object");
 reset();nativeInfo=nil;refused(@"native application is not installed in the actual library");
 reset();[(DFLaunchTestInfo *)nativeInfo setValue:@"com.google.Maps"];refused(@"lookup bundle differs from explicit selection");
 reset();nativeDeclaration=nil;refused(@"missing native CarPlay declaration");
 reset();nativeDeclaration=[NSObject new];refused(@"wrong declaration object");
 reset();[(DFLaunchTestDeclaration *)nativeDeclaration setValue:@"com.google.Maps"];refused(@"declaration bundle differs");
 for(NSInteger mode=1;mode<=3;mode++) {
  reset();launchResultMode=mode;refused(@"nil or wrong-class launch-info result");
  reset();eventResultMode=mode;refused(@"nil or wrong-class event result");
 }
 for(NSString *stage in @[@"application",@"library",@"lookup",@"info",@"declaration-getter",@"declaration",@"launch",@"event",@"provider",@"guard"]) {
  reset();throwStage=stage;refused([@"exception at " stringByAppendingString:stage]);
 }
 reset();throwStage=@"handle";NSString *reason=nil;
 check(!perform(nil,@"com.apple.Maps",&reason) && handleCalls==1 && eventCalls==1,
       @"throwing receiver is one attempted event, never internally retried");
 for(NSInteger mode=1;mode<=3;mode++){reset();providerMode=mode;refused(@"missing, wrong-class or wrong-request context provider result");}
 reset();homeHooksReady=NO;refused(@"Home cancellation hook unavailable");
 reset();homeGeneration=0;refused(@"invalid Home generation");
 reset();requestID=@"not-a-uuid";refused(@"invalid context request identity");
 reset();DFNativeMapLaunchContext *expected=contextSnapshot();homeGeneration++;
 check(!perform(expected,@"com.apple.Maps",NULL) && !lookupCalls && !handleCalls,@"Home before launch cancels before native lookup");
 reset();expected=contextSnapshot();nativeWorkspace=[NSObject new];
 check(!perform(expected,@"com.apple.Maps",NULL) && !handleCalls,@"workspace replacement cancels dispatch");
 reset();expected=contextSnapshot();nativeOwner=nil;
 check(!perform(expected,@"com.apple.Maps",NULL) && !handleCalls,@"expired weak owner never becomes live evidence");
 reset();factoryCallback=^{homeGeneration++;};refused(@"synchronous Home during factory cancels before event dispatch");
 reset();factoryCallback=^{nativeWorkspace=[NSObject new];};refused(@"factory reentry changing workspace cancels dispatch");
 reset();factoryCallback=^{sessionPulse[@"Session"]=NSUUID.UUID.UUIDString;};
 refused(@"physical session replacement during factory cancels dispatch");
 reset();requestCurrent=NO;refused(@"already cancelled request never invokes native factories");
 reset();factoryCallback=^{requestCurrent=NO;};refused(@"new request or deadline during factory cancels final dispatch");
 reset();DFNativeMapLaunchRuntime runtime={classNamed,contextProvider,readHomeGeneration};
 check(!DFNativeMapDispatchLaunchUsingRuntime(@"com.apple.Maps",contextSnapshot(),runtime,nil,NULL),
       @"a request guard is mandatory");
 runtime.homeGeneration=NULL;
 check(!DFNativeMapDispatchLaunchUsingRuntime(@"com.apple.Maps",contextSnapshot(),runtime,^{return YES;},NULL),
       @"a final pure Home generation reader is mandatory");

 // Presentation readiness is stricter than stable context. It is checked
 // only before dispatch, never by the context accessor used during adoption.
 reset();nativeRoot.currentBaseViewController=[NSObject new];refused(@"unrelated current native base is never forced past");
 reset();nativeRoot.presentedViewController=[NSObject new];refused(@"modal presentation blocks launch");
 reset();homeView.hidden=YES;refused(@"hidden Home is not ready");
 reset();rootView.alpha=0;refused(@"hidden Home ancestor is not ready");
 reset();nativeHome.parentViewController=nil;refused(@"Home must belong to actual dashboard ancestry");
 reset();nativeRoot.childViewControllers=@[];refused(@"missing actual Home is not ready");
 reset();DFLaunchTestHome *second=[DFLaunchTestHome new];second.viewIfLoaded=homeView;
 second.parentViewController=nativeRoot;nativeRoot.childViewControllers=@[nativeHome,second];refused(@"ambiguous visible Home is refused");
 reset();DFLaunchTestController *badRoot=[badMethod(DFLaunchTestController.class,NO,"currentBaseViewController","q16@0:8") new];
 badRoot.viewIfLoaded=rootView;badRoot.childViewControllers=@[nativeHome];nativeHome.parentViewController=badRoot;nativeRoot=badRoot;
 refused(@"current-base getter ABI must be verified before reading nil");
 reset();factoryCallback=^{nativeRoot.currentBaseViewController=[NSObject new];};
 refused(@"presentation change during native factories cancels dispatch");
 reset();factoryCallback=^{homeFromPresentationGetter=YES;};reason=nil;
 check(!perform(nil,@"com.apple.Maps",&reason) && eventCalls==1 && handleCalls==0 &&
       [reason isEqual:@"native-launch-home-generation-changed-before-event"],
       @"Home inside final presentation getter wins even with unchanged active pulse and no revoke file");
 reset();expected=contextSnapshot();handleCallback=^{nativeRoot.currentBaseViewController=[NSObject new];};
 check(perform(expected,@"com.apple.Maps",NULL) && handleCalls==1,@"real launch may create a target presentation");
 check(DFNativeMapLaunchContextsMatch(expected,contextProvider(nativeRoot,nativeWindow,requestID,NULL)),
       @"post-launch presentation does not invalidate stable ownership context");
 check(!perform(nil,@"com.apple.Maps",NULL) && handleCalls==1,@"new nonnil base prevents a second launch");

 // A fresh exact first-party native base is a second pre-dispatch mode. The
 // live-owner receipt predicate used here is the actual production policy.
 reset();DFLaunchTestSceneController *owned=useOwnedBase();expected=contextSnapshot();
 check(expected.ownedBase==owned && homeView.isHidden,@"owned base is captured while Home is hidden");
 check(perform(expected,@"com.apple.Maps",NULL) && handleCalls==1,
       @"exact freshly bound DuoFace currentBase launches selected map once");
 reset();useOwnedBase();boundRecord[@"Session"]=NSUUID.UUID.UUIDString;refused(@"owned base from another session refused");
 reset();useOwnedBase();boundRecord[@"HostSceneID"]=@"other-host";refused(@"owned base with changed host scene refused");
 reset();useOwnedBase();boundRecord[@"NativeSceneID"]=@"other-native";refused(@"owned base with changed native scene refused");
 reset();useOwnedBase();boundRecord[@"Controller"]=[DFLaunchTestSceneController new];refused(@"same-bundle different bound controller refused");
 reset();useOwnedBase();visibleCandidate[@"Bundle"]=@"com.google.Maps";refused(@"foreign current app never counts as owned DuoFace base");
 reset();owned=useOwnedBase();[(DFLaunchTestInfo *)owned.applicationInfo setValue:@"com.google.Maps"];
 refused(@"reused owned controller exposing another app is refused");
 reset();useOwnedBase();sessionPulse[@"Active"]=@NO;refused(@"inactive owned session refused");
 reset();useOwnedBase();sessionPulse[@"Version"]=@YES;refused(@"boolean cannot stand in for session version");
 reset();useOwnedBase();sessionPulse[@"Active"]=@1;refused(@"numeric one cannot stand in for session Active boolean");
 reset();useOwnedBase();sessionPulse[@"Timestamp"]=@YES;refused(@"boolean cannot stand in for session timestamp");
 reset();useOwnedBase();sessionPulse[@"Timestamp"]=@(fixtureNow-2.51);refused(@"stale owned session pulse refused");
 reset();useOwnedBase();sessionPulse[@"Timestamp"]=@(fixtureNow+0.01);refused(@"future owned session pulse refused");
 reset();useOwnedBase();sessionRevoked=YES;refused(@"Home-revoked owned session refused");
 reset();useOwnedBase();visibleCandidate=[DFOwnerUniqueDuoFaceCandidate(@[visibleCandidate,[visibleCandidate copy]]) mutableCopy];
 refused(@"two visible DuoFace candidates do not confer an owner");
 reset();owned=useOwnedBase();owned.parentViewController=nil;refused(@"owned controller outside actual root ancestry refused");
 reset();owned=useOwnedBase();DFLaunchTestView *otherWindow=[DFLaunchTestView new];
 ((DFLaunchTestView *)owned.viewIfLoaded).window=otherWindow;
 refused(@"owned controller on another or expired window refused");
 reset();owned=useOwnedBase();owned.presentedViewController=[NSObject new];refused(@"modal over owned base blocks launch");
 reset();useOwnedBase();factoryCallback=^{(void)useOwnedBase();};
 refused(@"different freshly verified owned base during factories is still refused");
 reset();factoryCallback=^{(void)useOwnedBase();};
 refused(@"Home-to-owned-base mode change during factories is refused");
 reset();useOwnedBase();factoryCallback=^{nativeRoot.currentBaseViewController=nil;homeView.hidden=NO;};
 refused(@"owned-base-to-Home mode change during factories is refused");
 reset();useOwnedBase();factoryCallback=^{sessionPulse[@"Timestamp"]=@(fixtureNow-3);};
 refused(@"owned session becomes stale before event dispatch");
 reset();useOwnedBase();factoryCallback=^{latePresentationMutation=1;};reason=nil;
 check(!perform(nil,@"com.apple.Maps",&reason) && eventCalls==1 && handleCalls==0 &&
       [reason isEqual:@"native-launch-base-changed-before-event"],
       @"late root presentation getter replacing owned base is caught by terminal base read");
 reset();useOwnedBase();factoryCallback=^{latePresentationMutation=2;};reason=nil;
 check(!perform(nil,@"com.apple.Maps",&reason) && eventCalls==1 && handleCalls==0 &&
       [reason isEqual:@"native-launch-home-generation-changed-before-event"],
       @"Home inside terminal base getter wins even when its revoke receipt is absent");
 reset();useOwnedBase();factoryCallback=^{latePresentationMutation=3;};reason=nil;
 check(!perform(nil,@"com.apple.Maps",&reason) && eventCalls==1 && handleCalls==0 &&
       [reason isEqual:@"native-launch-request-no-longer-current"],
       @"late presentation getter cancelling the request wins before event");
 reset();useOwnedBase();expected=contextSnapshot();handleCallback=^{
  nativeRoot.currentBaseViewController=[NSObject new];
 };
 check(perform(expected,@"com.apple.Maps",NULL) && handleCalls==1,@"owned base may be replaced by actual native event");
 DFNativeMapLaunchContext *after=contextProvider(nativeRoot,nativeWindow,requestID,NULL);
 check(after.ownedBase==nil && DFNativeMapLaunchContextsMatch(expected,after),
       @"owned base is pre-dispatch only and does not invalidate stable post-event session identity");
 check(!DFNativeMapDispatchLaunchGuarded(@"com.apple.Maps",expected,^{return YES;},NULL),
       @"shipped entry refuses a Foundation harness outside CarPlay");
 NSLog(@"DF_NATIVE_MAP_LAUNCH_RUNTIME_PASS assertions=%lu",(unsigned long)checks);
 return 0;
}}
