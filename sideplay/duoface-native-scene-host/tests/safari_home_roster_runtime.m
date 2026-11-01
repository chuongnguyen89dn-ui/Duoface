// Execute actual admission + FBS reconciler with controlled OS objects.
// This is an integration boundary test, not physical CarPlay icon evidence.
#import <Foundation/Foundation.h>
#import "../DFEnabledAppsPolicy.h"
static NSArray *selection;
static BOOL enabled=YES;
static NSArray *TestSelection(void){return selection;}
#define DFConfiguredEnabledAppIDs TestSelection
#define DF_HOME_PUBLISHER136_CONFIG_H
#define DF_HOME140_CONSENT_H
static BOOL DFHome136Enabled(void){return enabled;}
static BOOL DFHome140Enabled(void){return enabled;}
void DF137ObserveExistingAppInfo(id info,NSString *stage){(void)info;(void)stage;}
@interface TestHomeProcessInfo:NSObject
+ (instancetype)processInfo;
- (NSString *)processName;
- (NSOperatingSystemVersion)operatingSystemVersion;
@end
@implementation TestHomeProcessInfo
+ (instancetype)processInfo {static id p; if(!p)p=[self new];return p;}
- (NSString *)processName{return @"CarPlay";}
- (NSOperatingSystemVersion)operatingSystemVersion{return (NSOperatingSystemVersion){16,7,16};}
@end
#define NSProcessInfo TestHomeProcessInfo
#import "../DFHomeAdmission141.m"
#import "../DFHomePublisher136Core.m"
#undef NSProcessInfo
@interface LSApplicationProxy:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
+ (id)applicationProxyForIdentifier:(NSString *)bundle;
- (id)entitlementValueForKey:(id)key ofClass:(Class)expected;
@end
@implementation LSApplicationProxy
+ (id)applicationProxyForIdentifier:(NSString *)bundle {LSApplicationProxy *p=[self new];p.bundleIdentifier=bundle;return p;}
- (id)entitlementValueForKey:(id)key ofClass:(Class)expected {return DF141Entitlement2(self,_cmd,key,expected);}
@end
@interface LSApplicationWorkspace:NSObject
+ (id)defaultWorkspace;
- (NSArray *)allInstalledApplications;
@end
@implementation LSApplicationWorkspace
+ (id)defaultWorkspace {static id w;if(!w)w=[self new];return w;}
- (NSArray *)allInstalledApplications {
 NSMutableArray *a=[NSMutableArray new];
 for(NSString *bid in @[@"com.apple.mobilesafari",@"com.apple.Maps",@"org.videolan.vlc-ios",@"com.apple.springboard"])
  [a addObject:[LSApplicationProxy applicationProxyForIdentifier:bid]];
 return a;
}
@end
@interface CRCarPlayAppDeclaration:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@end
@implementation CRCarPlayAppDeclaration
@end
@interface DBApplicationInfo:LSApplicationProxy
@property(nonatomic,strong) id carPlayDeclaration;
@end
@implementation DBApplicationInfo
@end
@interface FBSApplicationLibrary:NSObject
@property(nonatomic,strong) NSMutableDictionary *records;
@property(nonatomic,strong) NSArray *notified;
@property(nonatomic) NSUInteger additions;
- (NSArray *)allInstalledApplications;
- (void)addApplicationProxy:(id)proxy withOverrideURL:(id)url;
- (id)applicationInfoForBundleIdentifier:(NSString *)bundle;
- (void)_notifyDidAddApplications:(NSArray *)infos;
@end
@implementation FBSApplicationLibrary
- (instancetype)init {if((self=[super init]))_records=[NSMutableDictionary new];return self;}
- (NSArray *)allInstalledApplications{return self.records.allValues;}
- (void)addApplicationProxy:(id)proxy withOverrideURL:(id)url {
 (void)url;++self.additions;DBApplicationInfo *i=[DBApplicationInfo new];i.bundleIdentifier=[proxy bundleIdentifier];self.records[i.bundleIdentifier]=i;
}
- (id)applicationInfoForBundleIdentifier:(NSString *)bundle{return self.records[bundle];}
- (void)_notifyDidAddApplications:(NSArray *)infos{self.notified=infos;}
@end
static id NativeNil(id obj,SEL sel,id key,Class expected){(void)obj;(void)sel;(void)key;(void)expected;return nil;}
#define CHECK(x) do{if(!(x)){NSLog(@"FAIL %d: %s",__LINE__,#x);return 1;}}while(0)
int main(void){@autoreleasepool {
 DF141Original2=NativeNil;DF141Granted=[NSMutableSet new];
 FBSApplicationLibrary *library=[FBSApplicationLibrary new];
 DBApplicationInfo *maps=[DBApplicationInfo new];maps.bundleIdentifier=@"com.apple.Maps";
 CRCarPlayAppDeclaration *native=[CRCarPlayAppDeclaration new];native.bundleIdentifier=maps.bundleIdentifier;maps.carPlayDeclaration=native;
 library.records[maps.bundleIdentifier]=maps;
 selection=@[@"com.apple.mobilesafari",@"com.apple.Maps",@"com.apple.springboard",@"com.fake.uninstalled"];
 // The two former gates provably reject the same selected Safari input.
 CHECK(!DFIsRecommendedAppID(@"com.apple.mobilesafari"));
 CHECK([@"com.apple.mobilesafari" hasPrefix:@"com.apple."]);
 CHECK(DFHome136ReconcileVerifiedLibrary(library)==1);
 DBApplicationInfo *safari=library.records[@"com.apple.mobilesafari"];
 CHECK(safari && [safari.carPlayDeclaration bundleIdentifier]);
 CHECK([[safari.carPlayDeclaration bundleIdentifier] isEqual:@"com.apple.mobilesafari"]);
 CHECK(library.notified.count==1 && library.notified[0]==safari);
 CHECK(library.additions==1 && library.records.count==2);
 CHECK(maps.carPlayDeclaration==native);
 CHECK(!library.records[@"com.apple.springboard"] && !library.records[@"org.videolan.vlc-ios"]);
 CHECK(DFHome136ReconcileVerifiedLibrary(library)==0 && library.additions==1);
 FBSApplicationLibrary *empty=[FBSApplicationLibrary new];selection=@[];
 CHECK(DFHome136ReconcileVerifiedLibrary(empty)==0 && empty.records.count==0);
 selection=@[@"com.apple.mobilesafari"];enabled=NO;
 CHECK(DFHome136ReconcileVerifiedLibrary(empty)==0 && empty.records.count==0);
 puts("SAFARI_SELECTED_ADMISSION_REAL_FBS_RECORD_DECLARATION_NOTIFY_NATIVE_PRESERVATION_PASS");
 return 0;
}}
