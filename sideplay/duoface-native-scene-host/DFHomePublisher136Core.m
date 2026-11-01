// QA136 independent CarPlay Home library reconciler.
// This function only acts on an ACTUAL caller-provided FBSApplicationLibrary,
// after the separate user Home switch was explicitly enabled.
// It NEVER instantiates or swaps system libraries or modifies native app records.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <string.h>
#import <fcntl.h>
#import <unistd.h>
#import "DFCarPlayHomeCatalogPolicy.h"
#import "DFSelectedHomeAdmission.h"
#import "DFHomePublisher136Config.h"
extern void DF137ObserveExistingAppInfo(id info, NSString *stage);
// QA165: diagnostics only, without inserting duplicates into Apple's native
// icon roster. An FBS record is not proof an icon is actually displayed.
static void DF165HomeRosterLog(NSString *bundle,NSString *state) {
    NSString *line=[NSString stringWithFormat:
        @"[DFHome165] selected=%@ decision=%@ (icon visibility UNVERIFIED)\n",
        bundle?:@"unknown",state?:@"unknown"];
    NSLog(@"%@",line);
    int fd=open("/var/mobile/Library/Logs/DuoFaceHomeRoster165.log",
                O_WRONLY|O_CREAT|O_APPEND,0644);
    if(fd>=0){
        NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,data.bytes,data.length);
        close(fd);
    }
}


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
// Only selected admitted user-facing records with a missing declaration may be completed.
// Existing native declarations, including GOFA and all Apple CarPlay apps, must
// remain exactly as returned by the original OS library.
extern BOOL DFHome141CompleteInfo(id info);
extern BOOL DFHome141InfoHasDeclaration(id info);
extern BOOL DFHome141RequestSelectedAdmission(id proxy);
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
 // Native apps (Maps/GOFA/Waze) can be selected in DuoFace but their
 // visible Apple CarPlay Home roster is owned by iOS. Track precisely which
 // selected apps were bypassed, instead of saying they were "published".
 for(NSString *bundle in selected) {
    if([bundle isKindOfClass:NSString.class] &&
       ![installed containsObject:bundle])
        DF165HomeRosterLog(bundle,@"NOT_INSTALLED_OR_DIFFERENT_BUNDLE_ID");
 }
 for(NSString *bundle in allowed) {
    if(!DFSelectedHomeAdmission(bundle,selected)){
        DF165HomeRosterLog(bundle,@"NOT_ADMITTED_BY_SELECTED_POLICY");
        continue;
    }
    id already=((id(*)(id,SEL,id))objc_msgSend)(library,lookup,bundle);
    // Preserve native declarations. Native GOFA/Waze/Maps can be excluded
    // by CarPlay's own Home/Settings icon policy, unlike Safari's bridge.
    if(already && DFHome141InfoHasDeclaration(already)){
        DF165HomeRosterLog(bundle,@"NATIVE_DECLARATION_EXISTS_OS_HOME_ICON_NOT_MANAGED_BY_DUOFACE");
        continue;
    }
    id proxy=DF136InstalledProxy(bundle);
    if(!proxy){
        DF165HomeRosterLog(bundle,@"NO_INSTALLED_LS_PROXY");
        continue;
    }
    if(!DFHome141RequestSelectedAdmission(proxy)){
        DF165HomeRosterLog(bundle,@"SELECTED_ADMISSION_DENIED");
        continue;
    }
    id info=already;
    if(!info) {
      ((void(*)(id,SEL,id,id))objc_msgSend)(library,add,proxy,nil);
      info=((id(*)(id,SEL,id))objc_msgSend)(library,lookup,bundle);
    }
    if(!info){
        DF165HomeRosterLog(bundle,@"FBS_APPLICATION_INFO_MISSING");
        continue;
    }
    DF137ObserveExistingAppInfo(info,@"before-declaration-completion");
    BOOL completed=DFHome141CompleteInfo(info);
    DF137ObserveExistingAppInfo(info,@"after-declaration-completion");
    // Existing nil records need notification too after a verified attachment.
    BOOL ready=completed || (!already && DFHome141InfoHasDeclaration(info));
    if(ready)[infos addObject:info];
    DF165HomeRosterLog(bundle,ready?@"BRIDGE_DECLARATION_SENT_TO_FBS_ICON_NOT_YET_VERIFIED":
                         @"BRIDGE_DECLARATION_NOT_COMPLETED");
 }
 if(infos.count && DF136Exact(library,notify,"v24@0:8@16"))
    ((void(*)(id,SEL,id))objc_msgSend)(library,notify,infos);
 return (NSInteger)infos.count;
}
