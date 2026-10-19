// DuoFace experimental first-party CarPlay process ownership report.
// IMPORTANT: no hooks, no runtime swizzling, no UI modification or fake Dock.
// Filtered to CarPlay/CarPlayApp processes only, never SpringBoard.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <fcntl.h>
#import <unistd.h>

static const char *DFLogPath="/var/mobile/Library/Logs/DuoFaceNativeDockOwnerProbe.log";
static NSUInteger DFProbeCount=0;
static BOOL DFProbeFinished=NO;

static void DFLog(NSString *event,NSString *detail) {
    NSString *line=[NSString stringWithFormat:
      @"[DuoFaceNativeDockOwnerProbe] %@ %@\n",event?:@"-",detail?:@""];
    NSLog(@"%@",line);
    [[NSFileManager defaultManager]
       createDirectoryAtPath:@"/var/mobile/Library/Logs"
       withIntermediateDirectories:YES attributes:nil error:nil];
    int fd=open(DFLogPath,O_WRONLY|O_CREAT|O_APPEND,0644);
    if (fd>=0) {
        NSData *payload=[line dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,payload.bytes,payload.length);
        close(fd);
    }
}
static BOOL DFAllowedProcess(void) {
    NSString *proc=NSProcessInfo.processInfo.processName;
    return [proc isEqualToString:@"CarPlay"] || [proc isEqualToString:@"CarPlayApp"];
}
static NSString *DFRect(CGRect rect) {
    return NSStringFromCGRect(rect);
}
static NSString *DFInsets(UIEdgeInsets insets) {
    return NSStringFromUIEdgeInsets(insets);
}
static void DFProbeOnce(void) {
    if (!DFAllowedProcess() || ![NSThread isMainThread] || DFProbeFinished)return;
    DFProbeCount++;
    @try {
        UIApplication *app=UIApplication.sharedApplication;
        NSSet<UIScene *> *scenes=app.connectedScenes;
        NSUInteger inspected=0,external=0,visible=0;
        NSMutableString *summary=[NSMutableString stringWithFormat:
           @"process=%@ sample=%lu sceneCount=%lu dashboardClass=%d dockWindowClass=%d remoteContextClass=%d layerHostClass=%d",
           NSProcessInfo.processInfo.processName,(unsigned long)DFProbeCount,
           (unsigned long)scenes.count,
           NSClassFromString(@"DBWorkspace")!=Nil,
           NSClassFromString(@"DBDockWindow")!=Nil,
           NSClassFromString(@"CAContext")!=Nil,
           NSClassFromString(@"CALayerHost")!=Nil];
        for (UIScene *scene in scenes) {
            if (![scene isKindOfClass:UIWindowScene.class])continue;
            UIWindowScene *ws=(UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (++inspected>16)break;
                BOOL isExternal=(w.screen && w.screen!=UIScreen.mainScreen);
                if (isExternal)external++;
                if (!w.hidden && w.alpha>0.01)visible++;
                NSString *root=w.rootViewController ?
                              NSStringFromClass(w.rootViewController.class):@"none";
                NSString *name=NSStringFromClass(w.class);
                [summary appendFormat:
                 @" | sceneRole=%@ sceneState=%ld winClass=%@ rootClass=%@ external=%d hidden=%d key=%d level=%.2f frame=%@ bounds=%@ safeInsets=%@ screenBounds=%@",
                 ws.session.role?:@"unknown",(long)scene.activationState,
                 name,root,isExternal,w.hidden,w.isKeyWindow,w.windowLevel,
                 DFRect(w.frame),DFRect(w.bounds),DFInsets(w.safeAreaInsets),
                 DFRect(w.screen.bounds)];
            }
            if (inspected>16)break;
        }
        DFLog(@"sample",summary);
        // Finish on the first available true external UIWindowScene, otherwise
        // check at most 40 times (80s); no forever-running process observer.
        if (external>0 || DFProbeCount>=40) {
            DFProbeFinished=YES;
            DFLog(@"complete",[NSString stringWithFormat:
               @"windows=%lu external=%lu visible=%lu nativeDockVisible=UNVERIFIED",
               (unsigned long)inspected,(unsigned long)external,(unsigned long)visible]);
        }
    } @catch(NSException *e) {
        DFProbeFinished=YES;
        DFLog(@"exception",[NSString stringWithFormat:@"class=%@",e.name]);
    }
}
static void DFTick(NSTimer *timer) {
    DFProbeOnce();
    if (DFProbeFinished)[timer invalidate];
}

%ctor {
    @autoreleasepool {
        if (!DFAllowedProcess())return;
        // Never mutate SpringBoard or CarPlay window layout during bootstrap.
        // Diagnostic starts after the host UI has initialized.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(8*NSEC_PER_SEC)),
          dispatch_get_main_queue(), ^{
            DFLog(@"begin",@"read-only native scene ownership; no window modification");
            DFProbeOnce();
            if (!DFProbeFinished)
                [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES
                    block:^(NSTimer *timer) {
                        DFTick(timer);
                    }];
          });
    }
}
