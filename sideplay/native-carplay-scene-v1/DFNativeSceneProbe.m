// Only observes existing CarPlay Dashboard owner. Never admits applications,
// constructs a window, displays a bar, repositions Apple's chrome or injects touch.
#import "DFNativeSceneContract.h"
#import <UIKit/UIKit.h>
#import <fcntl.h>
#import <unistd.h>
#import <math.h>
@interface DFNativeSceneProbe : NSObject
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,copy) NSString *session;
@property(nonatomic,copy) NSString *lastDescription;
@property(nonatomic,assign) NSUInteger ticks;
@end
@implementation DFNativeSceneProbe
static void DFProbeLog(NSString *message) {
    NSString *line=[NSString stringWithFormat:@"[DuoFaceNativeSceneJoin] %@\n",message];
    NSLog(@"%@",line);
    int fd=open("/var/mobile/Library/Logs/DuoFaceNativeSceneJoin.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0){NSData *d=[line dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);close(fd);}
}
+ (instancetype)shared {
    static DFNativeSceneProbe *o;
    static dispatch_once_t once;
    dispatch_once(&once,^{o=[self new];});return o;
}
- (void)start {
    if(self.timer || !NSThread.isMainThread)return;
    NSString *p=NSProcessInfo.processInfo.processName;
    if(![p isEqual:@"CarPlay"] && ![p isEqual:@"CarPlayApp"])return;
    self.session=NSUUID.UUID.UUIDString;
    DFProbeLog([NSString stringWithFormat:@"passive-start process=%@ version=0.0.1 no-ui-mutation",p]);
    self.timer=[NSTimer scheduledTimerWithTimeInterval:1.5 target:self
        selector:@selector(tick) userInfo:nil repeats:YES];
    [self tick];
}
- (void)tick {
    if(!NSThread.isMainThread)return;
    self.ticks++;
    CGRect full=CGRectNull, usable=CGRectNull;
    BOOL chrome=NO, dashboard=NO;
    UIWindow *dashboardWindow=nil;
    NSUInteger inspected=0;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:UIWindowScene.class] ||
           scene.activationState!=UISceneActivationStateForegroundActive)continue;
        UIWindowScene *ws=(UIWindowScene *)scene;
        if(ws.screen==UIScreen.mainScreen)continue;
        CGRect extent=ws.coordinateSpace.bounds;
        for(UIWindow *w in ws.windows){
            if(++inspected>64)break;
            if(!w.screen || w.screen!=ws.screen || w.hidden || w.alpha<0.95)continue;
            NSString *kind=NSStringFromClass(w.class);
            NSString *root=NSStringFromClass(w.rootViewController.class);
            if([root isEqual:@"DBDashboardRootViewController"] && !dashboardWindow){
                dashboard=YES;dashboardWindow=w;
                full=extent;
            }
            if([kind isEqual:@"DBDockWindow"] ||
               [kind isEqual:@"DBStatusBarWindow"]){
                CGRect b=[w convertRect:w.bounds toWindow:dashboardWindow];
                if(CGRectIsNull(b) || !isfinite(b.origin.x) || !isfinite(b.origin.y))continue;
                // Visibility is an observation, never a request to restore it.
                if(CGRectIntersectsRect(extent,b))chrome=YES;
            }
        }
        if(dashboard)break;
    }
    if(dashboardWindow){
        UIEdgeInsets i=dashboardWindow.safeAreaInsets;
        if(!DFNativeSceneUsable(full,i.top,i.left,i.bottom,i.right,&usable)){
            // An unknown safe area is NOT permission to guess Dock width.
            usable=full;
        }
        NSDictionary *record=DFNativeSceneOwnerRecord(self.session,full,usable,
                              chrome,NSDate.date.timeIntervalSince1970);
        if(record && DFNativeSceneValidateOwnerRecord(record,self.session,
                                                  NSDate.date.timeIntervalSince1970)){
            // Short lease expires within 3s if the real owner is disconnected.
            [record writeToFile:DFNativeSceneOwnerRecordPath atomically:YES];
        }
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:DFNativeSceneOwnerRecordPath error:nil];
    }
    NSString *state=[NSString stringWithFormat:@"dashboard=%d nativeChrome=%d full=%@ usable=%@",
      dashboard,chrome,NSStringFromCGRect(full),NSStringFromCGRect(usable)];
    if(![self.lastDescription isEqual:state] || self.ticks%20==0){
        self.lastDescription=state;DFProbeLog(state);
    }
}
@end
void DFNativeSceneProbeStart(void){[[DFNativeSceneProbe shared] start];}
