#import "MTCPBridgeContract.h"
#import <math.h>
static NSString *const kBridgeConfig=@"/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist";
static NSString *const kEngineConfig=@"/var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist";
static NSString *const kSurface=@"/var/mobile/Library/Preferences/com.duoface.mytweak.cp-surface.plist";
static NSString *const kCommand=@"/var/mobile/Library/Preferences/com.duoface.mytweak.cp-command.plist";
static NSString *const kReceiverAck=@"/var/mobile/Library/Preferences/com.duoface.mytweak.cp-receiver-ack.plist";
static NSTimeInterval const kMaxAge=2.0;
NSString *MTCPBridgeSurfaceFile(void) { return kSurface; }
NSString *MTCPBridgeCommandFile(void) { return kCommand; }
static BOOL MTCPBoolFlag(NSString *path,NSString *key) {
    NSDictionary *dict=[NSDictionary dictionaryWithContentsOfFile:path];
    return [dict[key] isKindOfClass:NSNumber.class] && [dict[key] boolValue];
}
BOOL MTCPBridgeExplicitOptIn(void) {
    // Two separate switches: legacy V1BC Enabled alone never enables the bridge.
    return MTCPBoolFlag(kEngineConfig,@"Enabled") &&
           MTCPBoolFlag(kBridgeConfig,@"Enabled");
}
static BOOL MTCPValidSession(id value) {
    return [value isKindOfClass:NSString.class] &&
           [value length]==36 && [[NSUUID alloc] initWithUUIDString:value]!=nil;
}
static BOOL MTCPRecent(id value,NSTimeInterval now) {
    if (![value isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval age=now-[value doubleValue];
    return isfinite(age) && age>=0 && age<=kMaxAge;
}
static BOOL MTCPFiniteUnit(id value) {
    if (![value isKindOfClass:NSNumber.class])return NO;
    double d=[value doubleValue];
    return isfinite(d) && d>=0 && d<=1;
}
static BOOL MTCPHeader(NSDictionary *record,NSString *kind,NSString *session,
                        NSTimeInterval now) {
    if (![record isKindOfClass:NSDictionary.class])return NO;
    // A malformed plist must never send -isEqualToString: to NSNumber/NSArray.
    id recordKind=record[@"Kind"];
    if (![record[@"Version"] isEqual:@1] ||
        ![recordKind isKindOfClass:NSString.class] ||
        ![recordKind isEqualToString:kind] ||
        !MTCPValidSession(record[@"Session"]) ||
        !MTCPRecent(record[@"Timestamp"],now))return NO;
    if (session && ![record[@"Session"] isEqualToString:session])return NO;
    return YES;
}
BOOL MTCPBridgeValidateSurface(NSDictionary *record,NSString *expectedSession,NSTimeInterval now) {
    if (!MTCPHeader(record,@"surface",expectedSession,now))return NO;
    NSNumber *cid=record[@"ContextID"];
    if (![cid isKindOfClass:NSNumber.class] || cid.unsignedLongLongValue==0 ||
        cid.unsignedLongLongValue>UINT32_MAX)return NO;
    for(NSString *key in @[@"X",@"Y",@"Width",@"Height"])
        if(!MTCPFiniteUnit(record[key]))return NO;
    double x=[record[@"X"] doubleValue],y=[record[@"Y"] doubleValue],
           w=[record[@"Width"] doubleValue],h=[record[@"Height"] doubleValue];
    return w>=0.25 && h>=0.25 && x+w<=1.0001 && y+h<=1.0001;
}
BOOL MTCPBridgeValidateCommand(NSDictionary *record,NSString *expectedSession,
                                 unsigned long long lastSequence,NSTimeInterval now) {
    if (!MTCPHeader(record,@"command",expectedSession,now))return NO;
    id sequence=record[@"Sequence"];
    if (![sequence isKindOfClass:NSNumber.class] ||
        [sequence unsignedLongLongValue]<=lastSequence ||
        [sequence unsignedLongLongValue]>1000000000ULL)return NO;
    NSString *action=record[@"Action"];
    if (![action isKindOfClass:NSString.class])return NO;
    if ([@[@"home",@"close",@"swap",@"split",@"zoom"] containsObject:action]) {
        return record[@"Phase"]==nil && record[@"X"]==nil && record[@"Y"]==nil;
    }
    if (![action isEqualToString:@"pointer"])return NO;
    return [@[@"begin",@"move",@"end",@"cancel"] containsObject:record[@"Phase"]] &&
           MTCPFiniteUnit(record[@"X"]) && MTCPFiniteUnit(record[@"Y"]);
}
NSDictionary *MTCPBridgeReadSurface(NSString *session) {
    if (!MTCPBridgeExplicitOptIn())return nil;
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:kSurface];
    return MTCPBridgeValidateSurface(record,session,NSDate.date.timeIntervalSince1970)?record:nil;
}
NSDictionary *MTCPBridgeReadCommand(NSString *session,unsigned long long lastSequence) {
    if (!MTCPBridgeExplicitOptIn())return nil;
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:kCommand];
    return MTCPBridgeValidateCommand(record,session,lastSequence,
                   NSDate.date.timeIntervalSince1970)?record:nil;
}
BOOL MTCPBridgeWriteSurface(NSString *session,uint32_t contextID,CGRect b) {
    if (!MTCPBridgeExplicitOptIn() || !MTCPValidSession(session) ||
        contextID==0 || !isfinite(b.origin.x) || !isfinite(b.origin.y) ||
        !isfinite(b.size.width) || !isfinite(b.size.height))return NO;
    NSDictionary *record=@{@"Version":@1,@"Kind":@"surface",@"Session":session,
       @"Timestamp":@(NSDate.date.timeIntervalSince1970),@"ContextID":@(contextID),
       @"X":@(b.origin.x),@"Y":@(b.origin.y),
       @"Width":@(b.size.width),@"Height":@(b.size.height)};
    if (!MTCPBridgeValidateSurface(record,session,NSDate.date.timeIntervalSince1970))return NO;
    return [record writeToFile:kSurface atomically:YES];
}
BOOL MTCPBridgeWriteCommand(NSString *session,NSString *action,unsigned long long sequence,
                             NSString *phase,CGPoint p) {
    if (!MTCPBridgeExplicitOptIn() || !MTCPValidSession(session) || sequence==0)return NO;
    NSMutableDictionary *record=[@{@"Version":@1,@"Kind":@"command",
        @"Session":session,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
        @"Sequence":@(sequence),@"Action":action?:@""} mutableCopy];
    if ([action isEqualToString:@"pointer"]) {
        record[@"Phase"]=phase?:@"";
        record[@"X"]=@(p.x);record[@"Y"]=@(p.y);
    }
    if (!MTCPBridgeValidateCommand(record,session,sequence-1,
                    NSDate.date.timeIntervalSince1970))return NO;
    return [record writeToFile:kCommand atomically:YES];
}
void MTCPBridgeInvalidateSurface(NSString *session) {
    // Do not unlink another process's or a newer session's record.
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:kSurface];
    if (MTCPValidSession(session) && [record[@"Session"] isEqualToString:session])
        [[NSFileManager defaultManager] removeItemAtPath:kSurface error:nil];
}

