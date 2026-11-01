// First-party DuoFace cross-process app-side state. No vendor protocol/token.
// Native12/DuoNavi architectural precedent: host -> selected app -> UIKit restore.
// A short-lived owner+scene lease is required before ANY UIKit mutation.
// Darwin notify is not an authenticated sender boundary; do not call it signed.
#ifndef DF154_APP_STATE_PROTOCOL_H
#define DF154_APP_STATE_PROTOCOL_H
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>
#import "DF156DarwinMailbox.h"
#import "DF155PilotAppScope.h"

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
// Fixed per-app/direction names and bounded retained tokens, never per-request names.
// Main-queue serialization matches both current UIKit host and app consumer.
static inline DF156Mailbox *DF156Channel(NSString *bundle,BOOL ack) {
 if(!NSThread.isMainThread || !DF155PilotAppID(bundle))return NULL;
 static NSMutableDictionary<NSString *,NSValue *> *channels;
 if(!channels)channels=[NSMutableDictionary new];
 NSString *name=[NSString stringWithFormat:@"com.duoface.ipc.v156.%@.%@",
    ack?@"ack":@"state",bundle];
 DF156Mailbox *mailbox=[channels[name] pointerValue];
 if(!mailbox) {
   mailbox=calloc(1,sizeof(*mailbox));
   if(!mailbox)return NULL;
   DF156Init(mailbox,name.UTF8String);
   channels[name]=[NSValue valueWithPointer:mailbox];
 }
 return mailbox;
}
static inline NSDictionary *DF156ReadState(DF156Mailbox *channel) {
 if(!channel)return nil;
 uint8_t bytes[DF156_MAX_BYTES];
 size_t size=DF156Read(channel,bytes);
 if(!size)return nil;
 id state=[NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:bytes length:size]
    options:0 error:nil];
 return [state isKindOfClass:NSDictionary.class]?state:nil;
}
static inline BOOL DF156Send(NSDictionary *state,BOOL ack) {
 DF156Mailbox *channel=DF156Channel(state[@"bundleIdentifier"],ack);
 if(!channel || ![NSJSONSerialization isValidJSONObject:state])return NO;
 NSData *bytes=[NSJSONSerialization dataWithJSONObject:state options:0 error:nil];
 uint64_t generation=0;arc4random_buf(&generation,sizeof(generation));
 BOOL ok=bytes && DF156Write(channel,bytes.bytes,bytes.length,generation?:1);
 if(!ok)NSLog(@"[DF156IPC] transport-write-failed bundle=%@ ack=%d",
      state[@"bundleIdentifier"],ack);
 return ok;
}
// Callback carries the complete dictionary, with old request/scene checks intact.
static inline BOOL DF156Listen(NSString *bundle,BOOL ack,void (^receive)(NSDictionary *)) {
 DF156Mailbox *channel=DF156Channel(bundle,ack);
 if(!channel)return NO;
 int token=-1;
 uint32_t status=notify_register_dispatch(channel->name,&token,dispatch_get_main_queue(),
   ^(__unused int ignored){
     NSDictionary *state=DF156ReadState(channel);
     if([state[@"bundleIdentifier"] isEqual:bundle])receive(state);
   });
 if(status!=NOTIFY_STATUS_OK)return NO;
 // Catch an already committed lease when injection started after host publish.
 NSDictionary *state=DF156ReadState(channel);
 if([state[@"bundleIdentifier"] isEqual:bundle])receive(state);
 return YES; // token intentionally lives for the process; caller registers once.
}
static inline void DF155PostAck(NSDictionary *s) {
 if(DF154String(s[@"requestID"]) && DF154String(s[@"bundleIdentifier"]) &&
    DF154String(s[@"owner"]) && DF154String(s[@"sceneIdentifier"]) &&
    DF154String(s[@"phase"]))DF156Send(s,YES);
}
static inline void DF154Post(NSDictionary *s) {
 if(DF154Valid(s,NSDate.date.timeIntervalSince1970))DF156Send(s,NO);
}
#endif
