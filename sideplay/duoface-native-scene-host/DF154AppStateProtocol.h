// First-party DuoFace cross-process app-side state. No vendor protocol/token.
// Native12/DuoNavi architectural precedent: host -> selected app -> UIKit restore.
// A signed, short-lived owner+scene lease is required before ANY UIKit mutation.
#ifndef DF154_APP_STATE_PROTOCOL_H
#define DF154_APP_STATE_PROTOCOL_H
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>

static NSString *const DF154StateNotification=@"com.duoface.independent.app-state.v154";
static NSString *const DF155AckNotification=@"com.duoface.independent.app-state.ack.v155";

static inline id DF154Object(id object,const char *getter) {
 if(!object)return nil;
 SEL sel=sel_registerName(getter);
 Method m=class_getInstanceMethod(object_getClass(object),sel);
 if(!m || strcmp(method_getTypeEncoding(m),"@16@0:8"))return nil;
 @try {return ((id(*)(id,SEL))objc_msgSend)(object,sel);}
 @catch(__unused NSException *e){return nil;}
}
static inline BOOL DF154String(id text) {
 return [text isKindOfClass:NSString.class] && [text length]>0 && [text length]<=256;
}
static inline BOOL DF154Valid(NSDictionary *s,NSTimeInterval now) {
 if(![s isKindOfClass:NSDictionary.class] || ![s[@"version"] isEqual:@1] ||
    !DF154String(s[@"bundleIdentifier"]) || !DF154String(s[@"owner"]) ||
    !DF154String(s[@"sceneIdentifier"]) || !DF154String(s[@"requestID"]) ||
    ![s[@"issuedAt"] isKindOfClass:NSNumber.class] ||
    ![s[@"active"] isKindOfClass:NSNumber.class] ||
    ![s[@"width"] isKindOfClass:NSNumber.class] ||
    ![s[@"height"] isKindOfClass:NSNumber.class])return NO;
 double age=now-[s[@"issuedAt"] doubleValue];
 double w=[s[@"width"] doubleValue],h=[s[@"height"] doubleValue];
 BOOL active=[s[@"active"] boolValue];
 if(!isfinite(age)||age<0||age>3.0 || !isfinite(w)||!isfinite(h) ||
    (![[s objectForKey:@"active"] isEqual:@0] && ![[s objectForKey:@"active"] isEqual:@1]))
    return NO;
 return active?(w>=100&&h>=100&&w<=8192&&h<=8192):(w==0&&h==0);
}
@interface NSObject (DF154DistributedCenter)
+ (id)defaultCenter;
- (void)addObserver:(id)observer selector:(SEL)sel name:(NSString *)name object:(id)object;
- (void)removeObserver:(id)observer;
- (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)info deliverImmediately:(BOOL)immediately;
@end
static inline id DF154Center(void) {
 Class cls=NSClassFromString(@"NSDistributedNotificationCenter");
 if(![cls respondsToSelector:@selector(defaultCenter)])return nil;
 id center=[cls defaultCenter];
 return [center respondsToSelector:@selector(postNotificationName:object:userInfo:deliverImmediately:)] &&
        [center respondsToSelector:@selector(addObserver:selector:name:object:)]?center:nil;
}
static inline void DF155PostAck(NSDictionary *s) {
 if(DF154String(s[@"requestID"]) && DF154String(s[@"bundleIdentifier"]) &&
    DF154String(s[@"owner"]) && DF154String(s[@"sceneIdentifier"]) &&
    DF154String(s[@"phase"]))
   [DF154Center() postNotificationName:DF155AckNotification object:nil userInfo:s deliverImmediately:YES];
}
static inline void DF154Post(NSDictionary *s) {
 if(DF154Valid(s,NSDate.date.timeIntervalSince1970))
   [DF154Center() postNotificationName:DF154StateNotification object:nil userInfo:s deliverImmediately:YES];
}
#endif
