// QA167: extend QA166 original-CarPlayPro-verified GOFA notification observer
// with *type-only* runtime schema and privacy-limited Darwin notify handoff.
// No method swizzling, no vendor code, no route/position/alert values, no UI.
// Original confirmed names: notificationNextBoard / notificationOtherBoard /
// notificationSpeedBoard (SpeedAlerts.dylib at 0x3ce1c).
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CarPlay/CarPlay.h>
// Independent, public-CarPlay-type route reader: only if original GOFA
// notifications explicitly carry a CPManeuver, never a guessed Swift model.
FOUNDATION_EXPORT BOOL DF168PublishNativeCarPlayManeuver(CPManeuver *,CPTravelEstimates *);
#import <objc/runtime.h>
#import <notify.h>
#import <math.h>
#import <stdint.h>
#import "DF167GOFAEventProtocol.h"

static NSString *const DF166LogFile =
    @"/var/mobile/Library/Logs/DuoFaceTrafficNav166.log";
static NSUInteger DF167EventLogCount;
static int DF167NotifyToken=-1;
static uint8_t DF167Sequence;
static BOOL DF166ValidIdentifier(NSString *value) {
    if (![value isKindOfClass:NSString.class] || value.length==0 ||
        value.length>120) return NO;
    NSCharacterSet *allowed=[NSCharacterSet characterSetWithCharactersInString:
        @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:$"];
    return [value rangeOfCharacterFromSet:allowed.invertedSet].location==NSNotFound;
}
static NSString *DF167SafeKey(id raw) {
    if (![raw isKindOfClass:NSString.class])return @"[nonstring-key]";
    NSString *key=raw;
    if (!DF166ValidIdentifier(key) || key.length>48)return @"[redacted-key]";
    NSString *lower=key.lowercaseString;
    for (NSString *part in @[@"token",@"cookie",@"secret",@"password",@"auth",
                               @"latitude",@"longitude",@"address",@"user",
                               @"email",@"phone",@"routeid",@"deviceid"]) {
        if ([lower containsString:part])return @"[sensitive-key]";
    }
    return key;
}
static NSString *DF167SafeClass(id obj) {
    if (!obj)return @"none";
    NSString *name=NSStringFromClass(object_getClass(obj));
    if (!DF166ValidIdentifier(name))return @"unidentified";
    if (name.length>80)return @"unidentified";
    return name;
}
static void DF166Log(NSString *line) {
    if (!line || line.length>650)return;
    // System log remains available when GOFA sandbox blocks the shared file.
    // Only sanitized schema metadata is emitted; never payload or location values.
    NSLog(@"[DuoFaceGOFAProbe QA171] %@",line);
    // The GOFA process may not have cross-sandbox write permission for
    // /var/mobile/Library/Logs. The Darwin state below is a separate,
    // always data-free manual export fallback; do not claim log persisted.
    @synchronized(NSFileManager.defaultManager) {
        NSFileManager *fm=NSFileManager.defaultManager;
        NSString *dir=DF166LogFile.stringByDeletingLastPathComponent;
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                      attributes:nil error:nil];
        NSDictionary *attrs=[fm attributesOfItemAtPath:DF166LogFile error:nil];
        unsigned long long existingSize=[attrs[NSFileSize] unsignedLongLongValue];
        if (existingSize>128*1024)
            [fm removeItemAtPath:DF166LogFile error:nil]; // own diagnostic only
        if (![fm fileExistsAtPath:DF166LogFile])
            [fm createFileAtPath:DF166LogFile contents:[NSData data] attributes:nil];
        NSFileHandle *h=[NSFileHandle fileHandleForWritingAtPath:DF166LogFile];
        if (!h)return;
        @try {
            [h seekToEndOfFile];
            NSString *row=[NSString stringWithFormat:@"QA171 %.0f %@\n",
                        NSDate.date.timeIntervalSince1970,line];
            [h writeData:[row dataUsingEncoding:NSUTF8StringEncoding]];
        } @catch(NSException *ex) {
            (void)ex;
        } @finally {
            [h closeFile];
        }
    }
}
static BOOL DF166InterestingName(NSString *name) {
    return DF166ValidIdentifier(name) && [name containsString:@"GOFA"] &&
        ([name containsString:@"Board"] || [name containsString:@"Datapoint"] ||
         [name containsString:@"Direction"] || [name containsString:@"Navigation"]);
}
static void DF166InspectClass(Class cls) {
    NSString *name=NSStringFromClass(cls);
    if (!DF166InterestingName(name))return;
    DF166Log([NSString stringWithFormat:@"runtime-class=%@",name]);
    for (NSString *selName in @[
         @"currentAllowSpeed",@"notificationSpeedBoard",
         @"notificationNextBoard",@"notificationOtherBoard",
         @"pushOtherBoardToCarplay",@"flutterDirection",
         @"currentRoute",@"distanceRemaining"]) {
        SEL sel=NSSelectorFromString(selName);
        Method method=class_getInstanceMethod(cls,sel);
        BOOL classMethod=NO;
        if (!method) {method=class_getClassMethod(cls,sel);classMethod=(method!=NULL);}
        if (!method)continue;
        const char *enc=method_getTypeEncoding(method);
        NSString *type=enc?[NSString stringWithUTF8String:enc]:@"unknown";
        if (!DF166ValidIdentifier(type))type=@"encoding-complex";
        DF166Log([NSString stringWithFormat:@"method=%@.%@ type=%@ classMethod=%d",
                  name,selName,type,classMethod]);
    }
}
static void DF166InspectRuntime(void) {
    unsigned int count=0;Class *classes=objc_copyClassList(&count);
    if(!classes)return;
    NSUInteger matched=0;
    for (unsigned int i=0;i<count && matched<40;i++) {
        NSString *name=NSStringFromClass(classes[i]);
        if(!DF166InterestingName(name))continue;
        DF166InspectClass(classes[i]);matched++;
    }
    free(classes);
    DF166Log([NSString stringWithFormat:@"runtime-scan complete matches=%lu",
              (unsigned long)matched]);
}
static uint8_t DF167Kind(id obj) {
    if(!obj)return 0;
    if([obj isKindOfClass:NSDictionary.class])return 1;
    if([obj isKindOfClass:NSArray.class])return 2;
    if([[DF167SafeClass(obj) uppercaseString] containsString:@"GOFA"])return 3;
    return 4;
}
static void DF167PublishEvidence(NSInteger event,NSUInteger keys,uint8_t kind) {
    if(event<1||event>3)return;
    if(DF167NotifyToken<0) {
        int token=-1;
        if(notify_register_check(DF167_GOFA_NOTIFY_NAME,&token)!=NOTIFY_STATUS_OK) {
            DF166Log(@"QA167 cross-process evidence transport unavailable");
            return;
        }
        DF167NotifyToken=token;
    }
    double seconds=NSProcessInfo.processInfo.systemUptime;
    if(!isfinite(seconds)||seconds<0||seconds>DF167_GOFA_MAX_UPTIME)return;
    DF167GOFAEvent e={(uint8_t)event,(uint8_t)MIN(keys,255),
                       kind,(uint32_t)floor(seconds),++DF167Sequence};
    uint64_t encoded=0;
    if(!DF167GOFAEncode(e,&encoded))return;
    if(notify_set_state(DF167NotifyToken,encoded)==NOTIFY_STATUS_OK) {
        (void)notify_post(DF167_GOFA_NOTIFY_NAME);
    } else DF166Log(@"QA167 notify_set_state failed (no delivery proof)");
}
static void DF167SummarizeNSDictionary(NSDictionary *dict,NSString *label) {
    if(![dict isKindOfClass:NSDictionary.class])return;
    NSArray *keys=[dict.allKeys sortedArrayUsingComparator:^NSComparisonResult(id a,id b){
        return [DF167SafeKey(a) compare:DF167SafeKey(b)];
    }];
    NSUInteger count=MIN((NSUInteger)12,keys.count);
    NSMutableArray<NSString *> *schema=[NSMutableArray arrayWithCapacity:count];
    for(NSUInteger i=0;i<count;i++) {
        id key=keys[i];
        id value=dict[key]; // type ONLY. Never log description or contents.
        NSString *type=DF167SafeClass(value);
        [schema addObject:[NSString stringWithFormat:@"%@:%@",DF167SafeKey(key),type]];
    }
    DF166Log([NSString stringWithFormat:@"schema %@ entries=%lu keysAndTypes=%@",
              label,(unsigned long)dict.count,[schema componentsJoinedByString:@","]]);
}
static void DF167SummarizeObject(id obj) {
    if(!obj)return;
    if([obj isKindOfClass:NSDictionary.class]) {
        DF167SummarizeNSDictionary(obj,@"object-dict");
        return;
    }
    if([obj isKindOfClass:NSArray.class]) {
        NSArray *items=obj;
        DF166Log([NSString stringWithFormat:@"schema object-array count=%lu firstClass=%@",
                  (unsigned long)items.count,DF167SafeClass(items.firstObject)]);
        return;
    }
    NSString *classname=DF167SafeClass(obj);
    if(![classname containsString:@"GOFA"])return;
    unsigned int n=0;
    objc_property_t *properties=class_copyPropertyList(object_getClass(obj),&n);
    NSMutableArray<NSString *> *names=[NSMutableArray array];
    for(unsigned int i=0;i<n&&i<12;i++) {
        NSString *name=@(property_getName(properties[i])?: "");
        if(DF166ValidIdentifier(name))
            [names addObject:DF167SafeKey(name)];
    }
    free(properties);
    DF166Log([NSString stringWithFormat:@"schema gofa-object class=%@ propertyCount=%u propertyNames=%@",
              classname,n,[names componentsJoinedByString:@","]]);
}
static NSInteger DF167EventId(NSString *name) {
    if([name isEqualToString:@"notificationNextBoard"])return 1;
    if([name isEqualToString:@"notificationOtherBoard"])return 2;
    if([name isEqualToString:@"notificationSpeedBoard"])return 3;
    return 0;
}
// QA175 (T5): the probe's bookkeeping (evidence sequence/token and
// the bounded event counter) is confined to this serial queue; the
// observer blocks hop here instead of running on GOFA's posting
// thread. Log content and behaviour are unchanged.
static dispatch_queue_t DF166Queue(void) {
    static dispatch_queue_t q; static dispatch_once_t once;
    dispatch_once(&once, ^{
        q = dispatch_queue_create("com.duoface.gofa.probe166",
                                  DISPATCH_QUEUE_SERIAL);
    });
    return q;
}
static void DF166ObserveKnownNames(void) {
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
    // NOW CONFIRMED by static original SpeedAlerts registration at 0x3ce1c.
    // Actual GOFA posting the events is still an on-device hypothesis.
    for(NSString *name in @[@"notificationNextBoard",
                             @"notificationOtherBoard",
                             @"notificationSpeedBoard"]) {
        [center addObserverForName:name object:nil queue:nil
                       usingBlock:^(NSNotification *note) {
          NSDictionary *info=note.userInfo;
          id object=note.object;
          dispatch_async(DF166Queue(), ^{
            NSUInteger keys=info.count;
            uint8_t kind=DF167Kind(object);
            // Export-only proof from GOFA to DuoFace host via Darwin notify.
            DF167PublishEvidence(DF167EventId(name),keys,kind);
            // QA168: no private GOFA ABI assumptions. If an original event
            // actually carries a public CPManeuver object, its Apple-provided
            // distance/instruction may be forwarded; otherwise no turn.
            id route=object;
            if([route isKindOfClass:NSArray.class])route=[route firstObject];
            if([route isKindOfClass:CPManeuver.class]) {
                CPManeuver *maneuver=(CPManeuver *)route;
                (void)DF168PublishNativeCarPlayManeuver(
                    maneuver,maneuver.initialTravelEstimates);
            }
            NSUInteger index=0;
            @synchronized(NSNotificationCenter.class) {index=++DF167EventLogCount;}
            if(index>80)return; // bound ONLY privacy logs, never drop live source
            NSString *klass=DF167SafeClass(object);
            DF166Log([NSString stringWithFormat:@"candidate-event=%@ objectClass=%@ payloadKeys=%lu",
                     name,klass,(unsigned long)keys]);
            DF167SummarizeNSDictionary(info,@"userInfo");
            DF167SummarizeObject(object);
          });
        }];
    }
    DF166Log(@"GOFA original candidate-notification-observers-installed; QA167 types-only");
}
__attribute__((constructor)) static void DF166StartEvidenceOnly(void) {
    @autoreleasepool {
        if(![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.lumi.GOFA"])return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DF166Log(@"GOFA-process-only structural probe installed; alerts/nav NOT connected");
            DF166ObserveKnownNames();
            DF166InspectRuntime();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(12*NSEC_PER_SEC)),
                           dispatch_get_main_queue(),^{DF166InspectRuntime();});
        });
    }
}
