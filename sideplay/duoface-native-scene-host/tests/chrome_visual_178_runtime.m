// Runtime contract for own visual-only Chrome expiry policy, no UIKit/CarPlay.
#import <Foundation/Foundation.h>
#import "../DFChromeVisual178.h"
#include <stdio.h>
#define CHECK(x) do {if(!(x)){fprintf(stderr,"DF178 FAIL line %d: %s\n",__LINE__,#x);return 1;}}while(0)
int main(void) {@autoreleasepool {
 CHECK(DF178ChromeVisible(10.0,14.0,NO,NO));
 CHECK(DF178ChromeVisible(14.0,14.0,NO,NO));
 CHECK(!DF178ChromeVisible(14.01,14.0,NO,NO));
 CHECK(DF178ChromeVisible(20.0,14.0,YES,NO));
 CHECK(DF178ChromeVisible(20.0,14.0,NO,YES));
 CHECK(!DF178ChromeVisible(NAN,14.0,NO,NO));
 CHECK(!DF178ChromeVisible(10.0,NAN,NO,NO));
 CHECK(DF178ChromeExpiryGenerationCurrent(9,9));
 CHECK(!DF178ChromeExpiryGenerationCurrent(0,0));
 CHECK(!DF178ChromeExpiryGenerationCurrent(9,10));
 CHECK(fabs(DF178ChromeDelayUntilExpiry(10,14)-4.05)<0.0001);
 CHECK(fabs(DF178ChromeDelayUntilExpiry(13.9,14)-0.15)<0.0001);
 CHECK(fabs(DF178ChromeDelayUntilExpiry(15,14)-0.05)<0.0001);
 CHECK(DF178ChromeDelayUntilExpiry(NAN,14)>=0.05);
 puts("DF178_VISUAL_ONLY_LOGO_4S_POLICY_PASS");
 return 0;
}}
