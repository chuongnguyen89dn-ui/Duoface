// Independent, 30-second, on-demand CarPlay touch-owner diagnostic for iOS 16.
// The system CPWindow stays untouched. No vendor binary, app hosting,
// system Dock manipulation, fabricated UIKit touches, or autorun overlay.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>

static const char *const kStart = "com.duoface.nativehost.touchowner.start.v1";
static const char *const kStop  = "com.duoface.nativehost.touchowner.stop.v1";
static UIWindow *sWindow;
static UIButton *sButton;
static NSUInteger sTaps, sGeneration;
static BOOL sActivated;
static int sStartToken=-1, sStopToken=-1;

static void DFTOLog(NSString *event, NSString *detail) {
    NSString *line=[NSString stringWithFormat:@"[DFTouchOwner] %@ %@\n",
        event?:@"-", detail?:@""];
    NSLog(@"%@",line);
    int fd=open("/var/mobile/Library/Logs/DuoFaceTouchOwner.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0) {
        NSData *d=[line dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);
        close(fd);
    }
}
static id DFGetObject(id object,NSString *name) {
    if(!object)return nil;
    SEL sel=NSSelectorFromString(name);
    if(![object respondsToSelector:sel])return nil;
    Class cls=object_isClass(object)?(Class)object:object_getClass(object);
    Method method=object_isClass(object)?class_getClassMethod(cls,sel):
                                 class_getInstanceMethod(cls,sel);
    char ret[16]={0};
    if(!method)return nil;
    method_getReturnType(method,ret,sizeof(ret));
    if(ret[0]!='@')return nil;
    @try{return ((id(*)(id,SEL))objc_msgSend)(object,sel);}
    @catch(NSException *exception) {
        DFTOLog(@"getter-exception",NSStringFromClass(exception.class));
        return nil;
    }
}
static id DFConnectedCarDisplay(void) {
    id device=DFGetObject(NSClassFromString(@"AVExternalDevice"),
                          @"currentCarPlayExternalDevice");
    NSArray *ids=DFGetObject(device,@"screenIDs");
    NSArray *displays=DFGetObject(NSClassFromString(@"CADisplay"),@"displays");
    if(![ids isKindOfClass:NSArray.class] ||
       ![displays isKindOfClass:NSArray.class] || ids.count==0)return nil;
    for(id display in displays) {
        id uid=DFGetObject(display,@"uniqueId");
        if(uid && [ids containsObject:uid])return display;
    }
    return nil;
}
static void DFStopProbe(NSString *reason) {
    sGeneration++;
    if(sWindow) {
        sWindow.hidden=YES;
        sWindow.rootViewController=nil;
        sWindow=nil;
        sButton=nil;
        DFTOLog(@"window-detached",reason);
    }
    sActivated=NO;
}
@interface DFTouchOwnerHandler : NSObject
@end
@implementation DFTouchOwnerHandler
- (void)tapped:(UIButton *)sender {
    if(!sActivated || !sWindow || sender!=sButton)return;
    sTaps++;
    NSString *label=[NSString stringWithFormat:@"CHẠM OK %lu",(unsigned long)sTaps];
    [sender setTitle:label forState:UIControlStateNormal];
    DFTOLog(@"real-button-action",label);
}
@end
static DFTouchOwnerHandler *sHandler;
static void DFStartProbe(void) {
    if(sActivated || sWindow)return;
    sActivated=YES; // one attempt per CarPlay activation, no retry storm.
    id display=DFConnectedCarDisplay();
    Class configuration=NSClassFromString(@"FBSDisplayConfiguration");
    Class windowClass=NSClassFromString(@"UIRootSceneWindow");
    SEL makeConfig=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:");
    SEL makeWindow=NSSelectorFromString(@"initWithDisplayConfiguration:");
    if(!display || !configuration || !windowClass ||
       ![configuration instancesRespondToSelector:makeConfig] ||
       ![windowClass instancesRespondToSelector:makeWindow]) {
        DFTOLog(@"preflight-rejected",
           [NSString stringWithFormat:@"display=%d config=%d window=%d",
               display!=nil,configuration!=nil,windowClass!=nil]);
        return;
    }
    @try {
        id config=((id(*)(id,SEL,id,BOOL))objc_msgSend)(
            [configuration alloc],makeConfig,display,NO);
        UIWindow *window=((id(*)(id,SEL,id))objc_msgSend)(
            [windowClass alloc],makeWindow,config);
        if(!window || ![window isKindOfClass:UIWindow.class] ||
           !window.screen || window.screen==UIScreen.mainScreen) {
            DFTOLog(@"window-rejected",@"not-an-external-UIWindow");
            return;
        }
        // A narrow 110 x 40pt panel only: do not cover apps or Apple Dock.
        CGRect screen=window.screen.bounds;
        if(CGRectGetWidth(screen)<240 || CGRectGetHeight(screen)<160) {
            DFTOLog(@"window-rejected",@"screen-bounds-too-small");
            return;
        }
        CGRect target=CGRectMake(CGRectGetMaxX(screen)-124,
                                 CGRectGetMinY(screen)+10,110,40);
        window.frame=target;
        if(fabs(window.frame.size.width-110)>1 ||
           fabs(window.frame.size.height-40)>1) {
            DFTOLog(@"window-rejected",@"window-does-not-support-bounded-frame");
            return;
        }
        UIViewController *root=[UIViewController new];
        root.view=[[UIView alloc]initWithFrame:CGRectMake(0,0,110,40)];
        root.view.backgroundColor=UIColor.clearColor;
        UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
        button.frame=root.view.bounds;
        button.backgroundColor=[UIColor colorWithRed:.8 green:.10 blue:.12 alpha:.95];
        button.layer.cornerRadius=9;
        button.titleLabel.font=[UIFont boldSystemFontOfSize:12];
        [button setTitle:@"CHẠM THỬ" forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [button addTarget:sHandler action:@selector(tapped:)
          forControlEvents:UIControlEventTouchUpInside];
        [root.view addSubview:button];
        window.rootViewController=root;
        window.backgroundColor=UIColor.clearColor;
        window.opaque=NO;
        window.windowLevel=UIWindowLevelNormal+1;
        sWindow=window;sButton=button;sTaps=0;
        window.hidden=NO;
        DFTOLog(@"window-visible",
           [NSString stringWithFormat:@"class=%@ frame=%@ screen=%@",
               NSStringFromClass(window.class),NSStringFromCGRect(window.frame),
               NSStringFromCGRect(screen)]);
        NSUInteger generation=++sGeneration;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,30*NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            if(sGeneration==generation)DFStopProbe(@"timeout-30s");
        });
    } @catch(NSException *exception) {
        DFTOLog(@"window-exception",exception.reason);
        DFStopProbe(@"exception");
    }
}
__attribute__((constructor))
static void DFInstallTouchOwnerProbe(void) {
    @autoreleasepool {
        if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
        dispatch_async(dispatch_get_main_queue(), ^{
            sHandler=[DFTouchOwnerHandler new];
            int a=notify_register_dispatch(kStart,&sStartToken,
                      dispatch_get_main_queue(),^(int t) {
                (void)t;DFStartProbe();
            });
            int b=notify_register_dispatch(kStop,&sStopToken,
                      dispatch_get_main_queue(),^(int t) {
                (void)t;DFStopProbe(@"nativehost-disconnected");
            });
            DFTOLog(@"listener-registered",
                [NSString stringWithFormat:@"start=%d stop=%d",a,b]);
        });
    }
}
