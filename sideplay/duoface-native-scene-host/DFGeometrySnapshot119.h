// Read-only geometry evidence. No layout, private setters, input hooks or IPC commands.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>

static inline NSDictionary *DFGWindow(UIWindow *w) {
    if(!w || !w.screen)return @{@"Status":@"unavailable"};
    UIWindowScene *scene=w.windowScene;
    NSMutableDictionary *d=[@{
        @"WindowClass":NSStringFromClass(w.class),
        @"RootControllerClass":w.rootViewController?NSStringFromClass(w.rootViewController.class):@"nil",
        @"Frame":NSStringFromCGRect(w.frame),@"Bounds":NSStringFromCGRect(w.bounds),
        @"SafeAreaInsets":NSStringFromUIEdgeInsets(w.safeAreaInsets),
        @"SafeLayoutFrame":NSStringFromCGRect(w.safeAreaLayoutGuide.layoutFrame),
        @"Hidden":@(w.hidden),@"Alpha":@(w.alpha),
        @"MainScreen":@(w.screen==UIScreen.mainScreen),
        @"ScreenBounds":NSStringFromCGRect(w.screen.bounds),@"Scale":@(w.screen.scale),
        @"CoordinateSpace":@"UIScreen.coordinateSpace",
        @"WindowInScreen":NSStringFromCGRect([w convertRect:w.bounds toCoordinateSpace:w.screen.coordinateSpace]),
        @"SafeLayoutInScreen":NSStringFromCGRect([w convertRect:w.safeAreaLayoutGuide.layoutFrame toCoordinateSpace:w.screen.coordinateSpace])
    } mutableCopy];
    if(scene){
        d[@"SceneBounds"]=NSStringFromCGRect(scene.coordinateSpace.bounds);
        d[@"SceneInScreen"]=NSStringFromCGRect([scene.coordinateSpace convertRect:scene.coordinateSpace.bounds toCoordinateSpace:w.screen.coordinateSpace]);
        d[@"SceneID"]=scene.session.persistentIdentifier?:@"";
        d[@"SceneRole"]=scene.session.role?:@"";
        d[@"ActivationState"]=@(scene.activationState);
    }
    return d;
}
// Only known zero-argument object getters; missing native root stays unresolved.
static inline id DFGObject(id object, NSString *name) {
    if(!object)return nil;
    SEL sel=NSSelectorFromString(name);
    Method m=class_getInstanceMethod(object_getClass(object),sel);
    if(!m || method_getNumberOfArguments(m)!=2)return nil;
    char type[16]={0};method_getReturnType(m,type,sizeof(type));
    if(type[0]!='@')return nil;
    @try{return ((id(*)(id,SEL))objc_msgSend)(object,sel);}
    @catch(NSException *e){(void)e;return nil;}
}
static inline BOOL DFGFresh(NSDictionary *pulse, NSTimeInterval now) {
    id sid=pulse[@"Session"], sample=pulse[@"GeometrySample"], stamp=pulse[@"Timestamp"], time=pulse[@"GeometrySampleTime"];
    if(![pulse[@"Version"] isEqual:@1] || ![pulse[@"Active"] isEqual:@YES] ||
       ![sid isKindOfClass:NSString.class] || ![[NSUUID alloc] initWithUUIDString:sid] ||
       ![sample isKindOfClass:NSString.class] || ![[NSUUID alloc] initWithUUIDString:sample] ||
       ![stamp isKindOfClass:NSNumber.class] || ![time isKindOfClass:NSNumber.class])return NO;
    double age=now-[stamp doubleValue], sampleAge=now-[time doubleValue];
    return isfinite(age) && age>=0 && age<=2.5 && isfinite(sampleAge) && sampleAge>=0 && sampleAge<=3.5;
}
static inline void DFGWrite(NSDictionary *pulse, NSDictionary *measurements) {
    if(!NSThread.isMainThread || !DFGFresh(pulse,NSDate.date.timeIntervalSince1970))return;
    NSString *process=NSProcessInfo.processInfo.processName;
    // Dedicated process files prevent multiple writers corrupting JSONL/rotation.
    if(![@[@"DuoFaceNativeHost",@"SpringBoard",@"CarPlayApp",@"CarPlay",@"Dashboard"] containsObject:process])return;
    NSDictionary *record=@{@"Schema":@119,@"Kind":@"geometry-readonly",
        @"Session":pulse[@"Session"],@"Sample":pulse[@"GeometrySample"],
        @"SampleTime":pulse[@"GeometrySampleTime"],@"Timestamp":@(NSDate.date.timeIntervalSince1970),
        @"Process":process,@"Measurements":measurements};
    if(![NSJSONSerialization isValidJSONObject:record])return;
    NSData *data=[NSJSONSerialization dataWithJSONObject:record options:0 error:nil];
    if(!data || data.length>128*1024)return;
    NSMutableData *line=[data mutableCopy];[line appendBytes:"\n" length:1];
    NSString *path=[NSString stringWithFormat:@"/var/mobile/Library/Logs/DuoFaceGeometry119-%@.jsonl",process];
    int fd=open(path.UTF8String,O_WRONLY|O_APPEND|O_CREAT|O_CLOEXEC,0644);
    if(fd<0)return;
    if(lseek(fd,0,SEEK_END)>1024*1024){(void)ftruncate(fd,0);(void)lseek(fd,0,SEEK_SET);}
    (void)write(fd,line.bytes,line.length);close(fd);
}
