// MyTweak v1a -- passive SpringBoard/CarPlay capability evidence.
// No private setter, no scene creation, no host launch, no UIWindow creation.
#import "MTPreflight.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <fcntl.h>
#import <unistd.h>

static void MTV1ALog(NSString *event, NSString *detail) {
    NSString *line = [NSString stringWithFormat:
        @"[MyTweakV1A] event=%@ %@", event ?: @"unknown", detail ?: @""];
    NSLog(@"%@", line);
    int fd = open("/var/mobile/Library/Logs/MyTweakV1A.log",
                  O_WRONLY | O_APPEND | O_CREAT, 0644);
    if (fd >= 0) {
        NSData *bytes = [[line stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd, bytes.bytes, bytes.length);
        close(fd);
    }
}

static id MTV1ARead(id target, NSString *selector) {
    SEL sel = NSSelectorFromString(selector);
    if (!target || ![target respondsToSelector:sel]) return nil;
    // These private selectors are version-dependent. Never interpret a scalar as id.
    BOOL classTarget=class_isMetaClass(object_getClass(target));
    Method method=classTarget ? class_getClassMethod((Class)target,sel)
                              : class_getInstanceMethod([target class],sel);
    char returnType[16]={0};
    if (method) method_getReturnType(method,returnType,sizeof(returnType));
    if (!method || returnType[0]!='@') {
        MTV1ALog(@"read-skipped", [NSString stringWithFormat:
            @"selector=%@ nonObjectReturn=%s",selector,method ? returnType : "missing"]);
        return nil;
    }
    @try {
        return ((id (*)(id, SEL))objc_msgSend)(target, sel);
    } @catch (NSException *exception) {
        MTV1ALog(@"read-exception", [NSString stringWithFormat:
            @"selector=%@ type=%@", selector, NSStringFromClass([exception class])]);
        return nil;
    }
}
static void MTV1ASelector(NSString *className, NSString *selector, BOOL classMethod) {
    Class cls = NSClassFromString(className);
    SEL sel = NSSelectorFromString(selector);
    Method method = cls ? (classMethod ? class_getClassMethod(cls,sel) :
                           class_getInstanceMethod(cls,sel)) : NULL;
    const char *signature = method ? method_getTypeEncoding(method) : NULL;
    NSString *encoding = signature ? [NSString stringWithUTF8String:signature] : @"missing";
    MTV1ALog(@"selector", [NSString stringWithFormat:
        @"class=%@ kind=%@ sel=%@ encoding=%@",
        className, classMethod ? @"+" : @"-", selector, encoding]);
}
static void MTV1ADockViews(UIWindow *window) {
    NSMutableArray<UIView *> *queue=[NSMutableArray array];
    // Start at all window children; the AppDock may be a sibling of root.view.
    // Never force a lazy root view to load just for diagnostics.
    [queue addObjectsFromArray:window.subviews];
    NSUInteger inspected=0, found=0;
    while (queue.count && inspected<400) {
        UIView *view=queue.lastObject;
        [queue removeLastObject];
        inspected++;
        NSString *name=NSStringFromClass([view class]);
        if ([name containsString:@"AppDock"]) {
            found++;
            MTV1ALog(@"dock-view", [NSString stringWithFormat:
                @"class=%@ frame=%@",name,NSStringFromCGRect(view.frame)]);
        }
        [queue addObjectsFromArray:view.subviews];
    }
    MTV1ALog(@"dock-scan", [NSString stringWithFormat:
        @"viewsInspected=%lu appDockViews=%lu truncated=%d",
        (unsigned long)inspected,(unsigned long)found,queue.count>0]);
}

@interface MTPreflight ()
@property(nonatomic,assign) BOOL started;
@end
@implementation MTPreflight
+ (instancetype)shared {
    static MTPreflight *diagnostic;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ diagnostic=[MTPreflight new]; });
    return diagnostic;
}
+ (void)startReadOnlyDiagnostics {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self startReadOnlyDiagnostics]; });
        return;
    }
    MTPreflight *probe=[self shared];
    if (probe.started) return;
    probe.started=YES;
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"]) {
        MTV1ALog(@"injection-denied", @"not-SpringBoard");
        return;
    }
    NSNotificationCenter *nc=NSNotificationCenter.defaultCenter;
    [nc addObserver:probe selector:@selector(screenChanged:)
               name:UISceneDidActivateNotification object:nil];
    [nc addObserver:probe selector:@selector(screenChanged:)
               name:UISceneDidDisconnectNotification object:nil];
    MTV1ALog(@"diagnostic-start", @"readOnly=1 windowCreates=0 sceneLaunches=0");
    [probe snapshot];
}
- (void)screenChanged:(NSNotification *)note {
    MTV1ALog(@"screen-notification",note.name);
    [self snapshot];
}
- (void)snapshot {
    // Selector existence != ABI compatibility; log type encoding for manual review.
    MTV1ASelector(@"SBApplicationController",@"sharedInstance",YES);
    MTV1ASelector(@"SBApplicationController",@"applicationWithBundleIdentifier:",NO);
    MTV1ASelector(@"SBDeviceApplicationSceneEntity",@"initWithApplicationForMainDisplay:",NO);
    MTV1ASelector(@"SBDeviceApplicationSceneEntity",@"newEntityWithApplicationForMainDisplay:",YES);
    MTV1ASelector(@"SBDeviceApplicationSceneEntity",@"defaultEntityWithApplicationForMainDisplay:",YES);
    MTV1ASelector(@"SBAppViewController",@"initWithIdentifier:andApplicationSceneEntity:",NO);
    MTV1ASelector(@"SBAppViewController",@"setRequestedMode:",NO);
    MTV1ASelector(@"SBAppViewController",@"invalidate",NO);
    MTV1ASelector(@"SBAppViewController",@"sceneHandle",NO);
    MTV1ASelector(@"AVExternalDevice",@"currentCarPlayExternalDevice",YES);
    MTV1ASelector(@"AVExternalDevice",@"screenIDs",NO);
    MTV1ASelector(@"CADisplay",@"displays",YES);
    MTV1ASelector(@"CADisplay",@"uniqueId",NO);
    MTV1ASelector(@"FBSDisplayConfiguration",@"initWithCADisplay:isMainDisplay:",NO);
    MTV1ASelector(@"UIRootSceneWindow",@"initWithDisplayConfiguration:",NO);
    MTV1ASelector(@"DBAppDockViewController",@"init",NO);
    MTV1ASelector(@"CARAppDockViewController",@"init",NO);

    id device=MTV1ARead(NSClassFromString(@"AVExternalDevice"),@"currentCarPlayExternalDevice");
    id screenIDs=MTV1ARead(device,@"screenIDs");
    id displays=MTV1ARead(NSClassFromString(@"CADisplay"),@"displays");
    BOOL matched=NO;
    if ([screenIDs isKindOfClass:NSArray.class] && [displays isKindOfClass:NSArray.class]) {
        for (id display in (NSArray *)displays) {
            id displayID=MTV1ARead(display,@"uniqueId");
            if (displayID && [(NSArray *)screenIDs containsObject:displayID]) {
                matched=YES; break;
            }
        }
    }
    MTV1ALog(@"carplay-display", [NSString stringWithFormat:
        @"external=%d screenIDCount=%lu displayCount=%lu matched=%d connectedScenes=%lu",
        device!=nil,
        [screenIDs isKindOfClass:NSArray.class] ? (unsigned long)[screenIDs count] : 0UL,
        [displays isKindOfClass:NSArray.class] ? (unsigned long)[displays count] : 0UL,
        matched,(unsigned long)UIApplication.sharedApplication.connectedScenes.count]);

    // UIApplication.windows is deprecated on iOS15+ and misses multi-scene ownership.
    // This passive inventory is limited to windows exposed by connected UIWindowScenes.
    NSMutableOrderedSet<UIWindow *> *seen=[NSMutableOrderedSet orderedSet];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class]) {
            [seen addObjectsFromArray:((UIWindowScene *)scene).windows];
        }
    }
    NSArray<UIWindow *> *windows=seen.array;
    MTV1ALog(@"window-count",[NSString stringWithFormat:@"count=%lu",
        (unsigned long)windows.count]);
    NSUInteger inspected=0;
    for (UIWindow *window in windows) {
        if (++inspected>40) break; // no unbounded traversal inside SpringBoard
        NSString *sceneClass=window.windowScene ?
            NSStringFromClass([window.windowScene class]) : @"none";
        MTV1ALog(@"window",[NSString stringWithFormat:
            @"class=%@ sceneClass=%@ external=%d hidden=%d level=%.1f bounds=%@ root=%@",
            NSStringFromClass([window class]),sceneClass,
            window.screen!=UIScreen.mainScreen,window.hidden,
            (double)window.windowLevel,NSStringFromCGRect(window.bounds),
            window.rootViewController ?
                NSStringFromClass([window.rootViewController class]) : @"none"]);
        if (window.screen!=UIScreen.mainScreen) MTV1ADockViews(window);
    }
    MTV1ALog(@"snapshot-end", @"no-window-or-scene-mutated");
}
@end
