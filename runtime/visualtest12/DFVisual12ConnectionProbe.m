// DuoFace VisualTest12: read-only connection mismatch telemetry.
// Substrate/ElleKit loads only into SpringBoard and the original DuoFaceUI app.
// Never swizzles, forces connection, opens applications or touches CarPlay scenes.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>

static NSString *DFV12Role(void) {
    NSString *bundle=[[NSBundle mainBundle].bundleIdentifier lowercaseString];
    if ([bundle isEqualToString:@"com.apple.springboard"]) return @"SpringBoard";
    if ([bundle isEqualToString:@"com.duoface.duofaceui"] ||
        [bundle isEqualToString:@"com.duonavi.app"]) return @"DuoFaceUI";
    return nil;
}
static id DFV12ObjCFlag(NSString *className, NSString *selectorName, BOOL classMethod) {
    Class cls=NSClassFromString(className);
    if (!cls) return @"NO_CLASS";
    SEL selector=NSSelectorFromString(selectorName);
    Method method=classMethod ? class_getClassMethod(cls,selector)
                              : class_getInstanceMethod(cls,selector);
    if (!method) return @"NO_METHOD";
    if (!classMethod) return @"INSTANCE_NEEDS_OWNER";
    const char *typ=method_getTypeEncoding(method);
    NSMethodSignature *signature=typ?[NSMethodSignature signatureWithObjCTypes:typ]:nil;
    if (!signature || signature.numberOfArguments != 2 ||
        !strchr("Bc",signature.methodReturnType[0]))
        return @"ABI_MISMATCH";
    // These class getters are read-only in the byte-pinned original host.
    BOOL (*sendBool)(id,SEL)=(BOOL (*)(id,SEL))objc_msgSend;
    return @(sendBool(cls,selector));
}
static id DFV12BridgeActivated(void) {
    Class bridge=NSClassFromString(@"CBBridgeManager");
    if (!bridge) return @"NO_CLASS";
    SEL existing=NSSelectorFromString(@"sharedInstanceIfExists");
    SEL active=NSSelectorFromString(@"activated");
    Method method=class_getClassMethod(bridge,existing);
    if (!method) return @"NO_SAFE_OWNER_GETTER";
    const char *typ=method_getTypeEncoding(method);
    NSMethodSignature *sig=typ?[NSMethodSignature signatureWithObjCTypes:typ]:nil;
    if (!sig || sig.numberOfArguments!=2 || sig.methodReturnType[0]!='@') return @"OWNER_ABI_MISMATCH";
    id (*sendId)(id,SEL)=(id (*)(id,SEL))objc_msgSend;
    id manager=sendId(bridge,existing); // never allocate a manager just to probe
    if (!manager) return @"NO_EXISTING_OWNER";
    Method state=class_getInstanceMethod([manager class],active);
    if (!state) return @"NO_ACTIVATED_METHOD";
    const char *s=method_getTypeEncoding(state);
    NSMethodSignature *encoding=s?[NSMethodSignature signatureWithObjCTypes:s]:nil;
    if (!encoding || encoding.numberOfArguments!=2 ||
        !strchr("Bc",encoding.methodReturnType[0])) return @"ACTIVATED_ABI_MISMATCH";
    BOOL (*sendBool)(id,SEL)=(BOOL (*)(id,SEL))objc_msgSend;
    return @(sendBool(manager,active));
}
static void DFV12Write(NSDictionary *item, NSString *role) {
    NSString *dir=@"/var/mobile/Documents/DuoFaceConnectionProbe";
    NSError *err=nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:YES
                                               attributes:nil error:&err];
    if (err) {
        NSLog(@"[DFVisual12ConnectionProbe] mkdir denied %@",err.localizedDescription);
        return;
    }
    NSString *path=[dir stringByAppendingPathComponent:
                     [role stringByAppendingString:@".jsonl"]];
    NSMutableData *line=[[NSJSONSerialization dataWithJSONObject:item
                                                         options:0 error:&err] mutableCopy];
    if (!line) {
        NSLog(@"[DFVisual12ConnectionProbe] JSON error %@",err.localizedDescription);
        return;
    }
    [line appendBytes:"\n" length:1];
    NSFileManager *manager=[NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        [manager createFileAtPath:path contents:nil attributes:nil];
    }
    NSFileHandle *handle=[NSFileHandle fileHandleForWritingAtPath:path];
    if (!handle) {
        NSLog(@"[DFVisual12ConnectionProbe] open file denied %@",path);
        return;
    }
    @try {
        [handle seekToEndOfFile];
        [handle writeData:line];
        [handle synchronizeFile];
    } @catch(NSException *exception) {
        NSLog(@"[DFVisual12ConnectionProbe] write error %@",exception.reason);
    } @finally {
        [handle closeFile];
    }
}
static void DFV12Snapshot(NSString *reason) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(),^{DFV12Snapshot(reason);});
        return;
    }
    NSString *role=DFV12Role();
    if (!role) return;
    NSArray<UIScreen *> *screens=[UIScreen screens];
    UIScreen *main=[UIScreen mainScreen];
    NSUInteger external=0;
    NSMutableArray *sizes=[NSMutableArray array];
    for(UIScreen *screen in screens) {
        if (screen!=main) external++;
        CGRect r=screen.bounds;
        [sizes addObject:[NSString stringWithFormat:@"%.0fx%.0f@%.1f%@",
                           r.size.width,r.size.height,screen.scale,
                           screen==main?@"-main":@"-external"]];
    }
    NSDictionary *item=@{
        @"unix_time_ms":@((long long)([NSDate date].timeIntervalSince1970*1000.0)),
        @"role":role,
        @"trigger":reason?:@"timer",
        @"screens_count":@(screens.count),
        @"external_screens_count":@(external),
        @"screen_geometry":sizes,
        @"cb_detector_class_connected":DFV12ObjCFlag(
            @"CBLicenseSyncManager",@"isCarPlayScreenConnected",YES),
        @"cb_detector_class_is_carplay_screen_available":@(
            class_getClassMethod(NSClassFromString(@"CBLicenseSyncManager"),
                                 NSSelectorFromString(@"isCarPlayScreen:"))!=NULL),
        @"cb_detector_instance_available":@(
            class_getInstanceMethod(NSClassFromString(@"CBLicenseSyncManager"),
                                    NSSelectorFromString(@"isCarPlayScreenConnected"))!=NULL),
        @"bridge_manager_activated":DFV12BridgeActivated(),
        @"dashboard_policy_signal_active":DFV12ObjCFlag(
            @"CBBridgeManagerDashboard",@"isDashboardPolicySignalActive",YES),
        @"dashboard_class_available":@(NSClassFromString(@"CBBridgeManagerDashboard")!=Nil)
    };
    DFV12Write(item,role);
    NSLog(@"[DFVisual12ConnectionProbe] %@ %@ screens=%lu external=%lu "
          "detector=%@ bridge=%@ policy=%@",
          role,reason,(unsigned long)screens.count,(unsigned long)external,
          item[@"cb_detector_class_connected"],item[@"bridge_manager_activated"],
          item[@"dashboard_policy_signal_active"]);
}
__attribute__((constructor)) static void DFV12ProbeStart(void) {
    @autoreleasepool {
        if (!DFV12Role()) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DFV12Snapshot(@"tweak-loaded");
            NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
            [nc addObserverForName:UIScreenDidConnectNotification object:nil queue:[NSOperationQueue mainQueue]
                       usingBlock:^(__unused NSNotification *n){DFV12Snapshot(@"UIScreenDidConnect");}];
            [nc addObserverForName:UIScreenDidDisconnectNotification object:nil queue:[NSOperationQueue mainQueue]
                       usingBlock:^(__unused NSNotification *n){DFV12Snapshot(@"UIScreenDidDisconnect");}];
            [nc addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue]
                       usingBlock:^(__unused NSNotification *n){DFV12Snapshot(@"app-became-active");}];
            __block NSUInteger count=0;
            [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:YES
                                            block:^(NSTimer *timer){
                DFV12Snapshot(@"periodic");
                if (++count>=90) [timer invalidate];
            }];
        });
    }
}
