// Foundation-only routing policy: native OS Maps MUST NOT become phone scenes.
#import <Foundation/Foundation.h>
#import "../DFCarPlayAppRoute178.h"
#include <stdio.h>
#define CHECK(x) do {if(!(x)){fprintf(stderr,"DF178 ROUTE FAIL %d: %s\n",__LINE__,#x);return 1;}}while(0)
int main(void){@autoreleasepool {
 NSArray *installed=@[@"com.google.Maps",@"com.waze.iphone",@"com.lumi.GOFA",
                        @"com.apple.mobilesafari",@"com.google.ios.youtube"];
 NSArray *enabled=@[@"com.google.Maps",@"com.waze.iphone",@"com.lumi.GOFA",
                      @"com.apple.mobilesafari"];
 NSArray *native=@[@"com.google.Maps",@"com.waze.iphone"];
 CHECK(DF178RouteForSelectedBundle(@"com.google.Maps",installed,enabled,native)==DF178NativeMapReady);
 CHECK(DF178RouteForSelectedBundle(@"com.waze.iphone",installed,enabled,native)==DF178NativeMapReady);
 CHECK(DF178RouteForSelectedBundle(@"com.google.Maps",installed,enabled,nil)==DF178NativeMapUnverified);
 CHECK(DF178RouteForSelectedBundle(@"com.google.Maps",installed,enabled,@[])==DF178NativeMapUnverified);
 CHECK(DF178RouteForSelectedBundle(@"com.lumi.GOFA",installed,enabled,native)==DF178PhoneAppBridge);
 CHECK(DF178RouteForSelectedBundle(@"com.apple.mobilesafari",installed,enabled,native)==DF178PhoneAppBridge);
 CHECK(DF178RouteForSelectedBundle(@"com.google.ios.youtube",installed,enabled,native)==DF178AppUnavailable);
 CHECK(DF178RouteForSelectedBundle(@"com.fake.uninstalled",installed,enabled,native)==DF178AppUnavailable);
 CHECK(DF178RouteForSelectedBundle(@"com.apple.springboard",installed,enabled,native)==DF178AppUnavailable);
 puts("DF178_NATIVE_MAP_VS_PHONE_APPBRIDGE_POLICY_PASS");return 0;
}}
