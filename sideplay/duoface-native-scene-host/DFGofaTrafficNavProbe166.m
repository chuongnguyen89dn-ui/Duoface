// QA166: evidence-only GOFA traffic/nav source discovery, NOT an alert producer.
// CarPlayPro Speed 0.9.97 static symbols name SpeedBoardModel / DatapointModel
// and notifications, but do not prove GOFA runtime types or event payloads.
// This probe changes no GOFA methods and never reads route, location or alerts.
// It is only compiled on the QA166 branch until source/ABI and device QA pass.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <stdlib.h>

static NSString *const DF166LogFile =
    @"/var/mobile/Library/Logs/DuoFaceTrafficNav166.log";
static BOOL DF166ValidIdentifier(NSString *value) {
    if (![value isKindOfClass:NSString.class] || value.length==0 ||
        value.length>120) return NO;
    NSCharacterSet *allowed=[NSCharacterSet characterSetWithCharactersInString:
        @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:$"];
    return [value rangeOfCharacterFromSet:allowed.invertedSet].location==NSNotFound;
}
static void DF166Log(NSString *line) {
    if (!line || line.length>400) return;
    @synchronized(NSFileManager.defaultManager) {
        NSFileManager *fm=NSFileManager.defaultManager;
        NSString *dir=DF166LogFile.stringByDeletingLastPathComponent;
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                      attributes:nil error:nil];
        if (![fm fileExistsAtPath:DF166LogFile])
            [fm createFileAtPath:DF166LogFile contents:[NSData data] attributes:nil];
        NSFileHandle *h=[NSFileHandle fileHandleForWritingAtPath:DF166LogFile];
        if (!h) return;
        @try {
            [h seekToEndOfFile];
            // Fixed code-owned identifiers only. No GPS, address, text or UUID.
            NSString *row=[NSString stringWithFormat:@"QA166 %.0f %@\n",
                      NSDate.date.timeIntervalSince1970,line];
            [h writeData:[row dataUsingEncoding:NSUTF8StringEncoding]];
        } @catch(NSException *exception) {
            (void)exception;
        } @finally {
            [h closeFile];
        }
    }
}
static BOOL DF166InterestingName(NSString *name) {
    if (!DF166ValidIdentifier(name)) return NO;
    return [name containsString:@"GOFA"] &&
        ([name containsString:@"Board"] ||
         [name containsString:@"Datapoint"] ||
         [name containsString:@"Direction"] ||
         [name containsString:@"Navigation"]);
}
static void DF166InspectClass(Class cls) {
    NSString *name=NSStringFromClass(cls);
    if (!DF166InterestingName(name)) return;
    DF166Log([NSString stringWithFormat:@"runtime-class=%@",name]);
    // Method *presence* and signature only, never call an unverified method.
    for (NSString *selectorName in @[
        @"currentAllowSpeed",@"notificationSpeedBoard",
        @"notificationNextBoard",@"notificationOtherBoard",
        @"pushOtherBoardToCarplay",@"flutterDirection",
        @"currentRoute",@"distanceRemaining"]) {
        SEL sel=NSSelectorFromString(selectorName);
        Method method=class_getInstanceMethod(cls,sel);
        BOOL isClassMethod=NO;
        if (!method) {
            method=class_getClassMethod(cls,sel);
            isClassMethod=(method!=NULL);
        }
        if (!method) continue;
        const char *enc=method_getTypeEncoding(method);
        NSString *type=enc?[NSString stringWithUTF8String:enc]:@"unknown";
        if (!DF166ValidIdentifier(type)) type=@"encoding-complex";
        DF166Log([NSString stringWithFormat:@"method=%@.%@ type=%@ classMethod=%d",
                 name,selectorName,type,isClassMethod]);
    }
}
static void DF166InspectRuntime(void) {
    unsigned int count=0;
    Class *classes=objc_copyClassList(&count);
    if (!classes) return;
    NSUInteger matched=0;
    for (unsigned int i=0;i<count && matched<40;i++) {
        NSString *name=NSStringFromClass(classes[i]);
        if (!DF166InterestingName(name)) continue;
        DF166InspectClass(classes[i]);
        matched++;
    }
    free(classes);
    DF166Log([NSString stringWithFormat:@"runtime-scan complete matches=%lu",
             (unsigned long)matched]);
}
static void DF166ObserveKnownNames(void) {
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
    // These tokens appear in CarPlayPro strings. Their *use as notification
    // names* has NOT been verified; no event does not prove GOFA lacks data.
    for (NSString *name in @[@"notificationSpeedBoard",
                              @"notificationNextBoard",
                              @"notificationOtherBoard"]) {
        [center addObserverForName:name object:nil queue:nil
                       usingBlock:^(NSNotification *note) {
            NSString *klass=note.object?NSStringFromClass([note.object class]):@"none";
            if (!DF166ValidIdentifier(klass)) klass=@"unidentified";
            // Only type, not notification object/userInfo values or route text.
            DF166Log([NSString stringWithFormat:@"candidate-event=%@ objectClass=%@ payloadKeys=%lu",
                     name,klass,(unsigned long)note.userInfo.count]);
        }];
    }
    DF166Log(@"candidate-notification-observers-installed; event names unverified");
}
__attribute__((constructor)) static void DF166StartEvidenceOnly(void) {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.lumi.GOFA"])
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DF166Log(@"GOFA-process-only structural probe installed; alerts/nav NOT connected");
            DF166ObserveKnownNames();
            DF166InspectRuntime();
            // Repeat after delayed GOFA Swift module initialization.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(12*NSEC_PER_SEC)),
                           dispatch_get_main_queue(),^{ DF166InspectRuntime(); });
        });
    }
}
