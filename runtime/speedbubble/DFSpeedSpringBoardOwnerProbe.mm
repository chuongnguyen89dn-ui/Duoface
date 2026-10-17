// DuoFace native12 speed6zzowner1 -- READ-ONLY SpringBoard split owner probe.
// No UIWindow creation, no ObjC method hooking, no class initialization.
// The existing CarPlayApp DuoFaceSpeedHUD renderer remains byte-identical.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>
#import <stdio.h>
#import <unistd.h>

static NSData *DFOwnerLastState=nil;
static NSTimeInterval DFOwnerLastWrite=0;
static NSUInteger DFOwnerTickCount=0;
static NSString *const DFOwnerLogPath=@"/var/mobile/Library/Logs/DuoFaceSpeedOwner-SpringBoard.jsonl";

static NSString *DFOwnerTypeName(id obj) {
    return obj ? NSStringFromClass([obj class]) : @"nil";
}
static NSString *DFOwnerClassImage(Class cls) {
    const char *path=cls ? class_getImageName(cls):NULL;
    if (!path) return @"nil";
    NSString *file=[NSString stringWithUTF8String:path].lastPathComponent;
    return file.length ? file : @"unknown";
}
static NSNumber *DFOwnerFinite(CGFloat n) {
    return @(isfinite(n) ? (double)n : -1.0);
}
static NSArray *DFOwnerDimensions(CGRect r) {
    return @[DFOwnerFinite(r.size.width), DFOwnerFinite(r.size.height)];
}
static id DFOwnerClassSend(Class cls, NSString *name) {
    SEL sel=NSSelectorFromString(name);
    if (!cls || ![cls respondsToSelector:sel]) return nil;
    return ((id(*)(id,SEL))objc_msgSend)(cls,sel);
}
static id DFOwnerSend(id target, NSString *name) {
    SEL sel=NSSelectorFromString(name);
    if (!target || ![target respondsToSelector:sel]) return nil;
    return ((id(*)(id,SEL))objc_msgSend)(target,sel);
}
static BOOL DFOwnerBool(id target, NSString *name) {
    SEL sel=NSSelectorFromString(name);
    if (!target || ![target respondsToSelector:sel]) return NO;
    return ((BOOL(*)(id,SEL))objc_msgSend)(target,sel);
}
static NSDictionary *DFOwnerWindowInfo(id native, Class cbClass) {
    if (!native) return @{@"class":@"nil",@"native_CBWindow":@NO};
    BOOL cb=cbClass && [native isKindOfClass:cbClass];
    if (!cb) return @{@"class":DFOwnerTypeName(native),@"native_CBWindow":@NO};
    id rootObj=DFOwnerSend(native,@"rootWindow");
    UIWindow *root=[rootObj isKindOfClass:UIWindow.class] ? (UIWindow *)rootObj:nil;
    id rootVC=DFOwnerSend(native,@"rootViewController");
    UIView *content=[DFOwnerSend(native,@"contentView") isKindOfClass:UIView.class]
                   ? DFOwnerSend(native,@"contentView"):nil;
    UIView *controller=[rootVC isKindOfClass:UIViewController.class]
                     ? [rootVC viewIfLoaded]:nil;
    NSString *role=root.windowScene.session.role ?: @"nil";
    BOOL ext=root && root.screen && root.screen!=UIScreen.mainScreen;
    BOOL linkedContent=root && content && content.window==root;
    BOOL linkedController=root && controller && controller.window==root;
    BOOL desc=NO;
    for(UIView *p=content; p && controller; p=p.superview)
        if (p==controller) {desc=YES;break;}
    return @{
        @"class":DFOwnerTypeName(native),
        @"native_CBWindow":@YES,
        @"is_visible":@(DFOwnerBool(native,@"isVisible")),
        @"root_class":DFOwnerTypeName(rootObj),
        @"root_hidden":@(root ? root.hidden : YES),
        @"root_alpha":DFOwnerFinite(root?root.alpha:-1),
        @"root_bounds":DFOwnerDimensions(root?root.bounds:CGRectZero),
        @"scene_role":role,
        @"external_screen":@(ext),
        @"root_has_windowScene":@(root && root.windowScene!=nil),
        @"content_class":DFOwnerTypeName(content),
        @"controller_class":DFOwnerTypeName(controller),
        @"content_window_is_root":@(linkedContent),
        @"controller_window_is_root":@(linkedController),
        @"content_descends_controller":@(desc),
        @"controller_bounds":DFOwnerDimensions(controller?controller.bounds:CGRectZero)
    };
}
static void DFOwnerWrite(NSDictionary *record) {
    NSData *out=[NSJSONSerialization dataWithJSONObject:record options:0 error:nil];
    if (!out) return;
    // Native12 does not guarantee the log directory already exists.
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Library/Logs"
                               withIntermediateDirectories:YES
                                                attributes:nil error:nil];
    FILE *fp=fopen(DFOwnerLogPath.fileSystemRepresentation,"a");
    if(!fp) {
        NSString *alternative=[NSTemporaryDirectory()
                    stringByAppendingPathComponent:@"DuoFaceSpeedOwner-SpringBoard.jsonl"];
        fp=fopen(alternative.fileSystemRepresentation,"a");
    }
    if(fp) {fwrite(out.bytes,1,out.length,fp);fputc('\n',fp);fclose(fp);}
    NSLog(@"[DuoFaceSpeedOwnerProbe] %@ %@",record[@"stage"],record[@"reason"]);
}
static void DFOwnerPoll(void) {
    if(!NSThread.isMainThread) return;
    ++DFOwnerTickCount;
    Class mgrClass=NSClassFromString(@"CBBridgeManager");
    Class cbClass=NSClassFromString(@"CBWindow");
    // This class method is an existing singleton getter; unlike sharedInstance,
    // it does not create/start/activate the DuoFace bridge.
    id mgr=DFOwnerClassSend(mgrClass,@"sharedInstanceIfExists");
    id mgrWindow=DFOwnerSend(mgr,@"window");
    id global=DFOwnerClassSend(cbClass,@"activeCarPlayWindow");
    NSDictionary *owner=DFOwnerWindowInfo(mgrWindow,cbClass);
    NSDictionary *active=DFOwnerWindowInfo(global,cbClass);
    NSDictionary *state=@{
        @"native_manager_class_present":@(mgrClass!=nil),
        @"native_window_class_present":@(cbClass!=nil),
        @"manager_image":DFOwnerClassImage(mgrClass),
        @"window_class_image":DFOwnerClassImage(cbClass),
        @"manager_instance_class":DFOwnerTypeName(mgr),
        @"manager_window":owner,
        @"activeCarPlayWindow":active
    };
    NSData *signature=[NSJSONSerialization dataWithJSONObject:state
                                    options:NSJSONWritingSortedKeys error:nil];
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(signature && [signature isEqualToData:DFOwnerLastState]
       && now-DFOwnerLastWrite<15.0) return;
    DFOwnerLastState=[signature copy];DFOwnerLastWrite=now;
    NSString *reason=mgrWindow ? @"manager_window_present"
                    : mgr ? @"manager_exists_no_window" : @"manager_not_created";
    DFOwnerWrite(@{
        @"time":@(now),@"process":NSProcessInfo.processInfo.processName ?: @"nil",
        @"pid":@(getpid()),@"stage":@"SPRINGBOARD_NATIVE12_OWNER_PROBE",
        @"reason":reason,@"tick":@(DFOwnerTickCount),@"state":state,
        @"read_only":@YES, @"created_window":@NO
    });
}
@interface DFOwnerPollingDriver:NSObject
-(void)onTimer:(NSTimer *)timer;
@end
@implementation DFOwnerPollingDriver
-(void)onTimer:(NSTimer *)timer { (void)timer;DFOwnerPoll(); }
@end
static DFOwnerPollingDriver *dfOwnerDriver=nil;
__attribute__((constructor)) static void DFOwnerProbeStart(void) {
    if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])
        return;
    dispatch_async(dispatch_get_main_queue(), ^{
        DFOwnerWrite(@{
          @"time":@(NSDate.date.timeIntervalSince1970),
          @"process":@"SpringBoard", @"pid":@(getpid()),
          @"stage":@"SPRINGBOARD_OWNER_PROBE_LOADED",
          @"reason":@"read_only_no_hooks_or_overlay",
          @"read_only":@YES,@"created_window":@NO
        });
        dfOwnerDriver=[DFOwnerPollingDriver new];
        NSTimer *timer=[NSTimer timerWithTimeInterval:1.0
                        target:dfOwnerDriver selector:@selector(onTimer:)
                        userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
        DFOwnerPoll();
    });
}
