// Independent iOS16 selected-app admission. ABI measured in physical Log17.
// Hook the real DashBoard factory BEFORE its FBS inclusion filter executes.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <dispatch/dispatch.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import "DFHomePublisher136Config.h"
#import "DFEnabledAppsPolicy.h"

typedef void (*DF138Hook)(Class,SEL,IMP,IMP *);
static id (*DF138Original3)(id,SEL,id,Class,Class);
static id (*DF138Original2)(id,SEL,id,Class);
static id (*DF138OriginalFactory)(id,SEL);
static NSMutableSet<NSString *> *DF138Granted;
extern NSInteger DFHome136ReconcileVerifiedLibrary(id library);

static void DF138Log(NSString *message) {
 NSString *line=[NSString stringWithFormat:@"[DFHome138] time=%.3f pid=%d %@\n",
                 NSDate.date.timeIntervalSince1970,getpid(),message];
 int fd=open("/var/mobile/Library/Logs/DuoFaceHomeAdmission138.log",O_CREAT|O_APPEND|O_WRONLY,0644);
 if(fd<0)return;
 NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
 if(data.length)(void)write(fd,data.bytes,data.length);
 close(fd);
}
static BOOL DF138Exact(Class cls,SEL selector,const char *type) {
 Method m=cls?class_getInstanceMethod(cls,selector):NULL;
 return m && method_getTypeEncoding(m) && !strcmp(method_getTypeEncoding(m),type);
}
static NSString *DF138Bundle(id proxy) {
 SEL s=sel_registerName("bundleIdentifier");
 if(!DF138Exact(object_getClass(proxy),s,"@16@0:8"))return nil;
 id name=((id(*)(id,SEL))objc_msgSend)(proxy,s);
 return [name isKindOfClass:NSString.class]?name:nil;
}
static BOOL DF138Selected(NSString *bundle) {
 return DFHome136Enabled() && DFIsRecommendedAppID(bundle) &&
        DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs());
}
static id DF138Answer(id proxy,id key,Class expected,Class values,id original) {
 // Real native capabilities always win. Do not invent template entitlements,
 // scene manifests, SpringBoard bulk dictionaries or Apple app declarations.
 if(original || (expected && expected!=NSNumber.class) ||
    (values && values!=NSNumber.class) ||
    ![key isKindOfClass:NSString.class] ||
    (![(NSString *)key isEqualToString:@"CARCapableApp"] &&
     ![(NSString *)key isEqualToString:@"SBStarkCapable"]))return original;
 @try {
   NSString *bundle=DF138Bundle(proxy);
   if(!DF138Selected(bundle))return original;
   // A real native capability on either original getter preserves native apps.
   if(DF138Original2 && (DF138Original2(proxy,sel_registerName("entitlementValueForKey:ofClass:"),@"CARCapableApp",NSNumber.class) ||
      DF138Original2(proxy,sel_registerName("entitlementValueForKey:ofClass:"),@"SBStarkCapable",NSNumber.class)))return original;
   @synchronized(DF138Granted) {
     if(![DF138Granted containsObject:bundle]) {
       [DF138Granted addObject:bundle];
       DF138Log([NSString stringWithFormat:@"selected-LS-inclusion bundle=%@ key=%@",bundle,key]);
     }
   }
   return @YES;
 } @catch(__unused NSException *e) {return original;}
}
static id DF138Entitlement3(id proxy,SEL s,id key,Class expected,Class values) {
 if(!DF138Original3)return nil;
 return DF138Answer(proxy,key,expected,values,DF138Original3(proxy,s,key,expected,values));
}
static id DF138Entitlement2(id proxy,SEL s,id key,Class expected) {
 if(!DF138Original2)return nil;
 return DF138Answer(proxy,key,expected,Nil,DF138Original2(proxy,s,key,expected));
}
BOOL DFHome138RequestSelectedAdmission(id proxy) {
 NSString *bundle=DF138Bundle(proxy);
 if(!DF138Selected(bundle) || !DF138Original2)return NO;
 // Query the installed LS proxy through the verified hook, rather than
 // treating an old QA136 FBS record as proof of native CarPlay capability.
 SEL s=sel_registerName("entitlementValueForKey:ofClass:");
 if(!DF138Exact(object_getClass(proxy),s,"@32@0:8@16#24"))return NO;
 (void)((id(*)(id,SEL,id,Class))objc_msgSend)(proxy,s,@"CARCapableApp",NSNumber.class);
 @synchronized(DF138Granted) {return [DF138Granted containsObject:bundle];}
}
// Only objects actually admitted by this module may receive launch flags.
// There is deliberately no dependency on absent iOS16 boolean GETTERS.
BOOL DFHome138PromoteAdmittedInfo(id info) {
 NSString *bundle=DF138Bundle(info);
 if(!DF138Selected(bundle))return NO;
 @synchronized(DF138Granted) {if(![DF138Granted containsObject:bundle])return NO;}
 Class cls=object_getClass(info);
 Class db=objc_getClass("DBApplicationInfo");
 if(!db || ![info isKindOfClass:db])return NO;
 BOOL launch=NO;
 for(NSString *name in @[@"setCarPlaySupported:",@"setCanDisplayOnCarScreen:",
                          @"setLaunchAsCarApplication:"]) {
   SEL s=NSSelectorFromString(name);
   Method m=class_getInstanceMethod(cls,s);
   char r[16]={0},a[16]={0};
   if(!m || method_getNumberOfArguments(m)!=3)continue;
   method_getReturnType(m,r,sizeof(r));method_getArgumentType(m,2,a,sizeof(a));
   if(r[0]!='v' || (a[0]!='B' && a[0]!='c'))continue;
   ((void(*)(id,SEL,BOOL))objc_msgSend)(info,s,YES);
   if([name isEqualToString:@"setLaunchAsCarApplication:"])launch=YES;
 }
 SEL declaration=sel_registerName("carPlayDeclaration");
 id declared=DF138Exact(cls,declaration,"@16@0:8")?
   ((id(*)(id,SEL))objc_msgSend)(info,declaration):nil;
 DF138Log([NSString stringWithFormat:@"admitted-info bundle=%@ declaration=%@ launchSetter=%d; physical-icon-and-tap-unverified",
           bundle,declared?NSStringFromClass([declared class]):@"nil",launch]);
 return launch;
}
static id DF138Factory(id receiver,SEL s) {
 // Forward exactly once and retain the original library object/metadata.
 id library=DF138OriginalFactory?DF138OriginalFactory(receiver,s):nil;
 if(!library || !DFHome136Enabled())return library;
 @try {
   SEL all=sel_registerName("allInstalledApplications");
   if(DF138Exact(object_getClass(library),all,"@16@0:8")) {
     id infos=((id(*)(id,SEL))objc_msgSend)(library,all);
     if([infos isKindOfClass:NSArray.class])for(id info in infos)
         (void)DFHome138PromoteAdmittedInfo(info);
   }
   NSInteger count=DFHome136ReconcileVerifiedLibrary(library);
   DF138Log([NSString stringWithFormat:@"original-DashBoard-factory returned=%@ newRecords=%ld; not-icon-proof",
             NSStringFromClass([library class]),(long)count]);
 } @catch(NSException *e) {DF138Log([NSString stringWithFormat:@"factory-postprocess exception=%@",e.name]);}
 return library;
}
static void DF138Install(NSUInteger attempt) {
 if(DF138OriginalFactory || attempt>10)return;
 Class proxy=objc_getClass("LSBundleProxy"),dash=objc_getClass("DashBoard");
 SEL s3=sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:");
 SEL s2=sel_registerName("entitlementValueForKey:ofClass:");
 SEL factory=sel_registerName("_newApplicationLibrary");
 DF138Hook hook=(DF138Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(hook && DF138Exact(proxy,s3,"@40@0:8@16#24#32") &&
    DF138Exact(proxy,s2,"@32@0:8@16#24") &&
    DF138Exact(object_getClass(dash),factory,"@16@0:8")) {
   if(!DF138Original3)hook(proxy,s3,(IMP)DF138Entitlement3,(IMP *)&DF138Original3);
   if(!DF138Original2)hook(proxy,s2,(IMP)DF138Entitlement2,(IMP *)&DF138Original2);
   if(DF138Original3 && DF138Original2)
     hook(object_getClass(dash),factory,(IMP)DF138Factory,(IMP *)&DF138OriginalFactory);
   DF138Log([NSString stringWithFormat:@"ABI-checked hooks typed3=%d typed2=%d DashBoardFactory=%d; scope=CarPlay; switch=%d",
             DF138Original3!=NULL,DF138Original2!=NULL,DF138OriginalFactory!=NULL,DFHome136Enabled()]);
 }
 if(!DF138OriginalFactory && attempt<10)
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{DF138Install(attempt+1);});
}
__attribute__((constructor)) static void DF138Start(void) {
 @autoreleasepool {
   if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16 ||
      ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
   DF138Granted=[NSMutableSet set];
   // Arm early even if switch OFF: each answer rechecks the switch. This
   // intercepts initial library construction without waiting for a UI lookup.
   DF138Install(0);
 }
}
