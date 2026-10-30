// Real Foundation executable: reuse ONE approved-install catalog for CarPlay.
#import <Foundation/Foundation.h>
#import "DFCarPlaySelectedAppCatalog.h"
#import <stdlib.h>
static void expect(BOOL ok,const char *message) {
 if(!ok){fprintf(stderr,"QA133_CATALOG_FAILED:%s\n",message);abort();}
}
int main(void) {
 @autoreleasepool {
   NSArray *installed=@[@"com.google.ios.youtube",@"com.lumi.GOFA",
      @"com.apple.Maps",@"com.apple.springboard",
      @"com.google.ios.youtube",@"com.duoface.native.scenehost"];
   expect(DFCarPlaySelectedInstalledBundleIDs(installed,nil).count==0,
     "unconfigured must not show");
   expect(DFCarPlaySelectedInstalledBundleIDs(installed,@[]).count==0,
     "disabled-all must not show");
   NSArray *selected=DFCarPlaySelectedInstalledBundleIDs(installed,
       @[@"com.lumi.GOFA",@"com.google.ios.youtube",
         @"com.phantom.missing",@"com.apple.springboard",@"com.apple.Maps"]);
   expect(selected.count==3,"filter unavailable, protected and duplicates");
   expect([selected isEqualToArray:@[@"com.google.ios.youtube",@"com.lumi.GOFA",
                                   @"com.apple.Maps"]],
     "preserve stable installed catalog order");
   expect(![selected containsObject:@"com.phantom.missing"],"reject not installed");
   expect(![selected containsObject:@"com.apple.springboard"],"reject Apple OS service");
   expect(DFCarPlaySelectedInstalledBundleIDs(@[],@[@"com.lumi.GOFA"]).count==0,
      "removed app disappears");
   expect(DFCarPlaySelectedInstalledBundleIDs(@[@"com.lumi.GOFA"],@[]).count==0,
      "disable clears catalog even if scene previously selected");
   NSLog(@"QA133_SHARED_APPROVED_INSTALLED_CARPLAY_APP_CATALOG_RUNTIME_PASS");
 }
 return 0;
}
