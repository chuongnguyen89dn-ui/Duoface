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
#import <objc/runtime.h>
#import <string.h>
static Class TestRosterClass(const char *name) {
 if(!strcmp(name,"LSApplicationProxy"))return objc_getClass("DFSafariTestLSApplicationProxy");
 if(!strcmp(name,"LSApplicationWorkspace"))return objc_getClass("DFSafariTestLSApplicationWorkspace");
 if(!strcmp(name,"CRCarPlayAppDeclaration"))return objc_getClass("DFSafariTestCRCarPlayAppDeclaration");
 if(!strcmp(name,"DBApplicationInfo"))return objc_getClass("DFSafariTestDBApplicationInfo");
 if(!strcmp(name,"FBSApplicationLibrary"))return objc_getClass("DFSafariTestFBSApplicationLibrary");
 return objc_getClass(name);
}
#define objc_getClass TestRosterClass
#define NSProcessInfo TestHomeProcessInfo
#import "../DFHomeAdmission141.m"
#import "../DFHomePublisher136Core.m"
#undef NSProcessInfo
#undef objc_getClass
@interface DFSafariTestLSApplicationProxy:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
+ (id)applicationProxyForIdentifier:(NSString *)bundle;
- (id)entitlementValueForKey:(id)key ofClass:(Class)expected;
@end
@implementation DFSafariTestLSApplicationProxy
+ (id)applicationProxyForIdentifier:(NSString *)bundle {DFSafariTestLSApplicationProxy *p=[self new];p.bundleIdentifier=bundle;return p;}
- (id)entitlementValueForKey:(id)key ofClass:(Class)expected {return DF141Entitlement2(self,_cmd,key,expected);}
@end
@interface DFSafariTestLSApplicationWorkspace:NSObject
+ (id)defaultWorkspace;
- (NSArray *)allInstalledApplications;
@end
@implementation DFSafariTestLSApplicationWorkspace
+ (id)defaultWorkspace {static id w;if(!w)w=[self new];return w;}
- (NSArray *)allInstalledApplications {
 NSMutableArray *a=[NSMutableArray new];
 for(NSString *bid in @[@"com.apple.mobilesafari",@"com.apple.Maps",@"org.videolan.vlc-ios",@"com.apple.springboard"])
  [a addObject:[DFSafariTestLSApplicationProxy applicationProxyForIdentifier:bid]];
 return a;
}
@end
@interface DFSafariTestCRCarPlayAppDeclaration:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@end
@implementation DFSafariTestCRCarPlayAppDeclaration
@end
@interface DFSafariTestDBApplicationInfo:DFSafariTestLSApplicationProxy
@property(nonatomic,strong) id carPlayDeclaration;
@end
@implementation DFSafariTestDBApplicationInfo
@end
@interface DFSafariTestFBSApplicationLibrary:NSObject
@property(nonatomic,strong) NSMutableDictionary *records;
@property(nonatomic,strong) NSArray *notified;
@property(nonatomic) NSUInteger additions;
- (NSArray *)allInstalledApplications;
- (void)addApplicationProxy:(id)proxy withOverrideURL:(id)url;
- (id)applicationInfoForBundleIdentifier:(NSString *)bundle;
- (void)_notifyDidAddApplications:(NSArray *)infos;
@end
@implementation DFSafariTestFBSApplicationLibrary
- (instancetype)init {if((self=[super init]))_records=[NSMutableDictionary new];return self;}
- (NSArray *)allInstalledApplications{return self.records.allValues;}
- (void)addApplicationProxy:(id)proxy withOverrideURL:(id)url {
 (void)url;++self.additions;DFSafariTestDBApplicationInfo *i=[DFSafariTestDBApplicationInfo new];i.bundleIdentifier=[proxy bundleIdentifier];self.records[i.bundleIdentifier]=i;
}
- (id)applicationInfoForBundleIdentifier:(NSString *)bundle{return self.records[bundle];}
- (void)_notifyDidAddApplications:(NSArray *)infos{self.notified=infos;}
@end
static id NativeNil(id obj,SEL sel,id key,Class expected){(void)obj;(void)sel;(void)key;(void)expected;return nil;}
#define CHECK(x) do{if(!(x)){NSLog(@"FAIL %d: %s",__LINE__,#x);return 1;}}while(0)
int main(void){@autoreleasepool {
 DF141Original2=NativeNil;DF141Granted=[NSMutableSet new];
 DFSafariTestFBSApplicationLibrary *library=[DFSafariTestFBSApplicationLibrary new];
 DFSafariTestDBApplicationInfo *maps=[DFSafariTestDBApplicationInfo new];maps.bundleIdentifier=@"com.apple.Maps";
 DFSafariTestCRCarPlayAppDeclaration *native=[DFSafariTestCRCarPlayAppDeclaration new];native.bundleIdentifier=maps.bundleIdentifier;maps.carPlayDeclaration=native;
 library.records[maps.bundleIdentifier]=maps;
 selection=@[@"com.apple.mobilesafari",@"com.apple.Maps",@"com.apple.springboard",@"com.fake.uninstalled"];
 // The two former gates provably reject the same selected Safari input.
 CHECK(!DFIsRecommendedAppID(@"com.apple.mobilesafari"));
 CHECK([@"com.apple.mobilesafari" hasPrefix:@"com.apple."]);
 NSInteger added=DFHome136ReconcileVerifiedLibrary(library);
 NSLog(@"Safari test reconcile=%ld additions=%lu granted=%@",(long)added,(unsigned long)library.additions,DF141Granted);
 CHECK(added==1);
 DFSafariTestDBApplicationInfo *safari=library.records[@"com.apple.mobilesafari"];
 CHECK(safari && [safari.carPlayDeclaration bundleIdentifier]);
 CHECK([[safari.carPlayDeclaration bundleIdentifier] isEqual:@"com.apple.mobilesafari"]);
 CHECK(library.notified.count==1 && library.notified[0]==safari);
 CHECK(library.additions==1 && library.records.count==2);
 CHECK(maps.carPlayDeclaration==native);
 CHECK(!library.records[@"com.apple.springboard"] && !library.records[@"org.videolan.vlc-ios"]);
 CHECK(DFHome136ReconcileVerifiedLibrary(library)==0 && library.additions==1);
 DFSafariTestFBSApplicationLibrary *empty=[DFSafariTestFBSApplicationLibrary new];selection=@[];
 CHECK(DFHome136ReconcileVerifiedLibrary(empty)==0 && empty.records.count==0);
 selection=@[@"com.apple.mobilesafari"];enabled=NO;
 CHECK(DFHome136ReconcileVerifiedLibrary(empty)==0 && empty.records.count==0);
 puts("SAFARI_SELECTED_ADMISSION_REAL_FBS_RECORD_DECLARATION_NOTIFY_NATIVE_PRESERVATION_PASS");
 return 0;
}}
