// Independent SpringBoard phone-foreground eviction for a selected CarPlay app.
// Bounded conditional native phone Home branch: the real phone frontmost must
// be the exact selected bundle. Never issue guessed SBMainWorkspace transitions.
#ifndef DF_PHONE_EVICTION_153_H
#define DF_PHONE_EVICTION_153_H
#import "DFNativePrepOnce152.h"
static DF152Preparation DF153PhonePrep;
static NSString *DF153PhoneRID;

static BOOL DF153BoolGetter(id object,const char *getter,BOOL *value) {
 if(value)*value=NO;
 Method m=object?class_getInstanceMethod(object_getClass(object),sel_registerName(getter)):NULL;
 if(!m)return NO;
 const char *encoding=method_getTypeEncoding(m);
 BOOL asBool=!strcmp(encoding,"B16@0:8");
 BOOL asChar=!strcmp(encoding,"c16@0:8");
 if(!asBool&&!asChar)return NO;
 @try {
   if(value)*value=asBool?
       ((BOOL(*)(id,SEL))objc_msgSend)(object,sel_registerName(getter)):
       ((signed char(*)(id,SEL))objc_msgSend)(object,sel_registerName(getter))!=0;
   return YES;
 } @catch(NSException *e) {
   DF144Log(@"qa153-foreground-bool-exception",e.name);
   return NO;
 }
}
static void DF153PhoneRevoke(void) {
 DF152Revoke(&DF153PhonePrep);
 DF153PhoneRID=nil;
}
static void DF153PhoneResume(uint64_t generation,NSString *rid,NSString *cause,
                              void (^continuation)(void)) {
 if(!NSThread.isMainThread) {
   dispatch_async(dispatch_get_main_queue(),^{
     DF153PhoneResume(generation,rid,cause,continuation);
   });
   return;
 }
 if(![DF153PhoneRID isEqualToString:rid] ||
    !DF152FinishOnce(&DF153PhonePrep,generation)) {
   DF144Log(@"qa153-phone-old-completion-rejected",
       [NSString stringWithFormat:@"req=%@ cause=%@",rid,cause]);
   return;
 }
 DF144Log(@"qa153-phone-continue",
       [NSString stringWithFormat:@"req=%@ cause=%@",rid,cause]);
 if(continuation)continuation();
}
static void DF153PreparePhoneForSelectedApp(NSString *rid,NSString *target,
                                             void (^continuation)(void)) {
 uint64_t generation=DF152Begin(&DF153PhonePrep);
 DF153PhoneRID=[rid copy];
 if(!NSThread.isMainThread || !rid.length || !target.length || !continuation ||
    ![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"]) {
   DF153PhoneResume(generation,rid,@"not-SpringBoard-or-no-request",continuation);
   return;
 }
 // Never move an unrelated phone foreground app. All object getters are
 // guarded by DF144Get's exact "@16@0:8" runtime method ABI check.
 id springboard=UIApplication.sharedApplication;
 id front=DF144Get(springboard,"_accessibilityFrontMostApplication");
 id bundle=DF144Get(front,"bundleIdentifier");
 id process=DF144Get(front,"processState");
 BOOL foreground=NO;
 if(!front || ![bundle isKindOfClass:NSString.class] ||
    ![bundle isEqualToString:target] ||
    !DF153BoolGetter(process,"isForeground",&foreground) || !foreground) {
   DF153PhoneResume(generation,rid,@"different-or-inactive-phone-foreground",continuation);
   return;
 }
 Class controllerClass=objc_getClass("SBUIController");
 Method shared=controllerClass?
    class_getClassMethod(controllerClass,sel_registerName("sharedInstance")):NULL;
 if(!shared || strcmp(method_getTypeEncoding(shared),"@16@0:8")) {
   DF153PhoneResume(generation,rid,@"phone-controller-ABI-unsupported",continuation);
   return;
 }
 @try {
   id controller=((id(*)(id,SEL))objc_msgSend)(controllerClass,sel_registerName("sharedInstance"));
   Method click=controller?
     class_getInstanceMethod(object_getClass(controller),sel_registerName("clickedMenuButton")):NULL;
   if(!click || strcmp(method_getTypeEncoding(click),"v16@0:8")) {
     DF153PhoneResume(generation,rid,@"phone-home-ABI-unsupported",continuation);
     return;
   }
   DF144Log(@"qa153-verified-phone-target-eviction",
       [NSString stringWithFormat:@"req=%@ target=%@ front=%@",
          rid,target,NSStringFromClass([front class])]);
   // The only phone-mutating call, after verifying the phone frontmost is
   // precisely the selected CarPlay app; this is not a generic Home press.
   ((void(*)(id,SEL))objc_msgSend)(controller,sel_registerName("clickedMenuButton"));
   // The genuine route also has a bounded fallback. No guessed callback ABI.
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.12*NSEC_PER_SEC)),
     dispatch_get_main_queue(),^{
       DF153PhoneResume(generation,rid,@"verified-phone-home-fallback-120ms",continuation);
     });
 } @catch(NSException *e) {
   DF144Log(@"qa153-phone-home-exception",
     [NSString stringWithFormat:@"req=%@ name=%@",rid,e.name]);
   DF153PhoneResume(generation,rid,@"phone-home-exception",continuation);
 }
}
#endif
