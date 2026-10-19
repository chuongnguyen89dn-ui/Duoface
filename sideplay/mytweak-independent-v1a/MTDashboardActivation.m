// Independent CarPlay Dashboard activation via the native workspace.
#import "MTDashboardActivation.h"
#import "MTDashboardWorkspace.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <notify.h>

static NSString *const kControlPath=@"/var/mobile/Library/Preferences/com.duoface.mytweak.dashboard-control.plist";
static NSString *const kStatusPath=@"/var/mobile/Library/Preferences/com.duoface.mytweak.dashboard-control-status.plist";
static NSString *const kShell=@"com.duoface.mytweak.shell";
static const char *kNotify="com.duoface.mytweak.dashboard.activate";
static NSString *const kHome=@"com.apple.CarPlay.dashboard";
static NSString *const kLog=@"/var/mobile/Library/Logs/MyTweakActivation.log";

static void MTAEvent(NSString *event,NSString *detail) {
    NSString *message=[NSString stringWithFormat:@"[MyTweakActivation] event=%@ %@\n",event,detail?:@""];
    NSLog(@"%@",message);
    [[NSFileManager defaultManager] createDirectoryAtPath:[kLog stringByDeletingLastPathComponent]
        withIntermediateDirectories:YES attributes:nil error:nil];
    NSFileHandle *f=[NSFileHandle fileHandleForWritingAtPath:kLog];
    if (!f) {
        [[NSFileManager defaultManager] createFileAtPath:kLog contents:nil attributes:nil];
        f=[NSFileHandle fileHandleForWritingAtPath:kLog];
    }
    @try {
        [f seekToEndOfFile];
        [f writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
        [f closeFile];
    } @catch(NSException *ex) {
        NSLog(@"[MyTweakActivation] log-write-error=%@",NSStringFromClass(ex.class));
    }
}
static void MTAStatus(NSString *action,NSString *result) {
    [@{@"Action":action?:@"unknown",
       @"Result":result?:@"unknown",
       @"Timestamp":@(NSDate.date.timeIntervalSince1970)}
      writeToFile:kStatusPath atomically:YES];
    MTAEvent(action,result);
}
static BOOL MTACallKnownNativeActivation(id workspace,NSString *bundleID) {
    if (!workspace || ![NSThread isMainThread] ||
        ![bundleID isEqualToString:kHome] && ![bundleID isEqualToString:kShell])
        return NO;
    Class controllerClass=NSClassFromString(@"DBApplicationController");
    Class requestClass=NSClassFromString(@"DBMutableWorkspaceStateChangeRequest");
    SEL shared=NSSelectorFromString(@"sharedInstance");
    SEL lookup=NSSelectorFromString(@"applicationWithBundleIdentifier:");
    SEL activate=NSSelectorFromString(@"activateApplication:");
    SEL change=NSSelectorFromString(@"requestStateChange:");
    if (!controllerClass || !requestClass || ![controllerClass respondsToSelector:shared] ||
        ![workspace respondsToSelector:change]) {
        MTAStatus(@"native-activation",@"unsupported-workspace-or-app-controller");
        return NO;
    }
    @try {
        id controller=((id(*)(id,SEL))objc_msgSend)(controllerClass,shared);
        if (!controller || ![controller respondsToSelector:lookup]) {
            MTAStatus(@"native-activation",@"application-controller-no-lookup");return NO;
        }
        id app=((id(*)(id,SEL,id))objc_msgSend)(controller,lookup,bundleID);
        if (!app) {
            MTAStatus(@"native-activation",@"application-not-in-native-carplay-roster");
            return NO;
        }
        id request=[requestClass new];
        if (!request || ![request respondsToSelector:activate]) {
            MTAStatus(@"native-activation",@"request-class-unavailable");return NO;
        }
        // System-owned request. Does NOT change Dock window or Apple scene hierarchy.
        ((void(*)(id,SEL,id))objc_msgSend)(request,activate,app);
        ((void(*)(id,SEL,id))objc_msgSend)(workspace,change,request);
        MTAStatus(@"native-activation",[bundleID isEqualToString:kHome]?
                  @"home-requested-await-system":@"own-shell-requested-await-system");
        return YES;
    } @catch(NSException *e) {
        MTAStatus(@"native-activation",[NSString stringWithFormat:@"exception-%@",NSStringFromClass(e.class)]);
        return NO;
    }
}
static void MTASend(NSString *action) {
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])
        return;
    if (![action isEqualToString:@"home"] && ![action isEqualToString:@"shell"])
        return;
    // Fixed actions only; never accept arbitrary bundle-ID execution from IPC.
    NSDictionary *message=@{@"Action":action,@"Timestamp":@(NSDate.date.timeIntervalSince1970)};
    if (![message writeToFile:kControlPath atomically:YES]) {
        MTAEvent(@"send-failed",@"cross-process-control-not-writable");return;
    }
    notify_post(kNotify);
    MTAEvent(@"sent",action);
}
@implementation MTDashboardActivation
+ (void)requestNativeHomeFromSpringBoard { MTASend(@"home"); }
+ (void)requestDuoFaceShellFromSpringBoard { MTASend(@"shell"); }
+ (void)installListenerInCarPlay {
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        int token=0;
        int status=notify_register_dispatch(kNotify,&token,dispatch_get_main_queue(),^(int token) {
            (void)token;
            NSDictionary *message=[NSDictionary dictionaryWithContentsOfFile:kControlPath];
            NSString *action=[message[@"Action"] isKindOfClass:NSString.class]?message[@"Action"]:nil;
            NSNumber *t=message[@"Timestamp"];
            NSTimeInterval age=[t respondsToSelector:@selector(doubleValue)] ?
                NSDate.date.timeIntervalSince1970-t.doubleValue:INFINITY;
            if (age<0 || age>4 || !action) {
                MTAStatus(@"notification",@"invalid-or-stale-command");return;
            }
            id workspace=[MTDashboardWorkspace liveDashboardWorkspace];
            if (!workspace) {
                MTAStatus(action,@"no-live-dashboard-workspace");return;
            }
            if ([action isEqualToString:@"home"])
                MTACallKnownNativeActivation(workspace,kHome);
            else if ([action isEqualToString:@"shell"])
                MTACallKnownNativeActivation(workspace,kShell);
            else MTAStatus(@"notification",@"unknown-command");
        });
        MTAEvent(@"listener-installed",[NSString stringWithFormat:@"status=%d",status]);
    });
}
@end
