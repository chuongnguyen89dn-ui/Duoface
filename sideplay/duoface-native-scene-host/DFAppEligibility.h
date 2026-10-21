// Source-owned application inventory policy for DuoFace iOS 16.
// Hosts third-party applications and known Apple user-facing applications;
// excludes SpringBoard services, CarPlay Home, Setup and DuoFace itself.
// Shared by the iPhone app and the SpringBoard hosted-app picker.
#import <Foundation/Foundation.h>
NS_INLINE BOOL DFIsEligibleAppID(NSString *bundleID) {
    if(![bundleID isKindOfClass:NSString.class] || bundleID.length==0)
        return NO;
    if([bundleID hasPrefix:@"com.duoface."])return NO;
    if(![bundleID hasPrefix:@"com.apple."])return YES;
    // Do not indiscriminately host com.apple.* service bundles. These are
    // actual user-facing Apple apps validated by bundle identifier, not
    // SpringBoard/CarPlay infrastructure.
    return [@[
       @"com.apple.Maps",
       @"com.apple.mobileipod",
       @"com.apple.mobilesafari",
       @"com.apple.podcasts",
       @"com.apple.TV",
       @"com.apple.MobileSMS",
       @"com.apple.mobilemail",
       @"com.apple.calculator",
       @"com.apple.weather",
       @"com.apple.AppStore",
       @"com.apple.MobileAddressBook",
       @"com.apple.mobilecal"
    ] containsObject:bundleID];
}