// CarPlay owned-receiver state is a separate, short-lived and session-bound
// acknowledgement. It never grants CarPlay entitlement or creates an app scene.
NSString *MTCPBridgeReceiverAckFile(void) { return kReceiverAck; }
BOOL MTCPBridgeValidateReceiverAck(NSDictionary *record,NSString *session,NSTimeInterval now) {
    if (!MTCPHeader(record,@"receiver-ack",session,now))return NO;
    id context=record[@"ContextID"];
    if (![context isKindOfClass:NSNumber.class] ||
        [context unsignedLongLongValue]==0 ||
        [context unsignedLongLongValue]>UINT32_MAX)return NO;
    if (![record[@"DashboardOwned"] isKindOfClass:NSNumber.class] ||
        ![record[@"DashboardOwned"] boolValue])return NO;
    if (![record[@"RootClass"] isKindOfClass:NSString.class] ||
        ![record[@"RootClass"] isEqualToString:@"DBDashboardRootViewController"])return NO;
    for(NSString *key in @[@"X",@"Y",@"Width",@"Height"])
        if(!MTCPFiniteUnit(record[key]))return NO;
    double x=[record[@"X"] doubleValue],y=[record[@"Y"] doubleValue],
           w=[record[@"Width"] doubleValue],h=[record[@"Height"] doubleValue];
    return w>=0.50 && h>=0.50 && x+w<=1.0001 && y+h<=1.0001;
}
BOOL MTCPBridgeWriteReceiverAck(NSString *session,uint32_t contextID,CGRect b) {
    NSString *p=NSProcessInfo.processInfo.processName;
    if (!([p isEqualToString:@"CarPlay"] || [p isEqualToString:@"CarPlayApp"]) ||
        !MTCPBridgeExplicitOptIn() || !MTCPValidSession(session) || contextID==0 ||
        !isfinite(b.origin.x) || !isfinite(b.origin.y) ||
        !isfinite(b.size.width) || !isfinite(b.size.height))return NO;
    NSDictionary *surface=MTCPBridgeReadSurface(session);
    if (![surface[@"ContextID"] isEqual:@(contextID)])return NO;
    NSDictionary *ack=@{@"Version":@1,@"Kind":@"receiver-ack",
       @"Session":session,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
       @"ContextID":@(contextID),@"DashboardOwned":@YES,
       @"RootClass":@"DBDashboardRootViewController",
       @"X":@(b.origin.x),@"Y":@(b.origin.y),
       @"Width":@(b.size.width),@"Height":@(b.size.height)};
    if (!MTCPBridgeValidateReceiverAck(ack,session,NSDate.date.timeIntervalSince1970))return NO;
    return [ack writeToFile:kReceiverAck atomically:YES];
}
NSDictionary *MTCPBridgeReadReceiverAck(NSString *session) {
    if (!MTCPBridgeExplicitOptIn() || !MTCPValidSession(session))return nil;
    NSDictionary *surface=MTCPBridgeReadSurface(session);
    NSDictionary *ack=[NSDictionary dictionaryWithContentsOfFile:kReceiverAck];
    if (!MTCPBridgeValidateReceiverAck(ack,session,NSDate.date.timeIntervalSince1970) ||
        ![ack[@"ContextID"] isEqual:surface[@"ContextID"]])return nil;
    return ack;
}
void MTCPBridgeInvalidateReceiverAck(NSString *session) {
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:kReceiverAck];
    if (MTCPValidSession(session) && [record[@"Session"] isEqualToString:session])
        [[NSFileManager defaultManager] removeItemAtPath:kReceiverAck error:nil];
}
