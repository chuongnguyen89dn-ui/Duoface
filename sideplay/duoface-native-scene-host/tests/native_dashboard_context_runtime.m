// Imports actual context/preparation/exit policy. Controlled OS graph only;
// passing this test does not claim an actual CarPlay navigation destination.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <string.h>
static NSMutableArray *logs;
static void DF144Log(NSString *s,NSString *detail){[logs addObject:[s stringByAppendingFormat:@" %@",detail?:@""]];}
typedef void (*DF144Hook)(Class,SEL,IMP,IMP *);
static Class TestClass(const char *name) {
 if(!strcmp(name,"UIApplication"))return objc_getClass("DFTestCarApplication");
 if(!strcmp(name,"UIScreen"))return objc_getClass("DFTestCarScreen");
 if(!strcmp(name,"DBDashboardWorkspaceOwner"))return objc_getClass("DFTestDashboardOwner");
 if(!strcmp(name,"DBWorkspace"))return objc_getClass("DFTestDashboardWorkspace");
 if(!strcmp(name,"DBMutableWorkspaceStateChangeRequest"))return objc_getClass("DFTestWorkspaceRequest");
 return objc_getClass(name);
}
#define objc_getClass TestClass
#import "../DF151WorkspaceOwnerCapture.h"
#import "../DFNativeDashboardContext.h"
#import "../DF152NativeWorkspacePrepare.h"
#import "../DFNativeHomeExitPolicy.h"
#undef objc_getClass
static id phoneScreen,dashboard,library;
static BOOL fallbackGetter;
@interface DFTestCarScreen:NSObject
+ (id)mainScreen;
@end
@implementation DFTestCarScreen
+ (id)mainScreen{return phoneScreen;}
@end
@interface DFTestCarApplication:NSObject
+ (id)sharedApplication;
- (id)_currentDashboard;
- (id)currentDashboard;
- (id)sharedApplicationLibrary;
@end
@implementation DFTestCarApplication
+ (id)sharedApplication{static id app;if(!app)app=[self new];return app;}
- (id)_currentDashboard{return fallbackGetter?nil:dashboard;}
- (id)currentDashboard{return dashboard;}
- (id)sharedApplicationLibrary{return library;}
@end
@interface DFTestNode:NSObject
@property(nonatomic,strong) id viewIfLoaded,window,screen,parentViewController;
@end
@implementation DFTestNode
@end
@interface DFTestDashboardOwner:NSObject
@end
@implementation DFTestDashboardOwner
@end
@interface DFTestState:NSObject
@property(nonatomic,copy) NSString *activeBundleIdentifier;
@end
@implementation DFTestState
@end
@interface DFTestWorkspaceRequest:NSObject
@property(nonatomic,strong) id deactivated;
@property(nonatomic,copy) void (^completionHandler)(void);
- (void)deactivateApplication:(id)application;
@end
@implementation DFTestWorkspaceRequest
- (void)deactivateApplication:(id)application{self.deactivated=application;}
@end
@interface DFTestDashboardWorkspace:NSObject
@property(nonatomic,strong) DFTestState *state;
@property(nonatomic,strong) DFTestWorkspaceRequest *last;
@property(nonatomic) NSUInteger requests;
@property(nonatomic) BOOL complete;
- (void)requestStateChange:(id)request;
@end
@implementation DFTestDashboardWorkspace
- (void)requestStateChange:(id)request {
 self.last=request;++self.requests;
 if(self.complete && self.last.completionHandler)self.last.completionHandler();
}
@end
@interface DFTestDashboard:NSObject
@property(nonatomic,strong) id workspace,rootViewController,scene;
@property(nonatomic,copy) NSString *sceneBundle;
@property(nonatomic) BOOL showingApp;
- (id)_foregroundActiveScene;
- (id)_activeBundleIdentifierForScene:(id)scene;
@end
@implementation DFTestDashboard
- (id)_foregroundActiveScene{return self.scene;}
- (id)_activeBundleIdentifierForScene:(id)scene{return scene==self.scene?self.sceneBundle:nil;}
@end
@interface DFTestApplicationInfo:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@end
@implementation DFTestApplicationInfo
@end
@interface DFTestApplicationLibrary:NSObject
@property(nonatomic,strong) id app;
- (id)applicationInfoForBundleIdentifier:(id)bundle;
@end
@implementation DFTestApplicationLibrary
- (id)applicationInfoForBundleIdentifier:(id)bundle {
 return [bundle isEqual:[self.app bundleIdentifier]]?self.app:nil;
}
@end
#define CHECK(x) do{if(!(x)){NSLog(@"FAIL %d %s logs=%@",__LINE__,#x,logs);return 1;}}while(0)
static void Pump(NSTimeInterval seconds){[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];}
int main(void){@autoreleasepool {
 logs=[NSMutableArray new];phoneScreen=[NSObject new];id carScreen=[NSObject new];
 DFTestNode *root=[DFTestNode new],*grid=[DFTestNode new],*view=[DFTestNode new],*window=[DFTestNode new];
 root.viewIfLoaded=view;view.window=window;window.screen=carScreen;
 grid.viewIfLoaded=view;grid.parentViewController=root;
 DFTestDashboardWorkspace *workspace=[DFTestDashboardWorkspace new];workspace.state=[DFTestState new];workspace.complete=YES;
 DFTestDashboardOwner *owner=[DFTestDashboardOwner new];DF151DashboardOwner=owner;DF151DashboardWorkspace=workspace;
 DFTestDashboard *native=[DFTestDashboard new];native.rootViewController=root;native.workspace=workspace;dashboard=native;
 // Reproduce the real Log25 failure without modifying a production guard.
 id missing=nil;CHECK(!DF151SafeObjectGetter(grid,"workspace",&missing));
 CHECK(DFResolveNativeDashboard(grid,YES,@"actual-grid")==native);
 DF151WorkspaceSnapshot(@"snapshot",@"com.apple.mobilesafari",@"car",native);
 (void)&DF151StartCapture; // test does not install OS hooks
 fallbackGetter=YES;CHECK(DFResolveNativeDashboard(grid,YES,@"fallback")==native);fallbackGetter=NO;
 id otherWorkspace=[NSObject new];native.workspace=otherWorkspace;
 CHECK(!DFResolveNativeDashboard(grid,YES,@"wrong-workspace"));native.workspace=workspace;
 id wrongOwner=[NSObject new];DF151DashboardOwner=wrongOwner;CHECK(!DFResolveNativeDashboard(grid,YES,@"wrong-owner"));DF151DashboardOwner=owner;
 window.screen=phoneScreen;CHECK(!DFResolveNativeDashboard(grid,YES,@"phone-main"));window.screen=carScreen;
 grid.parentViewController=nil;CHECK(!DFResolveNativeDashboard(grid,YES,@"unrelated-grid"));
 CHECK(DFResolveNativeDashboard(grid,NO,@"native-dock-external-screen")==native);grid.parentViewController=root;
 // A verified chooser is already prepared: no artificial native deactivation.
 __block int continued=0;
 native.showingApp=NO;
 DF152PrepareThenContinue(@"chooser",@"com.apple.mobilesafari",@"car",native,^{++continued;});
 CHECK(continued==1 && workspace.requests==0);
 CHECK([[logs componentsJoinedByString:@"\n"] containsString:@"native-chooser-ready"]);
 // Native official app must match both real scene and captured workspace state.
 DFTestApplicationInfo *music=[DFTestApplicationInfo new];music.bundleIdentifier=@"com.apple.Music";
 DFTestApplicationLibrary *lib=[DFTestApplicationLibrary new];lib.app=music;library=lib;
 native.showingApp=YES;native.scene=[NSObject new];native.sceneBundle=music.bundleIdentifier;workspace.state.activeBundleIdentifier=music.bundleIdentifier;
 DF152PrepareThenContinue(@"official",@"com.apple.mobilesafari",@"car",native,^{++continued;});
 CHECK(continued==2 && workspace.requests==1 && workspace.last.deactivated==music);
 Pump(.3);CHECK(continued==2); // real completion + fallback exactly once
 native.sceneBundle=@"wrong.bundle";
 DF152PrepareThenContinue(@"mismatch",@"com.apple.mobilesafari",@"car",native,^{++continued;});
 CHECK(continued==3 && workspace.requests==1);
 native.sceneBundle=music.bundleIdentifier;workspace.complete=NO;
 DF152PrepareThenContinue(@"cancelled",@"com.apple.mobilesafari",@"car",native,^{++continued;});
 CHECK(continued==3 && workspace.requests==2);
 DF152RevokeNativePreparation();workspace.last.completionHandler();Pump(.3);CHECK(continued==3);
 // Home terminates bridge, not restoration of a stale previous in-app state0.
 CHECK(DFNativeHomeRestoredBundle(@"native-home-stop",@"previous.app")==nil);
 CHECK(DFNativeHomeRestoredState(@"native-home-stop",0)==1);
 CHECK(DFNativeHomeRestoredBundle(@"native-Home-exit",@"previous.app")==nil);
 CHECK(DFNativeHomeRestoredState(@"native-Home-exit",0)==1);
 CHECK([DFNativeHomeRestoredBundle(@"replacement-request",@"previous.app") isEqual:@"previous.app"]);
 CHECK(DFNativeHomeRestoredState(@"replacement-request",0)==0);
 puts("NATIVE_DASHBOARD_NOT_GRID_WORKSPACE_FOREGROUND_REQUEST_ONCE_CANCEL_AND_HOME_EXIT_POLICY_PASS");
 return 0;
}}
