// Model the actual Log18 saved getter2 -> hooked getter3 forwarding path.
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#define DF_HOME_PUBLISHER136_CONFIG_H
#define DF_HOME140_CONSENT_H
#define DF_ENABLED_APPS_POLICY_H
static BOOL enabled=YES;
static NSArray *selection;
static BOOL DFHome136Enabled(void) {return enabled;}
static BOOL DFHome140Enabled(void) {return enabled;}
static NSArray *DFConfiguredEnabledAppIDs(void) {return selection;}
static BOOL DFIsRecommendedAppID(NSString *bid) {
 return [bid isKindOfClass:NSString.class] && bid.length &&
        ![bid hasPrefix:@"com.apple."] && ![bid hasPrefix:@"com.duoface."];
}
static BOOL DFPickerAllowsApp(NSString *bid,NSArray *ids) {return [ids containsObject:bid];}
NSInteger DFHome136ReconcileVerifiedLibrary(id library) {(void)library;return 0;}
#import "../DFHomeAdmission140.m"
#import "../DFHomeAdmission138.m"

@interface TestProxy140:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
- (id)entitlementValueForKey:(id)key ofClass:(Class)expected;
@end
@implementation TestProxy140
- (id)entitlementValueForKey:(id)key ofClass:(Class)expected {
 return DF140Entitlement2(self,_cmd,key,expected);
}
@end
@interface CRCarPlayAppDeclaration:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@end
@implementation CRCarPlayAppDeclaration
@end
@interface TestPolicy140:NSObject
@property(nonatomic) BOOL launchAsCarApplication;
@property(nonatomic) BOOL carPlaySupported;
@property(nonatomic) BOOL canDisplayOnCarScreen;
@property(nonatomic) BOOL launchUsingTemplateUI;
@end
@implementation TestPolicy140
@end
static id nativeValue;
static BOOL throwOnNativeRead=NO;
static _Thread_local unsigned int forwards140=0,maxDepth140=0,depth140=0;
static unsigned int forwards138=0,maxDepth138=0,depth138=0;
static id base3(id object,SEL cmd,id key,Class expected,Class values) {
 (void)object;(void)cmd;(void)key;(void)expected;(void)values;return nativeValue;
}
static id forwarding2_140(id object,SEL cmd,id key,Class expected) {
 (void)cmd;
 if(throwOnNativeRead && DF140NativeReadDepth)
   @throw [NSException exceptionWithName:@"TestNativeFailure" reason:@"guard cleanup" userInfo:nil];
 ++forwards140;++depth140;maxDepth140=MAX(maxDepth140,depth140);
 id result=DF140Entitlement3(object,
    sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:"),key,expected,Nil);
 --depth140;return result;
}
static id forwarding2_138(id object,SEL cmd,id key,Class expected) {
 (void)cmd;++forwards138;++depth138;maxDepth138=MAX(maxDepth138,depth138);
 // Test harness only: stop the old recursion instead of crashing the runner.
 id result=depth138>=10?@NO:DF138Entitlement3(object,
    sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:"),key,expected,Nil);
 --depth138;return result;
}
static id policyResult;
static int factoryCalls=0;
static id originalPolicy(id object,SEL cmd,id arg) {(void)object;(void)cmd;(void)arg;return policyResult;}
static id originalDeclaration(id object,SEL cmd,id arg) {(void)object;(void)cmd;(void)arg;return nil;}
static id originalFactory(id object,SEL cmd) {(void)cmd;++factoryCalls;return object;}
#define CHECK(x) do {if(!(x)){NSLog(@"FAIL line%d: %s",__LINE__,#x);return 1;}}while(0)
int main(void) {@autoreleasepool {
 selection=@[@"test.selected"];
 TestProxy140 *app=[TestProxy140 new];app.bundleIdentifier=@"test.selected";
 SEL two=sel_registerName("entitlementValueForKey:ofClass:");
 DF138Granted=[NSMutableSet set];DF138Original2=forwarding2_138;DF138Original3=base3;
 (void)DF138Entitlement2(app,two,@"CARCapableApp",NSNumber.class);
 CHECK(maxDepth138>=10 && forwards138>10);
 NSLog(@"QA138 negative control reproduces native2-to-hook3 recursive growth; harness cap=%u calls=%u",maxDepth138,forwards138);

 DF140Granted=[NSMutableSet set];DF140Original2=forwarding2_140;DF140Original3=base3;
 id value=DF140Entitlement2(app,two,@"CARCapableApp",NSNumber.class);
 CHECK([value isEqual:@YES]);CHECK(maxDepth140<=2);CHECK(forwards140<=3);
 CHECK(DF140NativeReadDepth==0);CHECK([DF140Granted containsObject:@"test.selected"]);
 NSLog(@"QA140 same forwarding path bounded: depth=%u calls=%u",maxDepth140,forwards140);

 // A real native return (including explicit NO) must retain its identity.
 [DF140Granted removeAllObjects];nativeValue=@YES;
 CHECK(DF140Entitlement2(app,two,@"CARCapableApp",NSNumber.class)==nativeValue);
 CHECK(DF140Granted.count==0);nativeValue=@NO;
 CHECK(DF140Entitlement2(app,two,@"CARCapableApp",NSNumber.class)==nativeValue);
 nativeValue=nil;enabled=NO;
 CHECK(DF140Entitlement2(app,two,@"CARCapableApp",NSNumber.class)==nil);
 enabled=YES;selection=@[];
 CHECK(DF140Entitlement2(app,two,@"CARCapableApp",NSNumber.class)==nil);
 selection=@[@"test.selected"];
 CHECK(DF140Entitlement2(app,two,@"unrelated",NSNumber.class)==nil);
 CHECK(DF140Entitlement2(app,two,@"CARCapableApp",NSDictionary.class)==nil);
 app.bundleIdentifier=@"com.apple.Maps";selection=@[@"com.apple.Maps"];
 CHECK(DF140Entitlement2(app,two,@"CARCapableApp",NSNumber.class)==nil);
 app.bundleIdentifier=@"test.selected";selection=@[@"test.selected"];

 throwOnNativeRead=YES;
 CHECK(DF140Entitlement3(app,NULL,@"CARCapableApp",NSNumber.class,Nil)==nil);
 CHECK(DF140NativeReadDepth==0);throwOnNativeRead=NO;
 CHECK([DF140Entitlement3(app,NULL,@"CARCapableApp",NSNumber.class,Nil) isEqual:@YES]);

 // Main-thread native lookup must not suppress a simultaneous worker query.
 DF140NativeReadDepth=1;
 __block id workerResult=nil;
 dispatch_semaphore_t finished=dispatch_semaphore_create(0);
 dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{@autoreleasepool {
   workerResult=DF140Entitlement3(app,NULL,@"CARCapableApp",NSNumber.class,Nil);
   dispatch_semaphore_signal(finished);
 }});
 CHECK(dispatch_semaphore_wait(finished,dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC))==0);
 CHECK([workerResult isEqual:@YES]);CHECK(DF140NativeReadDepth==1);
 DF140NativeReadDepth=0;

 DF140OriginalDeclaration=originalDeclaration;
 id declaration=DF140Declaration(CRCarPlayAppDeclaration.class,NULL,app);
 CHECK([DF140Bundle(declaration) isEqual:@"test.selected"]);
 TestPolicy140 *policy=[TestPolicy140 new];policy.launchUsingTemplateUI=YES;
 policyResult=policy;DF140OriginalPolicy=originalPolicy;
 CHECK(DF140Policy(nil,NULL,declaration)==policy);
 CHECK(policy.carPlaySupported && policy.canDisplayOnCarScreen && policy.launchAsCarApplication);
 CHECK(!policy.launchUsingTemplateUI);
 enabled=NO;policy.launchAsCarApplication=NO;
 CHECK(DF140Policy(nil,NULL,declaration)==policy);CHECK(!policy.launchAsCarApplication);
 DF140OriginalFactory=originalFactory;
 NSObject *library=[NSObject new];CHECK(DF140Factory(library,NULL)==library);CHECK(factoryCalls==1);
 NSLog(@"QA140_FORWARDING_REENTRY_EXCEPTION_TLS_NATIVE_DISABLED_POLICY_AND_FACTORY_PASS");
 return 0;
}}
