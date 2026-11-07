// DuoFace Gate 0: narrow read-only discovery, NOT a Maps renderer or an ON/OFF oracle.
// No CarPlay Settings writes, no app launch, no scene/view mutation, no vendor code.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <dispatch/dispatch.h>
#import <fcntl.h>
#import <unistd.h>
#import <sys/stat.h>
#import <string.h>
#import <stdint.h>

static NSString *const DFG0Map = @"com.google.Maps";
static NSString *const DFG0Pulse = @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
static NSString *const DFG0Choice = @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-map-choice.v1.plist";
static NSString *const DFG0LogDir = @"/var/mobile/Library/Logs";
static NSMutableArray<NSString *> *DFG0Files;
static NSString *DFG0Run;
static unsigned long DFG0Seq;
static NSUInteger DFG0Ticks;
static NSString *DFG0LastScene;
static NSDictionary *DFG0CandidateSnapshot;  // updated only on bounded 30-second discovery
static NSTimeInterval DFG0CandidateSampleWall;
static __weak UIViewController *DFG0LastNativeMapsVC;  // never retain the system controller
static BOOL DFG0PresentInstalled;
static void (*DFG0OriginalPresent)(id,SEL,id,BOOL,unsigned long long,id);

static NSString *DFG0Digest(NSString *s) {
    // Stable FNV digest of private file paths, never log paired-car GUID/name.
    uint64_t h=UINT64_C(14695981039346656037);
    for(NSUInteger i=0;i<s.length;i++){h^=(uint64_t)[s characterAtIndex:i];h*=UINT64_C(1099511628211);}
    return [NSString stringWithFormat:@"%016llx",(unsigned long long)h];
}
static BOOL DFG0ContainsMaps(id o,NSUInteger depth) {
    if(!o || depth>24)return NO;
    if([o isKindOfClass:NSString.class])return [o isEqual:DFG0Map];
    if([o isKindOfClass:NSArray.class]){
        NSUInteger n=0;for(id v in (NSArray *)o){if(++n>4096)break;if(DFG0ContainsMaps(v,depth+1))return YES;}
    } else if([o isKindOfClass:NSDictionary.class]){
        NSUInteger n=0;for(id k in (NSDictionary *)o){if(++n>4096)break;
            if(DFG0ContainsMaps(k,depth+1)||DFG0ContainsMaps(o[k],depth+1))return YES;}
    }
    return NO;
}
// Record only hashed property-list *locations* containing Maps, never other apps
// or the raw paired-vehicle identifiers. A Maps occurrence is not ON/OFF.
static void DFG0MapsLocations(id node,NSString *position,NSMutableArray *out,NSUInteger depth) {
    if(!node || depth>18 || out.count>=24)return;
    if([node isKindOfClass:NSString.class]) {
        if([node isEqual:DFG0Map])[out addObject:DFG0Digest(position)];
    } else if([node isKindOfClass:NSArray.class]) {
        NSUInteger n=0;
        for(id item in (NSArray *)node) {
            if(++n>4096 || out.count>=24)break;
            DFG0MapsLocations(item,[position stringByAppendingString:@"/[]"],out,depth+1);
        }
    } else if([node isKindOfClass:NSDictionary.class]) {
        NSUInteger n=0;
        for(id key in (NSDictionary *)node) {
            if(++n>4096 || out.count>=24)break;
            NSString *name=[key isKindOfClass:NSString.class]?key:NSStringFromClass([key class]);
            NSString *sub=[position stringByAppendingFormat:@"/%@",name];
            if([name isEqual:DFG0Map])[out addObject:DFG0Digest(sub)];
            DFG0MapsLocations(((NSDictionary *)node)[key],sub,out,depth+1);
        }
    }
}
static void DFG0FindFiles(void) {
    NSMutableArray *found=[NSMutableArray new];
    NSArray *roots=@[@"/var/mobile/Library/SpringBoard",@"/var/mobile/Library/Preferences",
                     @"/var/mobile/Library/CarPlay"];
    for(NSString *root in roots){
        NSDirectoryEnumerator *en=[NSFileManager.defaultManager
          enumeratorAtURL:[NSURL fileURLWithPath:root isDirectory:YES]
          includingPropertiesForKeys:@[NSURLIsRegularFileKey]
          options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsPackageDescendants
          errorHandler:nil];
        NSUInteger walked=0;
        for(NSURL *u in en){
            if(++walked>6000)break;
            if(en.level>4){[en skipDescendants];continue;}
            NSString *name=u.lastPathComponent.lowercaseString;
            if(![name hasSuffix:@".plist"]||
               !([name containsString:@"carplay"]||[name containsString:@"iconstate"]))continue;
            NSNumber *regular=nil;[u getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
            if(!regular.boolValue)continue;
            if(found.count<40)[found addObject:u.path];
        }
    }
    DFG0Files=found;
}
static NSDictionary *DFG0ReadCandidates(void) {
    NSMutableArray *a=[NSMutableArray new]; NSUInteger matched=0;
    for(NSString *path in DFG0Files ?: @[]){
        NSDictionary *attrs=[NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
        unsigned long long size=[attrs fileSize];
        if(size==0 || size>1048576)continue; // bounded, no arbitrary car files
        NSData *data=[NSData dataWithContentsOfFile:path options:0 error:nil];
        if(!data)continue;
        id state=[NSPropertyListSerialization propertyListWithData:data
                 options:NSPropertyListImmutable format:NULL error:nil];
        if(![state isKindOfClass:NSDictionary.class]&&![state isKindOfClass:NSArray.class])continue;
        BOOL contains=DFG0ContainsMaps(state,0);
        NSString *name=path.lastPathComponent.lowercaseString;
        NSString *kind=[name containsString:@"desirediconstate"]?@"DESIRED":
                       ([name containsString:@"displayiconstate"]?@"DISPLAY":@"OTHER");
        if(contains)matched++;
        NSMutableArray *locations=[NSMutableArray new];
        DFG0MapsLocations(state,@"root",locations,0);
        // A location digest distinguishes map-in-visible-list from map-in-hidden-list
        // AFTER real ON/OFF calibration, but is never itself an OS setting verdict.
        [a addObject:@{@"fileId":DFG0Digest(path),@"kind":kind,
           @"mapsPresent":@(contains),@"mapsLocationHashes":locations,
           @"bytes":@(size),
           @"modified":@([attrs[NSFileModificationDate] timeIntervalSince1970])}];
    }
    return @{@"stockSettings":@"UNKNOWN",@"stockSourceStatus":@"UNVERIFIED",
             @"candidateCount":@(a.count),@"candidateContainingMaps":@(matched),@"candidates":a};
}
static id DFG0Getter(id obj,const char *name) {
    if(!obj)return nil;
    SEL sel=sel_registerName(name);
    Method m=class_getInstanceMethod(object_getClass(obj),sel);
    if(!m || method_getNumberOfArguments(m)!=2)return nil;
    char result[16]={0};method_getReturnType(m,result,sizeof(result));
    if(strcmp(result,"@"))return nil;
    @try{return ((id(*)(id,SEL))objc_msgSend)(obj,sel);}
    @catch(__unused NSException *e){return nil;}
}
static NSString *DFG0Bundle(id obj) {
    id idValue=DFG0Getter(obj,"bundleIdentifier");
    return [idValue isKindOfClass:NSString.class]?idValue:@"unknown";
}
static NSString *DFG0MethodABI(const char *c,const char *sel) {
    Class cls=objc_getClass(c);
    Method m=cls?class_getInstanceMethod(cls,sel_registerName(sel)):NULL;
    return m?[NSString stringWithUTF8String:method_getTypeEncoding(m)]:@"ABSENT";
}
static NSDictionary *DFG0SessionFields(void) {
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFG0Pulse];
    NSDictionary *a=[NSDictionary dictionaryWithContentsOfFile:DFG0Choice];
    NSString *session=[pulse[@"Session"] isKindOfClass:NSString.class]?pulse[@"Session"]:@"unknown";
    NSString *assign=[a[@"AssignmentID"] isKindOfClass:NSString.class]?a[@"AssignmentID"]:@"unknown";
    return @{@"session":session,@"assignmentID":assign,
             @"physicalSlot":[a[@"PhysicalSlot"] isKindOfClass:NSNumber.class]?a[@"PhysicalSlot"]:@(-1)};
}
// The shipping DuoFace iPhone button exports DuoFaceAudit.txt from
// DFNativeDiagnostics.prepareShareFiles, which already includes the last 2 MiB
// of DuoFaceDeepTrace.log. Mirror a tagged JSON record into that existing
// bounded export stream. Independent JSONL remains optional secondary evidence.
// If the probe is NOT installed/injected, no Gate0 marker will appear in Audit.
// Return actual write result; secondary per-process JSONL records it for audit coverage triage.
static BOOL DFG0MirrorToAudit(NSData *json) {
    if(!json.length || json.length>32768)return NO;
    NSString *body=[[NSString alloc]initWithData:json encoding:NSUTF8StringEncoding];
    if(!body)return NO;
    // One physical LF per event. A doubled backslash here would join records.
    NSString *line=[NSString stringWithFormat:
      @"utc=%.6f uptime=%.6f build=gate0-0.0.2~gate0audit2 pid=%d process=%@ area=gate0 %@\n",
      NSDate.date.timeIntervalSince1970,NSProcessInfo.processInfo.systemUptime,
      getpid(),NSProcessInfo.processInfo.processName?:@"unknown",body];
    NSData *bytes=[line dataUsingEncoding:NSUTF8StringEncoding];
    const char *path="/var/mobile/Library/Logs/DuoFaceDeepTrace.log";
    int fd=open(path,O_WRONLY|O_CREAT|O_APPEND|O_CLOEXEC,0644);
    if(fd<0) {
        NSLog(@"[DuoFaceGate0] audit-mirror-open-denied process=%@",
              NSProcessInfo.processInfo.processName);
        return NO;
    }
    ssize_t written=write(fd,bytes.bytes,bytes.length);
    close(fd);
    if(written<0 || (NSUInteger)written!=bytes.length) {
        NSLog(@"[DuoFaceGate0] audit-mirror-write-incomplete");
        return NO;
    }
    return YES;
}
static void DFG0Emit(NSString *event,NSDictionary *detail) {
    @autoreleasepool {
        NSDictionary *cached=DFG0CandidateSnapshot ?: @{};
        NSMutableDictionary *r=[@{@"version":@2,@"event":event?:@"unknown",
             @"run":DFG0Run?:@"unknown",@"seq":@(++DFG0Seq),
             @"process":NSProcessInfo.processInfo.processName?:@"unknown",
             @"pid":@(getpid()),@"bundle":DFG0Map,
             @"wall":@(NSDate.date.timeIntervalSince1970),
             @"uptime":@(NSProcessInfo.processInfo.systemUptime),
             // No authentic paired-car OS reader yet: these are NOT samples of ON/OFF.
             @"stockSettings":@"UNKNOWN",@"stockSourceStatus":@"UNVERIFIED",
             @"stockSource":@"UNVALIDATED_CARPLAY_ICONSTATE_CANDIDATES",
             @"stockSampleWall":@0,@"stockSampleUptime":@0,
             @"stockProfileMatch":@NO,
             @"candidateSampleWall":@(DFG0CandidateSampleWall),
             @"candidateCount":cached[@"candidateCount"]?:@0,
             @"candidateContainingMaps":cached[@"candidateContainingMaps"]?:@0} mutableCopy];
        [r addEntriesFromDictionary:DFG0SessionFields()];
        // Full hashed candidate list only on periodic discovery, not on every scene sample.
        if([event isEqualToString:@"stock.candidate.discovery"])
            [r addEntriesFromDictionary:cached];
        if([detail isKindOfClass:NSDictionary.class])[r addEntriesFromDictionary:detail];
        NSData *encoded=[NSJSONSerialization dataWithJSONObject:r options:0 error:nil];
        if(!encoded)return;
        NSString *process=NSProcessInfo.processInfo.processName?:@"unknown";
        if(![@[@"CarPlay",@"CarPlayApp",@"Preferences",@"dashboard",@"Dashboard"] containsObject:process])return;
        BOOL auditWritten=DFG0MirrorToAudit(encoded);
        // Independent JSONL carries receipt if shared log permissions/export fail.
        r[@"auditMirrorWrite"]=auditWritten?@"complete":@"failed";
        encoded=[NSJSONSerialization dataWithJSONObject:r options:0 error:nil];
        if(!encoded)return;
        NSString *file=[DFG0LogDir stringByAppendingPathComponent:
           [NSString stringWithFormat:@"DuoFaceMapsGate0-%@.jsonl",process]];
        int fd=open(file.fileSystemRepresentation,O_WRONLY|O_APPEND|O_CREAT|O_CLOEXEC,0644);
        if(fd<0){NSLog(@"[DuoFaceGate0] log-open-failed process=%@ event=%@",process,event);return;}
        (void)write(fd,encoded.bytes,encoded.length);(void)write(fd,"\n",1);close(fd);
    }
}
static void DFG0ABI(void) {
    NSDictionary *d=@{
      @"presentBase":DFG0MethodABI("DBDashboardRootViewController",
        "presentBaseViewController:animated:launchSource:completion:"),
      @"dismissBase":DFG0MethodABI("DBDashboardRootViewController",
        "dismissBaseViewControllerAnimated:completion:"),
      @"layout":DFG0MethodABI("DBDashboardRootViewController","viewDidLayoutSubviews"),
      @"appear":DFG0MethodABI("DBDashboardRootViewController","viewDidAppear:"),
      @"nativeFrame":DFG0MethodABI("DBDashboard","sceneFrameForAppInfo:proxyAppInfo:"),
      @"nativeInsets":DFG0MethodABI("DBDashboard","safeAreaInsetsForAppInfo:proxyAppInfo:"),
      @"homeEvent":DFG0MethodABI("DBDashboard","_handleHomeEvent:"),
      @"destroyScene":DFG0MethodABI("DBApplicationSceneViewController","sceneManager:didDestroyScene:"),
      @"carIconHidden":DFG0MethodABI("CARIconModel","hiddenBundleIdentifiers")
    };
    DFG0Emit(@"abi.metadata",d);
}
static BOOL DFG0PresentABI(Method m) {
    if(!m||method_getNumberOfArguments(m)!=6)return NO;
    char a[64]={0};method_getReturnType(m,a,sizeof(a));if(strcmp(a,"v"))return NO;
    method_getArgumentType(m,2,a,sizeof(a));if(strcmp(a,"@"))return NO;
    method_getArgumentType(m,3,a,sizeof(a));if(strcmp(a,"B")&&strcmp(a,"c"))return NO;
    method_getArgumentType(m,4,a,sizeof(a));if(strcmp(a,"Q")&&strcmp(a,"q"))return NO;
    method_getArgumentType(m,5,a,sizeof(a));if(strcmp(a,"@?")&&strcmp(a,"@"))return NO;
    return YES;
}
// Direct weak presentation-target readback complements view-tree traversal.
// A scene ID alone never means the view is attached, visible or in DuoFace.
static NSDictionary *DFG0VCReadback(UIViewController *vc) {
    if(!vc)return @{@"weakAlive":@NO};
    UIView *view=vc.viewIfLoaded;
    UIWindow *w=view.window;
    id scene=DFG0Getter(vc,"scene")?:DFG0Getter(DFG0Getter(vc,"sceneHandle"),"sceneIfExists");
    id sid=DFG0Getter(scene,"identifier");
    NSString *role=w.windowScene.session.role?:@"unknown";
    BOOL isCarPlayRole=[role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"];
    BOOL differentScreen=(w.screen!=nil && w.screen!=UIScreen.mainScreen);
    return @{@"weakAlive":@YES,
        @"controller":NSStringFromClass(vc.class),
        @"sceneClass":scene?NSStringFromClass([scene class]):@"nil",
        @"sceneID":[sid isKindOfClass:NSString.class]?sid:@"unknown",
        @"parent":vc.parentViewController?NSStringFromClass(vc.parentViewController.class):@"none",
        @"windowAttached":@(w!=nil),
        @"windowRole":role,@"carplayRoleVerified":@(isCarPlayRole),
        @"screenExternalByComparison":@(differentScreen),
        @"screenIsMain":@(w!=nil && w.screen==UIScreen.mainScreen),
        @"windowHidden":@(w==nil || w.hidden),
        @"viewFrame":view?NSStringFromCGRect(view.frame):@"unloaded",
        @"windowFrame":w?NSStringFromCGRect(w.frame):@"unattached"};
}
static void DFG0Present(id owner,SEL cmd,id vc,BOOL animated,unsigned long long source,id completion){
    NSTimeInterval entryWall=NSDate.date.timeIntervalSince1970;
    NSTimeInterval entryUptime=NSProcessInfo.processInfo.systemUptime;
    id info=DFG0Getter(vc,"applicationInfo")?:DFG0Getter(vc,"proxyApplicationInfo");
    NSString *bid=DFG0Bundle(info);
    id scene=DFG0Getter(vc,"scene");
    id sceneID=DFG0Getter(scene,"identifier");
    // Original UIKit presenter always receives its unaltered arguments once.
    DFG0OriginalPresent(owner,cmd,vc,animated,source,completion);
    if(![bid isEqual:DFG0Map])return;
    DFG0LastNativeMapsVC=vc;
    NSTimeInterval exitWall=NSDate.date.timeIntervalSince1970;
    NSMutableDictionary *d=[@{@"controller":vc?NSStringFromClass([vc class]):@"nil",
      @"targetBundle":bid,@"sceneID":[sceneID isKindOfClass:NSString.class]?sceneID:@"unknown",
      @"animated":@(animated),@"launchSource":@(source),
      @"presentEnteredWall":@(entryWall),@"presentEnteredUptime":@(entryUptime),
      @"presentReturnedWall":@(exitWall),@"eventCapture":@"post-original-sync-snapshot"} mutableCopy];
    [d addEntriesFromDictionary:DFG0VCReadback(vc)];
    DFG0Emit(@"presentBase.original-returned",d);
}
static void DFG0TryHook(void) {
    if(DFG0PresentInstalled)return;
    Class root=objc_getClass("DBDashboardRootViewController");
    SEL sel=sel_registerName("presentBaseViewController:animated:launchSource:completion:");
    Method m=root?class_getInstanceMethod(root,sel):NULL;
    if(!DFG0PresentABI(m))return;
    void (*hook)(Class,SEL,IMP,IMP *)=dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook)return;
    hook(root,sel,(IMP)DFG0Present,(IMP *)&DFG0OriginalPresent);
    DFG0PresentInstalled=(DFG0OriginalPresent!=NULL);
    DFG0Emit(DFG0PresentInstalled?@"presentBase.hook-readonly":@"presentBase.hook-failed",
            @{@"abi":m?[NSString stringWithUTF8String:method_getTypeEncoding(m)]:@"ABSENT"});
}
static void DFG0Walk(UIViewController *vc,NSMutableArray *scenes,NSUInteger depth) {
    if(!vc||depth>12||scenes.count>48)return;
    if([NSStringFromClass(vc.class) isEqualToString:@"DBApplicationSceneViewController"]){
        id info=DFG0Getter(vc,"applicationInfo")?:DFG0Getter(vc,"proxyApplicationInfo");
        if([DFG0Bundle(info) isEqual:DFG0Map]){
            id s=DFG0Getter(vc,"scene")?:DFG0Getter(DFG0Getter(vc,"sceneHandle"),"sceneIfExists");
            id sceneID=DFG0Getter(s,"identifier");
            UIWindow *w=vc.viewIfLoaded.window;
            [scenes addObject:@{@"controller":NSStringFromClass(vc.class),
                @"sceneClass":s?NSStringFromClass([s class]):@"nil",
                @"sceneID":[sceneID isKindOfClass:NSString.class]?sceneID:@"unknown",
                @"windowRole":w.windowScene.session.role?:@"unknown",
                @"carplayRoleVerified":@([w.windowScene.session.role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"]),
                @"external":@([w.windowScene.session.role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"] ||
                              (w.screen!=nil && w.screen!=UIScreen.mainScreen)),
                @"screenExternalByComparison":@(w.screen!=nil && w.screen!=UIScreen.mainScreen),
                @"windowHidden":@(w.hidden),
                @"parent":vc.parentViewController?NSStringFromClass(vc.parentViewController.class):@"none"}];
        }
    }
    for(UIViewController *sub in vc.childViewControllers)DFG0Walk(sub,scenes,depth+1);
    if(vc.presentedViewController)DFG0Walk(vc.presentedViewController,scenes,depth+1);
}
static void DFG0SceneSample(void) {
    if(![@[@"CarPlay",@"CarPlayApp",@"dashboard",@"Dashboard"]
          containsObject:NSProcessInfo.processInfo.processName])return;
    NSMutableArray *found=[NSMutableArray new];
    NSUInteger windows=0,carplayRoleWindows=0,externalComparisonWindows=0;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:UIWindowScene.class])continue;
        UIWindowScene *ws=(UIWindowScene *)scene;
        // Do NOT drop ws.screen==UIScreen.mainScreen: CarPlay may be the main
        // display of the isolated CarPlay process. Log both role and comparison.
        for(UIWindow *w in ws.windows){
            if(++windows>96)break;
            if([w.windowScene.session.role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"])
                carplayRoleWindows++;
            if(w.screen && w.screen!=UIScreen.mainScreen)externalComparisonWindows++;
            if(w.rootViewController)DFG0Walk(w.rootViewController,found,0);
        }
        if(windows>96)break;
    }
    NSDictionary *lastPresent=DFG0VCReadback(DFG0LastNativeMapsVC);
    NSString *signature=[NSString stringWithFormat:@"%@/%@/%lu/%lu",
        found,lastPresent,(unsigned long)windows,(unsigned long)carplayRoleWindows];
    if(![DFG0LastScene isEqual:signature]||DFG0Ticks%8==0){
       DFG0LastScene=signature;
       DFG0Emit(@"native.scene.snapshot",@{@"nativeMapsScenePresent":@(found.count>0),
         @"sceneCount":@(found.count),@"scenes":found,
         @"windowCountScanned":@(windows),
         @"carplayRoleWindowCount":@(carplayRoleWindows),
         @"externalByComparisonWindowCount":@(externalComparisonWindows),
         @"lastPresentWeakReadback":lastPresent});
    }
}
static void DFG0SettingsMetadata(void) {
    // Metadata only; no private getters, no user data. Preferences process loads
    // CarPlay settings UI on the iPhone and exposes discovery class names.
    unsigned count=0;Class *classes=objc_copyClassList(&count);
    NSMutableArray *match=[NSMutableArray new];
    for(unsigned i=0;i<count&&match.count<60;i++){
        NSString *name=NSStringFromClass(classes[i]);
        NSString *lower=name.lowercaseString;
        if(([lower containsString:@"carplay"]||[lower containsString:@"caricon"]||
            [lower containsString:@"vehicle"]) &&
           ([lower containsString:@"setting"]||[lower containsString:@"icon"]||
            [lower containsString:@"preference"]||[lower containsString:@"vehicle"])){
           [match addObject:name];
        }
    }
    free(classes);
    DFG0Emit(@"settings.runtime.classes",@{@"classCount":@(count),@"candidateClasses":match});
}
@interface DFG0Runner:NSObject
@property(nonatomic,strong) NSTimer *timer;
@end
@implementation DFG0Runner
- (void)tick {
    DFG0Ticks++;
    if(DFG0Ticks==1 || DFG0Ticks%75==0) {
       DFG0FindFiles();
       DFG0CandidateSnapshot=DFG0ReadCandidates();
       DFG0CandidateSampleWall=NSDate.date.timeIntervalSince1970;
       DFG0Emit(@"stock.candidate.discovery",@{@"filesDiscovered":@(DFG0Files.count)});
       DFG0ABI();
       DFG0SettingsMetadata();
    }
    DFG0TryHook();
    DFG0SceneSample();
}
- (void)start {
    if(self.timer)return;
    NSString *process=NSProcessInfo.processInfo.processName;
    if(![@[@"CarPlay",@"CarPlayApp",@"Preferences",@"dashboard",@"Dashboard"] containsObject:process])return;
    DFG0Run=NSUUID.UUID.UUIDString;
    DFG0Files=[NSMutableArray new];
    DFG0Emit(@"start.readonly",@{@"systemVersion":UIDevice.currentDevice.systemVersion?:@"unknown",
        @"runtimeMutation":@NO,@"stockReaderVerified":@NO});
    self.timer=[NSTimer scheduledTimerWithTimeInterval:0.4 target:self
                selector:@selector(tick) userInfo:nil repeats:YES];
    [self tick];
}
@end
__attribute__((constructor)) static void DFG0Start(void) {
    @autoreleasepool {
      NSString *name=NSProcessInfo.processInfo.processName;
      if(![@[@"CarPlay",@"CarPlayApp",@"Preferences",@"dashboard",@"Dashboard"] containsObject:name])return;
      dispatch_async(dispatch_get_main_queue(),^{[[DFG0Runner new] start];});
    }
}
