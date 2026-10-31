// Execute the independent admission policy against fake Objective-C objects.
// No iPhone ABI, icon appearance or physical launch is claimed by this test.
#import <Foundation/Foundation.h>
static BOOL enabled=YES;
static NSArray *selection;
#define DF_HOME_PUBLISHER136_CONFIG_H
#define DF_ENABLED_APPS_POLICY_H
static BOOL DFHome136Enabled(void) {return enabled;}
static NSArray *DFConfiguredEnabledAppIDs(void) {return selection;}
static BOOL DFIsRecommendedAppID(NSString *bid) {
 return [bid isKindOfClass:NSString.class] && bid.length && ![bid hasPrefix:@"com.apple."];
}
static BOOL DFPickerAllowsApp(NSString *bid,NSArray *ids) {return [ids containsObject:bid];}
NSInteger DFHome136ReconcileVerifiedLibrary(id library) {(void)library;return 0;}
#import "../DFHomeAdmission138.m"

@interface DBApplicationInfo:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@property(nonatomic) BOOL launch;
- (void)setLaunchAsCarApplication:(BOOL)value;
- (id)carPlayDeclaration;
- (id)entitlementValueForKey:(id)key ofClass:(Class)cls;
@end
@implementation DBApplicationInfo
- (void)setLaunchAsCarApplication:(BOOL)value {self.launch=value;}
- (id)carPlayDeclaration {return nil;}
- (id)entitlementValueForKey:(id)key ofClass:(Class)cls {return DF138Entitlement2(self,_cmd,key,cls);}
@end
@interface CRCarPlayAppDeclaration:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@end
@implementation CRCarPlayAppDeclaration
@end
@interface TestPolicy:NSObject
@property(nonatomic) BOOL launchAsCarApplication;
@property(nonatomic) BOOL carPlaySupported;
@property(nonatomic) BOOL canDisplayOnCarScreen;
@property(nonatomic) BOOL launchUsingTemplateUI;
@end
@implementation TestPolicy
@end
static int originalCalls=0,factoryCalls=0;
static id nativeValue=nil;
static id original(id proxy,SEL sel,id key,Class cls) {
 (void)proxy;(void)sel;(void)key;(void)cls;++originalCalls;return nativeValue;
}
static id factory(id object,SEL sel) {(void)sel;++factoryCalls;return object;}
static id policyResult;
static id policyOriginal(id object,SEL sel,id arg) {(void)object;(void)sel;(void)arg;return policyResult;}
static id declarationOriginal(id object,SEL sel,id arg) {(void)object;(void)sel;(void)arg;return nil;}
#define CHECK(x) do { if(!(x)){NSLog(@"FAIL line %d: %s",__LINE__,#x);return 1;} } while(0)
int main(void) { @autoreleasepool {
 selection=@[@"test.selected"];
 DF138Granted=[NSMutableSet set];DF138Original2=original;
 DBApplicationInfo *app=[DBApplicationInfo new];app.bundleIdentifier=@"test.selected";
 SEL typed=sel_registerName("entitlementValueForKey:ofClass:");
 CHECK([DF138Entitlement2(app,typed,@"CARCapableApp",NSNumber.class) isEqual:@YES]);
 CHECK(originalCalls>=1);
 CHECK([DF138Granted containsObject:@"test.selected"]);
 // The actual regression: a valid BOOL setter must work without the absent
 // isCarPlaySupported getter used by QA136/137.
 CHECK(![app respondsToSelector:sel_registerName("isCarPlaySupported")]);
 // The setters belong to the original policy return, not DBApplicationInfo.
 CHECK(!DFHome138PromoteAdmittedInfo(app));CHECK(!app.launch);
 TestPolicy *policy=[TestPolicy new];policy.launchUsingTemplateUI=YES;
 policyResult=policy;DF138OriginalPolicy=policyOriginal;
 CHECK(DF138Policy(nil,NULL,app)==policy);
 CHECK(policy.launchAsCarApplication && policy.carPlaySupported && policy.canDisplayOnCarScreen);
 CHECK(!policy.launchUsingTemplateUI);CHECK(!app.launch);
 DF138OriginalDeclaration=declarationOriginal;
 id declared=DF138Declaration(CRCarPlayAppDeclaration.class,NULL,app);
 CHECK([DF138Bundle(declared) isEqualToString:@"test.selected"]);
 CHECK(!DF138Answer(app,@"CARCapableApp",NSDictionary.class,Nil,nil));
 CHECK(!DF138Answer(app,@"unrelated",NSNumber.class,Nil,nil));
 selection=@[];
 CHECK(!DF138Answer(app,@"CARCapableApp",NSNumber.class,Nil,nil));
 selection=@[@"test.selected"];
 enabled=NO;
 CHECK(!DF138Answer(app,@"CARCapableApp",NSNumber.class,Nil,nil));
 app.launch=NO;CHECK(!DFHome138PromoteAdmittedInfo(app));CHECK(!app.launch);
 policy.launchAsCarApplication=NO;
 CHECK(DF138Policy(nil,NULL,app)==policy);CHECK(!policy.launchAsCarApplication);
 enabled=YES;
 // Preserve a real native return, including an explicit NO, by identity.
 nativeValue=@NO;
 CHECK(DF138Entitlement2(app,typed,@"CARCapableApp",NSNumber.class)==nativeValue);
 nativeValue=@YES;
 CHECK(!DF138Answer(app,@"SBStarkCapable",NSNumber.class,Nil,nil));
 nativeValue=nil;
 app.bundleIdentifier=@"com.apple.Maps";selection=@[@"com.apple.Maps"];
 CHECK(!DF138Answer(app,@"CARCapableApp",NSNumber.class,Nil,nil));
 app.bundleIdentifier=@"test.unselected";
 CHECK(!DF138Answer(app,@"CARCapableApp",NSNumber.class,Nil,nil));
 DF138OriginalFactory=factory;enabled=NO;
 NSObject *library=[NSObject new];CHECK(DF138Factory(library,NULL)==library);
 CHECK(factoryCalls==1);
 NSLog(@"QA138 admission runtime: selected-only, disabled, typed, native passthrough, absent info getter, correct original policy receiver, declaration and factory identity PASS");
 return 0;
} }
