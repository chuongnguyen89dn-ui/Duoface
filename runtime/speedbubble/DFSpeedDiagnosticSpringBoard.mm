// DuoFace read-only diagnostic for iOS 16 Dopamine rootless SpringBoard.
// Standalone source; NOT injected, built, or released until package wiring is verified.
// No method hooks, UIWindow creation, CarPlay activation, GPS, or app preference mutations.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <unistd.h>
#import <stdio.h>
static id DFDiagRead(id obj, SEL sel) {
    return obj && [obj respondsToSelector:sel] ? ((id(*)(id,SEL))objc_msgSend)(obj,sel) : nil;
}
static NSString *DFDiagName(id obj) { return obj ? NSStringFromClass([obj class]) : @"nil"; }
static void DFDiagEmit(NSString *event, NSDictionary *fields) {
    NSMutableDictionary *record=[@{@"timestamp":@([[NSDate date] timeIntervalSince1970]),
      @"pid":@(getpid()),@"event":event ?: @"unknown",
      @"process":[[NSProcessInfo processInfo] processName] ?: @"unknown"} mutableCopy];
    if(fields) [record addEntriesFromDictionary:fields];
    NSData *line=[NSJSONSerialization dataWithJSONObject:record options:0 error:nil];
    if(!line)return;
    const char *dir="/var/mobile/Library/Logs";
    [[NSFileManager defaultManager] createDirectoryAtPath:@(dir)
      withIntermediateDirectories:YES attributes:nil error:nil];
    FILE *fp=fopen("/var/mobile/Library/Logs/DuoFaceDiagnostic-SpringBoard.jsonl","a");
    if(fp){fwrite(line.bytes,1,line.length,fp);fputc('\n',fp);fclose(fp);}
}
static void DFDiagSnapshot(void) {
    Class managerClass=NSClassFromString(@"CBBridgeManager");
    Class windowClass=NSClassFromString(@"CBWindow");
    const char *origin=managerClass?class_getImageName(managerClass):NULL;
    id manager=DFDiagRead(managerClass,@selector(sharedInstanceIfExists));
    id bridge=DFDiagRead(manager,@selector(window));
    id current=DFDiagRead(manager,@selector(currentApp));
    id root=DFDiagRead(bridge,@selector(rootWindow));
    id screen=DFDiagRead(root,@selector(screen));
    BOOL external=screen && screen!=[UIScreen mainScreen];
    NSString *stage=!managerClass?@"NO_MANAGER_CLASS":
      !manager?@"NO_MANAGER":!bridge?@"NO_WINDOW":
      !windowClass || ![bridge isKindOfClass:windowClass]?@"WRONG_WINDOW_CLASS":
      !root?@"NO_ROOT":@"WINDOW_PRESENT";
    static NSString *last=nil;
    static NSUInteger repeats=0;
    NSString *signature=[NSString stringWithFormat:@"%@/%@/%@/%d",stage,
      DFDiagName(current),DFDiagName(root),external];
    BOOL changed=![last isEqualToString:signature];
    repeats++;
    if(changed || repeats>=20) {
        DFDiagEmit(changed?@"STATE_CHANGE":@"HEARTBEAT",@{
          @"stage":stage,@"manager_class":DFDiagName(manager),
          @"manager_image":origin?@(origin):@"nil",
          @"window_class":DFDiagName(bridge),
          @"current_app_class":DFDiagName(current),
          @"root_class":DFDiagName(root),
          @"external_screen":@(external),
          @"window_visible":@(bridge && [bridge respondsToSelector:@selector(isVisible)] ? ((BOOL(*)(id,SEL))objc_msgSend)(bridge,@selector(isVisible)) : NO),
          @"repeated_polls":@(repeats)});
        last=signature;repeats=0;
    }
}
@interface DFDiagTimer:NSObject
-(void)tick:(NSTimer *)timer;
@end
@implementation DFDiagTimer
-(void)tick:(NSTimer *)timer { (void)timer; DFDiagSnapshot(); }
@end
__attribute__((constructor)) static void DFDiagStart(void) {
    if(![[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"])return;
    dispatch_async(dispatch_get_main_queue(), ^{
        DFDiagEmit(@"DIAGNOSTIC_LOADED",@{@"version":@"1"});
        static DFDiagTimer *driver;
        driver=[DFDiagTimer new];
        NSTimer *timer=[NSTimer timerWithTimeInterval:0.5 target:driver
          selector:@selector(tick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        DFDiagSnapshot();
    });
}
