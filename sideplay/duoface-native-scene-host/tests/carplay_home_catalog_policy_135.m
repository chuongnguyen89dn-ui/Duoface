#import <Foundation/Foundation.h>
#import "../DFCarPlayHomeCatalogPolicy.h"
static int count=0;
static void check(NSString *what,NSArray *native,NSArray *installed,NSArray *enabled,
                  NSArray *expectedBridge, NSArray *expectedHome) {
    NSArray *bridged=DFHomeBridgeBundleIDs(installed,enabled,native);
    NSArray *home=DFHomeExpectedBundleIDs(native,installed,enabled);
    if (![bridged isEqualToArray:expectedBridge] || ![home isEqualToArray:expectedHome]) {
        NSLog(@"QA135 FAIL %@ bridge=%@ expected=%@ home=%@ expected=%@",
              what,bridged,expectedBridge,home,expectedHome);
        exit(1);
    }
    ++count;
}
int main(void) {
    @autoreleasepool {
        NSArray *native=@[@"com.apple.Maps",@"com.apple.MobileSMS"];
        NSArray *installed=@[@"com.apple.Maps",@"com.google.ios.youtube",
                              @"com.gofa.nav",@"com.apple.mobileipod"];
        check(@"empty",native,installed,@[],@[],native);
        check(@"one youtube",native,installed,@[@"com.google.ios.youtube"],
              @[@"com.google.ios.youtube"],
              @[@"com.apple.Maps",@"com.apple.MobileSMS",@"com.google.ios.youtube"]);
        check(@"two selected",native,installed,@[@"com.gofa.nav",@"com.google.ios.youtube"],
              @[@"com.gofa.nav",@"com.google.ios.youtube"],
              @[@"com.apple.Maps",@"com.apple.MobileSMS",@"com.gofa.nav",@"com.google.ios.youtube"]);
        check(@"native preserved no duplicate",native,installed,
              @[@"com.apple.Maps",@"com.google.ios.youtube"],
              @[@"com.google.ios.youtube"],
              @[@"com.apple.Maps",@"com.apple.MobileSMS",@"com.google.ios.youtube"]);
        check(@"uninstalled denied",native,installed,@[@"com.fake.uninstalled"],@[],native);
        check(@"dedup enabled",native,installed,@[@"com.google.ios.youtube",
              @"com.google.ios.youtube"],@[@"com.google.ios.youtube"],
              @[@"com.apple.Maps",@"com.apple.MobileSMS",@"com.google.ios.youtube"]);
        check(@"excluded springboard",native,installed,@[@"com.apple.springboard"],@[],native);
        check(@"excluded own app",native,installed,@[@"com.duoface.native.scenehost"],@[],native);
        check(@"apple user app",native,installed,@[@"com.apple.mobileipod"],
              @[@"com.apple.mobileipod"],
              @[@"com.apple.Maps",@"com.apple.MobileSMS",@"com.apple.mobileipod"]);
        check(@"missing-enabled fails closed",native,installed,nil,@[],native);
        check(@"missing-installed fails closed",native,nil,@[@"com.google.ios.youtube"],@[],native);
        check(@"missing-native fails closed",nil,installed,@[@"com.google.ios.youtube"],@[],@[]);
        check(@"do not add invalid entries",native,installed,@[@"com.google.ios.youtube",@42],
              @[@"com.google.ios.youtube"],
              @[@"com.apple.Maps",@"com.apple.MobileSMS",@"com.google.ios.youtube"]);
        check(@"native duplicates stable",@[@"com.apple.Maps",@"com.apple.Maps"],installed,@[],
              @[],@[@"com.apple.Maps"]);
        check(@"deny disabled-but-installed",native,installed,@[@"com.gofa.nav"],
              @[@"com.gofa.nav"],
              @[@"com.apple.Maps",@"com.apple.MobileSMS",@"com.gofa.nav"]);
        NSLog(@"QA135_FIRSTPARTY_HOME_CATALOG_POLICY_PASS tests=%d",count);
    }
    return 0;
}
