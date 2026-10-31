// QA136 independent CarPlay Home library reconciler.
// This function only acts on an ACTUAL caller-provided FBSApplicationLibrary,
// after the separate user Home switch was explicitly enabled.
// It NEVER instantiates or swaps system libraries or modifies native app records.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <string.h>
#import "DFCarPlayHomeCatalogPolicy.h"
#import "DFHomePublisher136Config.h"
extern void DF137ObserveExistingAppInfo(id info, NSString *stage);

static BOOL DF136Exact(id object,SEL sel,const char *expected) {
 if(!object)return NO;
 Method m=class_getInstanceMethod(object_getClass(object),sel);
 return m && method_getTypeEncoding(m) && strcmp(method_getTypeEncoding(m),expected)==0;
}
static NSString *DF136Identifier(id object) {
 if(!object)return nil;
 SEL s=sel_registerName("bundleIdentifier");
 if(!DF136Exact(object,s,"@16@0:8"))return nil;
 id value=((id(*)(id,SEL))objc_msgSend)(object,s);
 return [value isKindOfClass:NSString.class]?value:nil;
}
static id DF136InstalledProxy(NSString *bundle) {
 Class proxyClass=objc_getClass("LSApplicationProxy");
 SEL s=sel_registerName("applicationProxyForIdentifier:");
 Method m=proxyClass?class_getClassMethod(proxyClass,s):NULL;
 if(!m || !method_getTypeEncoding(m) ||
    strcmp(method_getTypeEncoding(m),"@24@0:8@16")!=0)return nil;
 id value=((id(*)(id,SEL,id))objc_msgSend)(proxyClass,s,bundle);
 return [DF136Identifier(value) isEqualToString:bundle]?value:nil;
}
static NSArray *DF136InstalledIDs(void) {
 Class wsClass=objc_getClass("LSApplicationWorkspace");
 SEL get=sel_registerName("defaultWorkspace");
 Method method=wsClass?class_getClassMethod(wsClass,get):NULL;
 if(!method || method_getNumberOfArguments(method)!=2)return nil;
 id workspace=((id(*)(id,SEL))objc_msgSend)(wsClass,get);
 SEL installed=sel_registerName("allInstalledApplications");
 if(!DF136Exact(workspace,installed,"@16@0:8"))return nil;
 id proxies=((id(*)(id,SEL))objc_msgSend)(workspace,installed);
 if(![proxies isKindOfClass:NSArray.class])return nil;
 NSMutableOrderedSet<NSString *> *IDs=[NSMutableOrderedSet orderedSet];
 for(id proxy in proxies) {
    NSString *bid=DF136Identifier(proxy);
    if(bid)[IDs addObject:bid];
 }
 return IDs.array;
}
// Only a newly created THIRD-PARTY application info may be promoted.
// Existing native objects, including GOFA and all Apple CarPlay apps, must
// remain exactly as returned by the original OS library.
extern BOOL DFHome138PromoteAdmittedInfo(id info);
extern BOOL DFHome138RequestSelectedAdmission(id proxy);
// Returns count of verified new FBS records, or -1 for unavailable native ABI.
NSInteger DFHome136ReconcileVerifiedLibrary(id library) {
 if(!DFHome136Enabled() ||
    ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"] ||
    NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return 0;
 Class libraryClass=objc_getClass("FBSApplicationLibrary");
 SEL all=sel_registerName("allInstalledApplications");
 SEL add=sel_registerName("addApplicationProxy:withOverrideURL:");
 SEL lookup=sel_registerName("applicationInfoForBundleIdentifier:");
 SEL notify=sel_registerName("_notifyDidAddApplications:");
 if(!libraryClass || ![library isKindOfClass:libraryClass] ||
    !DF136Exact(library,all,"@16@0:8") ||
    !DF136Exact(library,add,"v32@0:8@16@24") ||
    !DF136Exact(library,lookup,"@24@0:8@16"))return -1;
 NSArray *native=((id(*)(id,SEL))objc_msgSend)(library,all);
 if(![native isKindOfClass:NSArray.class])return -1;
 NSArray *installed=DF136InstalledIDs();
 NSArray *selected=DFConfiguredEnabledAppIDs();
 if(!installed || !selected)return -1;
 // A stale QA136-added record is not necessarily a native CarPlay app.
 // The original LS capabilities, not FBS membership alone, decide whether
 // the new selected-only gate is permitted to promote it.
 NSArray *allowed=DFHomeBridgeBundleIDs(installed,selected,@[]);
 NSMutableArray *infos=[NSMutableArray array];
 for(NSString *bundle in allowed) {
    if([bundle hasPrefix:@"com.apple."])continue;
    id proxy=DF136InstalledProxy(bundle);
    if(!proxy || !DFHome138RequestSelectedAdmission(proxy))continue;
    id already=((id(*)(id,SEL,id))objc_msgSend)(library,lookup,bundle);
    if(already){
      DF137ObserveExistingAppInfo(already,@"already-present");
      (void)DFHome138PromoteAdmittedInfo(already);
      continue;
    }
    ((void(*)(id,SEL,id,id))objc_msgSend)(library,add,proxy,nil);
    id info=((id(*)(id,SEL,id))objc_msgSend)(library,lookup,bundle);
    if(info){
      DF137ObserveExistingAppInfo(info,@"new-before-promotion");
      (void)DFHome138PromoteAdmittedInfo(info);
      DF137ObserveExistingAppInfo(info,@"new-after-promotion");
      [infos addObject:info];
    }
 }
 if(infos.count && DF136Exact(library,notify,"v24@0:8@16"))
    ((void(*)(id,SEL,id))objc_msgSend)(library,notify,infos);
 return (NSInteger)infos.count;
}
