// First-party Native12-inspired host/app contract. No vendor payload/code.
#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>

#define DFYTBundle @"com.google.ios.youtube"
#define DFYTStateName @"com.duoface.youtube.host-state.v1"
#define DFYTRequestName @"com.duoface.youtube.host-request.v1"
#define DFYTAckName @"com.duoface.youtube.host-ack.v1"

// Private object getters are optional and verified before dispatch.
static inline id DFYTObject(id object, NSString *name) {
    SEL sel=NSSelectorFromString(name);
    Method m=object?class_getInstanceMethod(object_getClass(object),sel):NULL;
    char type[64]={0};
    if(!m || method_getNumberOfArguments(m)!=2)return nil;
    method_getReturnType(m,type,sizeof(type));
    if(type[0]!='@')return nil;
    return ((id(*)(id,SEL))objc_msgSend)(object,sel);
}
static inline BOOL DFYTString(id value) {
    return [value isKindOfClass:NSString.class] && [value length]>0 && [value length]<=256;
}
static inline BOOL DFYTNumber(id value) {
    return [value isKindOfClass:NSNumber.class] && isfinite([value doubleValue]);
}
static inline BOOL DFYTValidState(NSDictionary *state, NSTimeInterval now) {
    if(![state isKindOfClass:NSDictionary.class] || ![state[@"bundleIdentifier"] isEqual:DFYTBundle] ||
       ![state[@"version"] isEqual:@1] || !DFYTString(state[@"owner"]) ||
       !DFYTString(state[@"sceneIdentifier"]) || !DFYTNumber(state[@"issuedAt"]) ||
       !DFYTNumber(state[@"active"]) || !DFYTNumber(state[@"orientation"]) ||
       !DFYTNumber(state[@"width"]) || !DFYTNumber(state[@"height"]))return NO;
    double age=now-[state[@"issuedAt"] doubleValue];
    double w=[state[@"width"] doubleValue],h=[state[@"height"] doubleValue];
    return isfinite(now) && age>=0 && age<=3.0 &&
        [state[@"orientation"] doubleValue]==1.0 &&
        ([state[@"active"] doubleValue]==0.0 || [state[@"active"] doubleValue]==1.0) && w>=64 && h>=64 && w<=8192 && h<=8192;
}
// Reject replay and an old owner's delayed revoke after a new owner attaches.
static inline BOOL DFYTShouldAccept(NSDictionary *next, NSDictionary *current,
                                   NSTimeInterval now, NSTimeInterval newest) {
    if(!DFYTValidState(next,now) || [next[@"issuedAt"] doubleValue]<=newest)return NO;
    return [next[@"active"] boolValue] ||
        ([next[@"owner"] isEqual:current[@"owner"]] &&
         [next[@"sceneIdentifier"] isEqual:current[@"sceneIdentifier"]]);
}
static inline char DFYTRotationABI(id window) {
    SEL sel=NSSelectorFromString(@"_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:");
    Method m=class_getInstanceMethod(object_getClass(window),sel);
    if(!m || method_getNumberOfArguments(m)!=6)return 0;
    char r[32]={0},o[32]={0},b[32]={0},d[32]={0},s[32]={0};
    method_getReturnType(m,r,sizeof(r));
    method_getArgumentType(m,2,o,sizeof(o)); method_getArgumentType(m,3,b,sizeof(b));
    method_getArgumentType(m,4,d,sizeof(d)); method_getArgumentType(m,5,s,sizeof(s));
    if(r[0]!='v' || (o[0]!='q' && o[0]!='i') ||
       (b[0]!='B' && b[0]!='c') || d[0]!='d' || (s[0]!='B' && s[0]!='c'))return 0;
    return o[0];
}
static inline BOOL DFYTRotate(id window, NSInteger orientation) {
    // Original Native12 0x2aa108/0x2aa10c: updateStatusBar=0, skipCallbacks=1.
    // Suppress a second app rotation lifecycle while host geometry is applied.
    char abi=DFYTRotationABI(window); if(!abi)return NO;
    SEL sel=NSSelectorFromString(@"_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:");
    if(abi=='i')((void(*)(id,SEL,int,BOOL,double,BOOL))objc_msgSend)(window,sel,(int)orientation,NO,0.0,YES);
    else ((void(*)(id,SEL,NSInteger,BOOL,double,BOOL))objc_msgSend)(window,sel,orientation,NO,0.0,YES);
    return YES;
}
// Original Native12 UIKit app reconciler enumerates regular UIWindow objects AND
// internal visible windows (including video presentation surfaces), then
// invokes updateLayoutToCurrentInterfaceOrientation where ABI permits.
// The .87 receiver only read UIWindowScene.windows; thus an internal video
// UIWindow could be omitted even when the exact scene matched.
// Query read-only, feature-detected private selectors; no window lookup by
// bundle ID, global swizzle, or unverified selector signature.
static inline NSArray *DFYTVisibleInternalWindows(id application) {
    for(NSString *name in @[@"allWindowsIncludingInternalWindows:onlyVisibleWindows:",
                             @"_allWindowsIncludingInternalWindows:onlyVisibleWindows:"]) {
        SEL sel=NSSelectorFromString(name);
        Method method=application?class_getInstanceMethod(object_getClass(application),sel):NULL;
        if(!method || method_getNumberOfArguments(method)!=4)continue;
        char result[32]={0},arg1[32]={0},arg2[32]={0};
        method_getReturnType(method,result,sizeof(result));
        method_getArgumentType(method,2,arg1,sizeof(arg1));
        method_getArgumentType(method,3,arg2,sizeof(arg2));
        if(result[0]!='@' || (arg1[0]!='B' && arg1[0]!='c') ||
           (arg2[0]!='B' && arg2[0]!='c'))continue;
        id value=((id (*)(id,SEL,BOOL,BOOL))objc_msgSend)(application,sel,YES,YES);
        if([value isKindOfClass:NSArray.class])return value;
    }
    return nil;
}
static inline BOOL DFYTUpdateWindowLayout(id controller) {
    SEL sel=NSSelectorFromString(@"updateLayoutToCurrentInterfaceOrientation");
    Method method=controller?class_getInstanceMethod(object_getClass(controller),sel):NULL;
    if(!method || method_getNumberOfArguments(method)!=2)return NO;
    char result[32]={0};
    method_getReturnType(method,result,sizeof(result));
    if(result[0]!='v')return NO;
    ((void (*)(id,SEL))objc_msgSend)(controller,sel);
    return YES;
}

// Native12 uses NSDistributedNotificationCenter. No sandbox file reads,
// persistent stale state, Darwin bit-packing, or device-wide rotation.
@interface NSObject (DFYTDistributedAPI)
+ (id)defaultCenter;
- (void)addObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;
- (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)info deliverImmediately:(BOOL)immediate;
@end
static inline id DFYTCenter(void) {
    Class cls=NSClassFromString(@"NSDistributedNotificationCenter");
    if(![cls respondsToSelector:@selector(defaultCenter)])return nil;
    id center=[cls defaultCenter];
    return [center respondsToSelector:@selector(postNotificationName:object:userInfo:deliverImmediately:)] &&
           [center respondsToSelector:@selector(addObserver:selector:name:object:)]?center:nil;
}
static inline void DFYTPost(NSString *name, NSDictionary *info) {
    [DFYTCenter() postNotificationName:name object:nil userInfo:info deliverImmediately:YES];
}
