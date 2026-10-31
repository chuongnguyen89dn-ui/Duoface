// QA140: independent admission with native cross-getter reentry guard.
// Regression reproduced by real Log18; do not compile withdrawn QA138.
// Hook the real DashBoard factory BEFORE its FBS inclusion filter executes.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <dispatch/dispatch.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import "DFHome140Consent.h"
#import "DFEnabledAppsPolicy.h"

typedef void (*DF140Hook)(Class,SEL,IMP,IMP *);
static id (*DF140Original3)(id,SEL,id,Class,Class);
static id (*DF140Original2)(id,SEL,id,Class);
static id (*DF140OriginalFactory)(id,SEL);
static id (*DF140OriginalPolicy)(id,SEL,id);
static id (*DF140OriginalDeclaration)(id,SEL,id);
static NSMutableSet<NSString *> *DF140Granted;
// Real Log18 proves saved getter2 forwards into hooked getter3. Guard the
// native-query chain per thread, including exceptions; do not synthesize
// values or read preference files during a nested native-only lookup.
static _Thread_local unsigned int DF140NativeReadDepth=0;
extern NSInteger DFHome136ReconcileVerifiedLibrary(id library);

static void DF140Log(NSString *message) {
 NSString *line=[NSString stringWithFormat:@"[DFHome140] time=%.3f pid=%d %@\n",
                 NSDate.date.timeIntervalSince1970,getpid(),message];
 int fd=open("/var/mobile/Library/Logs/DuoFaceHomeAdmission140.log",O_CREAT|O_APPEND|O_WRONLY,0644);
 if(fd<0)return;
 NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
 if(data.length)(void)write(fd,data.bytes,data.length);
 close(fd);
}
static BOOL DF140Exact(Class cls,SEL selector,const char *type) {
 Method m=cls?class_getInstanceMethod(cls,selector):NULL;
 return m && method_getTypeEncoding(m) && !strcmp(method_getTypeEncoding(m),type);
}
static NSString *DF140Bundle(id proxy) {
 SEL s=sel_registerName("bundleIdentifier");
 if(!DF140Exact(object_getClass(proxy),s,"@16@0:8"))return nil;
 id name=((id(*)(id,SEL))objc_msgSend)(proxy,s);
 return [name isKindOfClass:NSString.class]?name:nil;
}
static BOOL DF140Selected(NSString *bundle) {
 return DFHome140Enabled() && DFIsRecommendedAppID(bundle) &&
        DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs());
}
static id DF140Answer(id proxy,id key,Class expected,Class values,id original) {
 // Real native capabilities always win. Do not invent template entitlements,
 // scene manifests, SpringBoard bulk dictionaries or Apple app declarations.
 if(original || (expected && expected!=NSNumber.class) ||
    (values && values!=NSNumber.class) ||
    ![key isKindOfClass:NSString.class] ||
    (![(NSString *)key isEqualToString:@"CARCapableApp"] &&
     ![(NSString *)key isEqualToString:@"SBStarkCapable"]))return original;
 @try {
   NSString *bundle=DF140Bundle(proxy);
   if(!DF140Selected(bundle))return original;
   // A real native capability on either original getter preserves native apps.
   BOOL nativeCapability=NO;
   if(DF140Original2) {
     ++DF140NativeReadDepth;
     @try {
       nativeCapability=DF140Original2(proxy,sel_registerName("entitlementValueForKey:ofClass:"),@"CARCapableApp",NSNumber.class)!=nil ||
         DF140Original2(proxy,sel_registerName("entitlementValueForKey:ofClass:"),@"SBStarkCapable",NSNumber.class)!=nil;
     } @finally { --DF140NativeReadDepth; }
   }
   if(nativeCapability)return original;
   @synchronized(DF140Granted) {
     if(![DF140Granted containsObject:bundle]) {
       [DF140Granted addObject:bundle];
       DF140Log([NSString stringWithFormat:@"selected-LS-inclusion bundle=%@ key=%@",bundle,key]);
     }
   }
   return @YES;
 } @catch(__unused NSException *e) {return original;}
}
static id DF140Entitlement3(id proxy,SEL s,id key,Class expected,Class values) {
 if(!DF140Original3)return nil;
 id real=DF140Original3(proxy,s,key,expected,values);
 if(DF140NativeReadDepth)return real;
 return DF140Answer(proxy,key,expected,values,real);
}
static id DF140Entitlement2(id proxy,SEL s,id key,Class expected) {
 if(!DF140Original2)return nil;
 id real=DF140Original2(proxy,s,key,expected);
 if(DF140NativeReadDepth)return real;
 return DF140Answer(proxy,key,expected,Nil,real);
}
BOOL DFHome140RequestSelectedAdmission(id proxy) {
 NSString *bundle=DF140Bundle(proxy);
 if(!DF140Selected(bundle) || !DF140Original2)return NO;
 // Query the installed LS proxy through the verified hook, rather than
 // treating an old QA136 FBS record as proof of native CarPlay capability.
 SEL s=sel_registerName("entitlementValueForKey:ofClass:");
 if(!DF140Exact(object_getClass(proxy),s,"@32@0:8@16#24"))return NO;
 (void)((id(*)(id,SEL,id,Class))objc_msgSend)(proxy,s,@"CARCapableApp",NSNumber.class);
 @synchronized(DF140Granted) {return [DF140Granted containsObject:bundle];}
}
static BOOL DF140GrantedBundle(NSString *bundle) {
 if(!DF140Selected(bundle))return NO;
 @synchronized(DF140Granted) {return [DF140Granted containsObject:bundle];}
}
static BOOL DF140SetBool(id object,NSString *name,BOOL value) {
 SEL s=NSSelectorFromString(name);
 Method m=class_getInstanceMethod(object_getClass(object),s);
 char r[16]={0},a[16]={0};
 if(!m || method_getNumberOfArguments(m)!=3)return NO;
 method_getReturnType(m,r,sizeof(r));method_getArgumentType(m,2,a,sizeof(a));
 if(r[0]!='v' || (a[0]!='B' && a[0]!='c'))return NO;
 ((void(*)(id,SEL,BOOL))objc_msgSend)(object,s,value);
 return YES;
}
static id DF140Declaration(id receiver,SEL s,id proxy) {
 id declaration=DF140OriginalDeclaration?DF140OriginalDeclaration(receiver,s,proxy):nil;
 // Keep native declarations intact. Only a nil result for a genuinely
 // selected, installed LS proxy admitted by our typed gate can be filled.
 if(declaration || !DFHome140RequestSelectedAdmission(proxy))return declaration;
 NSString *bundle=DF140Bundle(proxy);
 Class cls=objc_getClass("CRCarPlayAppDeclaration");
 SEL set=sel_registerName("setBundleIdentifier:");
 if(!DF140Exact(cls,set,"v24@0:8@16"))return nil;
 @try {
   id created=[[cls alloc] init];
   ((void(*)(id,SEL,id))objc_msgSend)(created,set,bundle);
   if(![DF140Bundle(created) isEqualToString:bundle])return nil;
   DF140Log([NSString stringWithFormat:@"selected-declaration-created bundle=%@ class=%@",bundle,NSStringFromClass(cls)]);
   return created;
 } @catch(__unused NSException *e) {return nil;}
}
static id DF140Policy(id evaluator,SEL s,id declaration) {
 // Original ARM64 0x2f2c1c..0x2f2c28 stores the ORIGINAL evaluator return
 // in x20; subsequent setters act on that POLICY, not DBApplicationInfo.
 id policy=DF140OriginalPolicy?DF140OriginalPolicy(evaluator,s,declaration):nil;
 NSString *bundle=DF140Bundle(declaration);
 if(!policy || !DF140GrantedBundle(bundle))return policy;
 @try {
   BOOL launch=DF140SetBool(policy,@"setLaunchAsCarApplication:",YES);
   BOOL capable=DF140SetBool(policy,@"setCarPlaySupported:",YES);
   BOOL display=DF140SetBool(policy,@"setCanDisplayOnCarScreen:",YES);
   BOOL phone=DF140SetBool(policy,@"setLaunchUsingTemplateUI:",NO);
   DF140Log([NSString stringWithFormat:@"selected-original-policy bundle=%@ class=%@ launch=%d capable=%d display=%d phone=%d; icon-and-tap-unverified",
      bundle,NSStringFromClass([policy class]),launch,capable,display,phone]);
 } @catch(NSException *e) {DF140Log([NSString stringWithFormat:@"policy exception=%@",e.name]);}
 return policy;
}
// AppInfo is observed only. The native evaluator above owns launch flags.
BOOL DFHome140PromoteAdmittedInfo(id info) {
 NSString *bundle=DF140Bundle(info);
 if(!DF140GrantedBundle(bundle))return NO;
 Class cls=object_getClass(info);
 Class db=objc_getClass("DBApplicationInfo");
 if(!db || ![info isKindOfClass:db])return NO;
 SEL declaration=sel_registerName("carPlayDeclaration");
 id declared=DF140Exact(cls,declaration,"@16@0:8")?
   ((id(*)(id,SEL))objc_msgSend)(info,declaration):nil;
 DF140Log([NSString stringWithFormat:@"admitted-info bundle=%@ declaration=%@; policy-receiver-separate; physical-icon-and-tap-unverified",
           bundle,declared?NSStringFromClass([declared class]):@"nil"]);
 return declared!=nil;
}
static id DF140Factory(id receiver,SEL s) {
 // Forward exactly once and retain the original library object/metadata.
 id library=DF140OriginalFactory?DF140OriginalFactory(receiver,s):nil;
 if(!library || !DFHome140Enabled())return library;
 @try {
   SEL all=sel_registerName("allInstalledApplications");
   if(DF140Exact(object_getClass(library),all,"@16@0:8")) {
     id infos=((id(*)(id,SEL))objc_msgSend)(library,all);
     if([infos isKindOfClass:NSArray.class])for(id info in infos)
         (void)DFHome140PromoteAdmittedInfo(info);
   }
   NSInteger count=DFHome136ReconcileVerifiedLibrary(library);
   DF140Log([NSString stringWithFormat:@"original-DashBoard-factory returned=%@ newRecords=%ld; not-icon-proof",
             NSStringFromClass([library class]),(long)count]);
 } @catch(NSException *e) {DF140Log([NSString stringWithFormat:@"factory-postprocess exception=%@",e.name]);}
 return library;
}
static void DF140Install(NSUInteger attempt) {
 if(DF140OriginalFactory || attempt>10)return;
 Class proxy=objc_getClass("LSBundleProxy"),dash=objc_getClass("DashBoard");
 SEL s3=sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:");
 SEL s2=sel_registerName("entitlementValueForKey:ofClass:");
 SEL factory=sel_registerName("_newApplicationLibrary");
 Class policy=objc_getClass("CRCarPlayAppPolicyEvaluator");
 Class declaration=objc_getClass("CRCarPlayAppDeclaration");
 SEL evaluate=sel_registerName("effectivePolicyForAppDeclaration:");
 SEL declare=sel_registerName("declarationForAppProxy:");
 DF140Hook hook=(DF140Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(hook && DF140Exact(proxy,s3,"@40@0:8@16#24#32") &&
    DF140Exact(proxy,s2,"@32@0:8@16#24") &&
    DF140Exact(object_getClass(dash),factory,"@16@0:8") &&
    DF140Exact(policy,evaluate,"@24@0:8@16") &&
    DF140Exact(object_getClass(declaration),declare,"@24@0:8@16")) {
   if(!DF140Original3)hook(proxy,s3,(IMP)DF140Entitlement3,(IMP *)&DF140Original3);
   if(!DF140Original2)hook(proxy,s2,(IMP)DF140Entitlement2,(IMP *)&DF140Original2);
   if(DF140Original3 && DF140Original2) {
     if(!DF140OriginalPolicy)hook(policy,evaluate,(IMP)DF140Policy,(IMP *)&DF140OriginalPolicy);
     if(!DF140OriginalDeclaration)hook(object_getClass(declaration),declare,(IMP)DF140Declaration,(IMP *)&DF140OriginalDeclaration);
   }
   if(DF140Original3 && DF140Original2 && DF140OriginalPolicy && DF140OriginalDeclaration)
     hook(object_getClass(dash),factory,(IMP)DF140Factory,(IMP *)&DF140OriginalFactory);
   DF140Log([NSString stringWithFormat:@"ABI-checked hooks typed3=%d typed2=%d DashBoardFactory=%d; scope=CarPlay; switch=%d",
             DF140Original3!=NULL,DF140Original2!=NULL,DF140OriginalFactory!=NULL,DFHome140Enabled()]);
 }
 if(!DF140OriginalFactory && attempt<10)
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{DF140Install(attempt+1);});
}
__attribute__((constructor)) static void DF140Start(void) {
 @autoreleasepool {
   if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16 ||
      ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
   DF140Granted=[NSMutableSet set];
   // Arm early even if switch OFF: each answer rechecks the switch. This
   // intercepts initial library construction without waiting for a UI lookup.
   DF140Install(0);
 }
}
