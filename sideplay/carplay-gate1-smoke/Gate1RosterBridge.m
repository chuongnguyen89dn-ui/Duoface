// DuoFace-owned CarPlay roster bridge. One original app ID, iOS16 only.
// Explicit enable + one-shot command; no vehicle icon-state writes/restarts.
// Independent implementation using documented runtime concepts, not vendor code.
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <unistd.h>
#import <string.h>
typedef void (*DFHook)(Class,SEL,IMP,IMP *);
static NSString *const DFID=@"com.duoface.gate1smoke";
static NSString *const DFConf=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.plist";
static NSString *const DFKill=@"/var/mobile/Library/Preferences/.duoface-gate1smoke-disable";
static NSString *const DFRequest=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.roster-request.plist";
static NSString *const DFReply=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.roster-response.plist";
static BOOL DFHooked=NO;
static id (*DFOriginalList)(id,SEL)=NULL;
static __strong id DFPinnedInfo=nil;
static __strong id DFPinnedApp=nil;
static NSString *DFLastNonce=nil;
// Weak references: do not extend lifetime of Dashboard's native FBS objects.
static NSHashTable *DFSeenLibraries=nil;
static unsigned long DFNaturalListQueries=0;
static unsigned long DFOwnListAdditions=0;
static void DFTrackLibrary(id library){
 if(!library)return;
 if(!DFSeenLibraries)DFSeenLibraries=[NSHashTable weakObjectsHashTable];
 @synchronized(DFSeenLibraries){[DFSeenLibraries addObject:library];}
}
static BOOL DFLive(void){
 return NSProcessInfo.processInfo.operatingSystemVersion.majorVersion==16 &&
 [NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"];
}
static BOOL DFConsent(void){
 if(!DFLive()||access(DFKill.fileSystemRepresentation,F_OK)==0)return NO;
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:DFConf];
 return [p[@"Enabled"] boolValue] && [p[@"RiskAcknowledged"] boolValue] &&
 [p[@"HostBundleID"] isEqualToString:DFID];
}
static NSString *DFABI(Class c,SEL sel,BOOL classMethod){
 Method m=c?(classMethod?class_getClassMethod(c,sel):class_getInstanceMethod(c,sel)):NULL;
 const char *t=m?method_getTypeEncoding(m):NULL;
 return t?[NSString stringWithUTF8String:t]:@"UNAVAILABLE";
}
static BOOL DFMatches(Class c,const char *name,BOOL classMethod,NSString *type){
 return [DFABI(c,sel_registerName(name),classMethod) isEqualToString:type];
}
static NSString *DFBundle(id v){
 if(!v||![v respondsToSelector:@selector(bundleIdentifier)])return nil;
 @try{
 id b=((id(*)(id,SEL))objc_msgSend)(v,@selector(bundleIdentifier));
 return [b isKindOfClass:NSString.class]?b:nil;
 }@catch(NSException *e){(void)e;return nil;}
}
static void DFReport(NSString *nonce,NSString *result,NSDictionary *extra){
 NSMutableDictionary *d=[@{@"RequestID":nonce?:@"",
   @"Result":result?:@"UNKNOWN",
   @"Timestamp":@(NSDate.date.timeIntervalSince1970),
   @"Process":@"CarPlay",
   @"RosterHookInstalled":@(DFHooked)} mutableCopy];
 if(extra)[d addEntriesFromDictionary:extra];
 (void)[d writeToFile:DFReply atomically:YES];
 NSLog(@"[Gate1Roster] %@ result=%@",nonce,result);
}
// All ABI gates are checked before sending private selectors.
static id DFNewInfo(void){
 if(!DFConsent())return nil;
 Class ls=NSClassFromString(@"LSApplicationProxy");
 // iOS 16 can expose FBSApplicationInfo without iOS 18's DBApplicationInfo.
 Class info=NSClassFromString(@"DBApplicationInfo");
 if(!info)info=NSClassFromString(@"FBSApplicationInfo");
 if(!DFMatches(ls,"applicationProxyForIdentifier:",YES,@"@24@0:8@16") ||
    !DFMatches(info,"initWithApplicationProxy:",NO,@"@24@0:8@16"))return nil;
 @try{
 id p=((id(*)(id,SEL,id))objc_msgSend)(ls,sel_registerName("applicationProxyForIdentifier:"),DFID);
 if(![DFBundle(p) isEqualToString:DFID])return nil;
 if(DFPinnedInfo)return DFPinnedInfo;
 id object=((id(*)(id,SEL,id))objc_msgSend)([info alloc],sel_registerName("initWithApplicationProxy:"),p);
 if(![DFBundle(object) isEqualToString:DFID])return nil;
 // iOS16 may have no CarKit declaration. Require actual installation validity.
 const char *checks[]={"isValid","isInstalled"};
 for(NSUInteger i=0;i<2;i++){
   const char *name=checks[i];
   SEL s=sel_registerName(name);
   if([object respondsToSelector:s] && DFMatches([object class],name,NO,@"B16@0:8")){
     if(!((BOOL(*)(id,SEL))objc_msgSend)(object,s))return nil;
   }
 }
 DFPinnedInfo=object; // Dashboard may retain non-owning pointers.
 return object;
 }@catch(NSException *e){NSLog(@"[Gate1Roster] info-exception=%@",e.name);return nil;}
}
static id DFList(id owner,SEL sel){
 DFTrackLibrary(owner);
 id original=DFOriginalList?DFOriginalList(owner,sel):nil;
 if(!DFConsent()||![original isKindOfClass:NSArray.class])return original;
 DFNaturalListQueries++;
 @try{
 for(id item in original)if([DFBundle(item) isEqualToString:DFID])return original;
 id info=DFNewInfo();
 if(!info)return original;
 NSMutableArray *expanded=[original mutableCopy];
 [expanded addObject:info];
 DFOwnListAdditions++;
 NSLog(@"[Gate1Roster] own app appended to live FBS list: %lu -> %lu",
  (unsigned long)[original count],(unsigned long)expanded.count);
 return expanded;
 }@catch(NSException *e){NSLog(@"[Gate1Roster] list-exception=%@",e.name);return original;}
}
static void DFInstall(void){
 if(!DFLive()||DFHooked)return;
 Class library=NSClassFromString(@"FBSApplicationLibrary");
 if(!DFMatches(library,"allInstalledApplications",NO,@"@16@0:8")){
 NSLog(@"[Gate1Roster] FBS library/ABI unavailable; no mutation");return;
 }
 DFHook f=(DFHook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(!f)return;
 f(library,sel_registerName("allInstalledApplications"),(IMP)DFList,(IMP *)&DFOriginalList);
 DFHooked=DFOriginalList!=NULL;
 NSLog(@"[Gate1Roster] FBS hook installed=%d",DFHooked);
}
// Only DBApplication wrappers for OUR app forward missing metadata to their backing info.
static IMP DFFallbackForward=NULL;
static id DFForward(id app,SEL sel,SEL requested){
 if([DFBundle(app) isEqualToString:DFID] &&
   [app respondsToSelector:sel_registerName("info")]){
   id info=((id(*)(id,SEL))objc_msgSend)(app,sel_registerName("info"));
   if([info respondsToSelector:requested])return info;
 }
 return DFFallbackForward?((id(*)(id,SEL,SEL))DFFallbackForward)(app,sel,requested):nil;
}
static void DFInstallForwarder(void){
 Class c=NSClassFromString(@"DBApplication");
 SEL s=sel_registerName("forwardingTargetForSelector:");
 if(!c || !DFMatches(c,"forwardingTargetForSelector:",NO,@"@24@0:8:16"))return;
 // Do not override a pre-existing class-specific forwarding implementation.
 if(class_getInstanceMethod(c,s) &&
   class_getInstanceMethod(c,s)!=class_getInstanceMethod([c superclass],s))return;
 DFFallbackForward=method_getImplementation(class_getInstanceMethod(c,s));
 (void)class_addMethod(c,s,(IMP)DFForward,"@24@0:8:16");
}

// iOS16 does not always load DBApplicationController. Re-evaluate only
// FBSApplicationLibrary objects that CarPlay itself has already handed us.
// This does NOT create an icon, mutate a vehicle layout or claim a native scene.
static void DFRefreshFBS(NSString *nonce){
 NSArray *libraries=DFSeenLibraries ? DFSeenLibraries.allObjects : @[];
 NSUInteger refreshed=0, abiUnavailable=0;
 SEL invalidate=sel_registerName("invalidate");
 for(id library in libraries){
  if(!library || ![library respondsToSelector:invalidate] ||
     !DFMatches([library class],"invalidate",NO,@"v16@0:8")){
   abiUnavailable++;continue;
  }
  @try{
   ((void(*)(id,SEL))objc_msgSend)(library,invalidate);
   refreshed++;
  }@catch(NSException *e){
   NSLog(@"[Gate1Roster] FBS invalidate exception=%@",e.name);
  }
 }
 NSDictionary *stats=@{@"SeenLibraries":@(libraries.count),
   @"FBSRefreshed":@(refreshed),@"FBSABIUnavailable":@(abiUnavailable),
   @"FBSQueriesSinceLoad":@(DFNaturalListQueries),
   @"FBSOwnAdditionsSinceLoad":@(DFOwnListAdditions),
   @"HomeIconVerified":@NO,@"SceneVerified":@NO};
 if(refreshed>0)DFReport(nonce,@"FBS_CACHE_INVALIDATED_CHECK_CARPLAY_HOME",stats);
 else if(libraries.count==0)DFReport(nonce,@"FBS_NO_LIVE_LIBRARY_SEEN_RECONNECT_CARPLAY",stats);
 else DFReport(nonce,@"FBS_INVALIDATE_ABI_UNAVAILABLE",stats);
}

static void DFApply(NSString *nonce){
 if(!DFConsent()){DFReport(nonce,@"DISABLED",nil);return;}
 DFInstall();
 if(!DFHooked){DFReport(nonce,@"FBS_HOOK_NOT_READY",nil);return;}
 Class c=NSClassFromString(@"DBApplicationController");
 if(!c){DFRefreshFBS(nonce);return;}
 SEL shared=sel_registerName("sharedInstance");
 SEL get=sel_registerName("applicationWithBundleIdentifier:");
 SEL load=sel_registerName("_loadApplicationWithInfo:");
 SEL didAdd=sel_registerName("_didAddApplications:");
 if(!DFMatches(c,"sharedInstance",YES,@"@16@0:8") ||
    !DFMatches(c,"applicationWithBundleIdentifier:",NO,@"@24@0:8@16") ||
    !DFMatches(c,"_loadApplicationWithInfo:",NO,@"v24@0:8@16") ||
    !DFMatches(c,"_didAddApplications:",NO,@"v24@0:8@16")){
 // A class name alone is not proof of the iOS16 method contract.
 DFRefreshFBS(nonce);return;
 }
 @try{
 id ctl=((id(*)(id,SEL))objc_msgSend)(c,shared);
 if(!ctl){DFReport(nonce,@"CONTROLLER_NOT_READY",nil);return;}
 id existing=((id(*)(id,SEL,id))objc_msgSend)(ctl,get,DFID);
 if(existing){DFReport(nonce,@"ALREADY_IN_DASHBOARD_ROSTER",nil);return;}
 id info=DFNewInfo();
 if(!info){DFReport(nonce,@"DB_APPLICATION_INFO_NOT_READY",nil);return;}
 DFInstallForwarder();
 ((void(*)(id,SEL,id))objc_msgSend)(ctl,load,info);
 id app=((id(*)(id,SEL,id))objc_msgSend)(ctl,get,DFID);
 if(!app){DFReport(nonce,@"LOAD_RETURNED_NO_APP",nil);return;}
 DFPinnedApp=app;
 ((void(*)(id,SEL,id))objc_msgSend)(ctl,didAdd,@[app]);
 DFReport(nonce,@"ADDED_TO_DASHBOARD_ROSTER",
 @{@"HomeIconVerified":@NO,@"SceneVerified":@NO});
 }@catch(NSException *e){
 DFReport(nonce,@"DASHBOARD_EXCEPTION",@{@"ExceptionName":e.name?:@"unknown"});
 }
}
static void DFCmd(CFNotificationCenterRef c,void *o,CFStringRef n,const void *obj,CFDictionaryRef d){
 (void)c;(void)o;(void)n;(void)obj;(void)d;
 dispatch_async(dispatch_get_main_queue(), ^{
  if(!DFConsent())return;
  NSDictionary *r=[NSDictionary dictionaryWithContentsOfFile:DFRequest];
  NSString *nonce=r[@"RequestID"];
  if(![r[@"Enabled"] boolValue]||![r[@"HostBundleID"] isEqualToString:DFID]||
   ![nonce isKindOfClass:NSString.class]||
   ![[NSUUID alloc] initWithUUIDString:nonce]||[DFLastNonce isEqualToString:nonce]||
   ![r[@"RequestedAt"] isKindOfClass:NSNumber.class])return;
  NSTimeInterval age=NSDate.date.timeIntervalSince1970-[r[@"RequestedAt"] doubleValue];
  if(age<0||age>45)return;
  DFLastNonce=[nonce copy];
  DFApply(nonce);
 });
}
static void DFRefresh(CFNotificationCenterRef c,void *o,CFStringRef n,const void *obj,CFDictionaryRef d){
 (void)c;(void)o;(void)n;(void)obj;(void)d;
 dispatch_async(dispatch_get_main_queue(), ^{DFInstall();});
}
__attribute__((constructor)) static void DFStart(void){
 @autoreleasepool{
 if(!DFLive())return;
 CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,
  DFCmd,CFSTR("com.duoface.gate1smoke.roster-apply"),NULL,
  CFNotificationSuspensionBehaviorDeliverImmediately);
 CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,
  DFRefresh,CFSTR("com.duoface.gate1smoke.refresh"),NULL,
  CFNotificationSuspensionBehaviorDeliverImmediately);
 dispatch_async(dispatch_get_main_queue(), ^{DFInstall();});
 }
}
