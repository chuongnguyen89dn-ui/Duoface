// DuoFace Diagnostic v1 — passive, SpringBoard-only iOS 16 rootless probe.
// Does not swizzle, hook, create windows, activate scenes, change settings,
// or collect user content, app identifiers, coordinates or URLs.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>
#import <stdio.h>
#import <sys/stat.h>
#import <unistd.h>

static NSString *const kDFDiagPath=@"/var/mobile/Library/Logs/DuoFaceDiagnostic-SpringBoard.jsonl";
static NSData *sDFDiagLastSignature=nil;
static NSTimeInterval sDFDiagLastWrite=0;
static NSUInteger sDFDiagPolls=0;

static id DFDiagGet(id obj, const char *selector) {
    SEL sel=sel_registerName(selector);
    return obj && [obj respondsToSelector:sel] ?
        ((id (*)(id,SEL))objc_msgSend)(obj,sel) : nil;
}
static BOOL DFDiagGetBool(id obj,const char *selector) {
    SEL sel=sel_registerName(selector);
    return obj && [obj respondsToSelector:sel] ?
        ((BOOL (*)(id,SEL))objc_msgSend)(obj,sel) : NO;
}
static NSString *DFDiagClassName(id obj) {
    return obj ? NSStringFromClass([obj class]) : @"nil";
}
static NSString *DFDiagImage(Class cls) {
    const char *path=cls ? class_getImageName(cls) : NULL;
    if(!path)return @"nil";
    NSString *value=[NSString stringWithUTF8String:path];
    return value.lastPathComponent ?: @"unknown";
}
static NSNumber *DFDiagNumber(CGFloat value) {
    return @(isfinite(value) ? (double)value : -1.0);
}
static NSArray *DFDiagSize(CGSize size) {
    return @[DFDiagNumber(size.width),DFDiagNumber(size.height)];
}
static NSDictionary *DFDiagWindow(id native, Class windowClass) {
    BOOL valid=native && windowClass && [native isKindOfClass:windowClass];
    id rootObject=valid ? DFDiagGet(native,"rootWindow") : nil;
    UIWindow *root=[rootObject isKindOfClass:UIWindow.class] ? rootObject : nil;
    id vcObject=valid ? DFDiagGet(native,"rootViewController") : nil;
    UIViewController *vc=[vcObject isKindOfClass:UIViewController.class] ? vcObject : nil;
    id contentObject=valid ? DFDiagGet(native,"contentView") : nil;
    UIView *content=[contentObject isKindOfClass:UIView.class] ? contentObject : nil;
    UIView *controller=vc.viewIfLoaded;
    id screen=root.screen;
    return @{
        @"class":DFDiagClassName(native),
        @"valid_CBWindow":@(valid),
        @"visible":@(valid && DFDiagGetBool(native,"isVisible")),
        @"root_class":DFDiagClassName(rootObject),
        @"root_bounds":DFDiagSize(root ? root.bounds.size : CGSizeZero),
        @"root_hidden":@(root ? root.hidden : YES),
        @"root_alpha":DFDiagNumber(root ? root.alpha : -1.0),
        @"external_screen":@(screen && screen != UIScreen.mainScreen),
        @"scene_role":root.windowScene.session.role ?: @"nil",
        @"view_controller_class":DFDiagClassName(vcObject),
        @"content_class":DFDiagClassName(contentObject),
        @"controller_attached":@(root && controller && controller.window==root),
        @"content_attached":@(root && content && content.window==root)
    };
}
static void DFDiagWrite(NSString *event, NSDictionary *details) {
    NSMutableDictionary *record=[@{
       @"time":@(NSDate.date.timeIntervalSince1970),
       @"pid":@(getpid()),
       @"process":NSProcessInfo.processInfo.processName ?: @"nil",
       @"event":event ?: @"unknown",
       @"diag_version":@"1",
       @"read_only":@YES
    } mutableCopy];
    if(details)[record addEntriesFromDictionary:details];
    NSData *encoded=[NSJSONSerialization dataWithJSONObject:record options:0 error:nil];
    if(!encoded)return;
    NSFileManager *fm=NSFileManager.defaultManager;
    [fm createDirectoryAtPath:@"/var/mobile/Library/Logs"
       withIntermediateDirectories:YES attributes:nil error:nil];
    // Keep a bounded diagnostic trail, rotating at 5 MiB.
    struct stat info={};
    if(stat(kDFDiagPath.fileSystemRepresentation,&info)==0 && info.st_size>5*1024*1024) {
        NSString *old=[kDFDiagPath stringByAppendingString:@".previous"];
        [fm removeItemAtPath:old error:nil];
        [fm moveItemAtPath:kDFDiagPath toPath:old error:nil];
    }
    FILE *fp=fopen(kDFDiagPath.fileSystemRepresentation,"a");
    if(!fp)return;
    fwrite(encoded.bytes,1,encoded.length,fp);
    fputc('\n',fp);
    fclose(fp);
}
static void DFDiagPoll(void) {
    if(!NSThread.isMainThread)return;
    ++sDFDiagPolls;
    Class managerClass=NSClassFromString(@"CBBridgeManager");
    Class windowClass=NSClassFromString(@"CBWindow");
    Class splitClass=NSClassFromString(@"CBBridgedSplitApp");
    id manager=DFDiagGet(managerClass,"sharedInstanceIfExists");
    id owner=DFDiagGet(manager,"window");
    id active=DFDiagGet(windowClass,"activeCarPlayWindow");
    id current=DFDiagGet(manager,"currentApp");
    id panes=DFDiagGet(current,"appViews");
    id currentView=DFDiagGet(current,"view");
    BOOL validOwner=owner && windowClass && [owner isKindOfClass:windowClass];
    NSString *stage=!managerClass ? @"MISSING_MANAGER_CLASS" :
        !manager ? @"MISSING_MANAGER_INSTANCE" :
        !owner ? @"MANAGER_EXISTS_NO_WINDOW" :
        !validOwner ? @"WRONG_WINDOW_CLASS" :
        @"MANAGER_WINDOW_PRESENT";
    NSUInteger connected=[UIScreen screens].count;
    NSDictionary *snapshot=@{
      @"stage":stage,
      @"manager_image":DFDiagImage(managerClass),
      @"window_image":DFDiagImage(windowClass),
      @"split_image":DFDiagImage(splitClass),
      @"manager_class":DFDiagClassName(manager),
      @"window":DFDiagWindow(owner,windowClass),
      @"active_window":DFDiagWindow(active,windowClass),
      @"current_app_class":DFDiagClassName(current),
      @"current_is_split":@(current && splitClass && [current isKindOfClass:splitClass]),
      @"current_view_class":DFDiagClassName(currentView),
      @"app_views_count":@([panes isKindOfClass:NSArray.class] ? [panes count] : -1),
      @"screen_count":@(connected)
    };
    NSData *signature=[NSJSONSerialization dataWithJSONObject:snapshot
        options:NSJSONWritingSortedKeys error:nil];
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    BOOL changed=signature && ![signature isEqualToData:sDFDiagLastSignature];
    if(changed || now-sDFDiagLastWrite>=10.0) {
        DFDiagWrite(changed ? @"STATE_CHANGED" : @"HEARTBEAT",
          @{@"state":snapshot,@"poll":@(sDFDiagPolls)});
        sDFDiagLastSignature=[signature copy];
        sDFDiagLastWrite=now;
    }
}
@interface DFDiagDriver:NSObject
- (void)onTimer:(NSTimer *)timer;
- (void)onUIKitEvent:(NSNotification *)note;
@end
@implementation DFDiagDriver
- (void)onTimer:(NSTimer *)timer {
    (void)timer;
    @autoreleasepool { DFDiagPoll(); }
}
- (void)onUIKitEvent:(NSNotification *)note {
    DFDiagWrite(@"UIKIT_NOTIFICATION",@{@"notification":note.name ?: @"nil"});
    DFDiagPoll();
}
@end
static DFDiagDriver *sDFDiagDriver=nil;
__attribute__((constructor)) static void DFDiagStart(void) {
    if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
    dispatch_async(dispatch_get_main_queue(), ^{
        DFDiagWrite(@"LOADED",@{
           @"reason":@"passive_poll_no_hooks_no_windows",
           @"springboard_only":@YES
        });
        sDFDiagDriver=[DFDiagDriver new];
        NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
        for(NSString *name in @[
            UIScreenDidConnectNotification,
            UIScreenDidDisconnectNotification,
            UIScreenModeDidChangeNotification,
            UIApplicationDidBecomeActiveNotification,
            UIApplicationWillResignActiveNotification,
            UIApplicationDidEnterBackgroundNotification,
            UIApplicationWillEnterForegroundNotification
        ]) {
            [center addObserver:sDFDiagDriver selector:@selector(onUIKitEvent:)
              name:name object:nil];
        }
        NSTimer *timer=[NSTimer timerWithTimeInterval:0.5
            target:sDFDiagDriver selector:@selector(onTimer:)
            userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
        DFDiagPoll();
    });
}
