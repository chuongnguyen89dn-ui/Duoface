// QA141: fill the measured missing DB info declaration, with QA140 guard.
// Global CR declaration factory interception removed: Log19 shows it did not
// populate these DB records. Native nonnil declarations and policy pass through.
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

typedef void (*DF141Hook)(Class,SEL,IMP,IMP *);
static id (*DF141Original3)(id,SEL,id,Class,Class);
static id (*DF141Original2)(id,SEL,id,Class);
static id (*DF141OriginalFactory)(id,SEL);
static id (*DF141OriginalPolicy)(id,SEL,id);
static char DF141OwnedDeclarationKey;
static NSMutableSet<NSString *> *DF141Granted;
// Real Log18 proves saved getter2 forwards into hooked getter3. Guard the
// native-query chain per thread, including exceptions; do not synthesize
// values or read preference files during a nested native-only lookup.
static _Thread_local unsigned int DF141NativeReadDepth=0;
extern NSInteger DFHome136ReconcileVerifiedLibrary(id library);

static void DF141Log(NSString *message) {
 NSString *line=[NSString stringWithFormat:@"[DFHome141] time=%.3f pid=%d %@\n",
                 NSDate.date.timeIntervalSince1970,getpid(),message];
 int fd=open("/var/mobile/Library/Logs/DuoFaceHomeAdmission141.log",O_CREAT|O_APPEND|O_WRONLY,0644);
 if(fd<0)return;
 NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
 if(data.length)(void)write(fd,data.bytes,data.length);
 close(fd);
}
static BOOL DF141Exact(Class cls,SEL selector,const char *type) {
 Method m=cls?class_getInstanceMethod(cls,selector):NULL;
 return m && method_getTypeEncoding(m) && !strcmp(method_getTypeEncoding(m),type);
}
static NSString *DF141Bundle(id proxy) {
 SEL s=sel_registerName("bundleIdentifier");
 if(!DF141Exact(object_getClass(proxy),s,"@16@0:8"))return nil;
 id name=((id(*)(id,SEL))objc_msgSend)(proxy,s);
 return [name isKindOfClass:NSString.class]?name:nil;
}
static BOOL DF141Selected(NSString *bundle) {
 return DFHome140Enabled() && DFIsRecommendedAppID(bundle) &&
        DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs());
}
static id DF141Answer(id proxy,id key,Class expected,Class values,id original) {
 // Real native capabilities always win. Do not invent template entitlements,
 // scene manifests, SpringBoard bulk dictionaries or Apple app declarations.
 if(original || (expected && expected!=NSNumber.class) ||
    (values && values!=NSNumber.class) ||
    ![key isKindOfClass:NSString.class] ||
    (![(NSString *)key isEqualToString:@"CARCapableApp"] &&
     ![(NSString *)key isEqualToString:@"SBStarkCapable"]))return original;
 @try {
   NSString *bundle=DF141Bundle(proxy);
   if(!DF141Selected(bundle))return original;
   // A real native capability on either original getter preserves native apps.
   BOOL nativeCapability=NO;
   if(DF141Original2) {
     ++DF141NativeReadDepth;
     @try {
       nativeCapability=DF141Original2(proxy,sel_registerName("entitlementValueForKey:ofClass:"),@"CARCapableApp",NSNumber.class)!=nil ||
         DF141Original2(proxy,sel_registerName("entitlementValueForKey:ofClass:"),@"SBStarkCapable",NSNumber.class)!=nil;
     } @finally { --DF141NativeReadDepth; }
   }
   if(nativeCapability)return original;
   @synchronized(DF141Granted) {
     if(![DF141Granted containsObject:bundle]) {
       [DF141Granted addObject:bundle];
       DF141Log([NSString stringWithFormat:@"selected-LS-inclusion bundle=%@ key=%@",bundle,key]);
     }
   }
   return @YES;
 } @catch(__unused NSException *e) {return original;}
}
static id DF141Entitlement3(id proxy,SEL s,id key,Class expected,Class values) {
 if(!DF141Original3)return nil;
 id real=DF141Original3(proxy,s,key,expected,values);
 if(DF141NativeReadDepth)return real;
 return DF141Answer(proxy,key,expected,values,real);
}
static id DF141Entitlement2(id proxy,SEL s,id key,Class expected) {
 if(!DF141Original2)return nil;
 id real=DF141Original2(proxy,s,key,expected);
 if(DF141NativeReadDepth)return real;
 return DF141Answer(proxy,key,expected,Nil,real);
}
BOOL DFHome141RequestSelectedAdmission(id proxy) {
 NSString *bundle=DF141Bundle(proxy);
 if(!DF141Selected(bundle) || !DF141Original2)return NO;
 // Query the installed LS proxy through the verified hook, rather than
 // treating an old QA136 FBS record as proof of native CarPlay capability.
 SEL s=sel_registerName("entitlementValueForKey:ofClass:");
 if(!DF141Exact(object_getClass(proxy),s,"@32@0:8@16#24"))return NO;
 (void)((id(*)(id,SEL,id,Class))objc_msgSend)(proxy,s,@"CARCapableApp",NSNumber.class);
 @synchronized(DF141Granted) {return [DF141Granted containsObject:bundle];}
}
static BOOL DF141GrantedBundle(NSString *bundle) {
 if(!DF141Selected(bundle))return NO;
 @synchronized(DF141Granted) {return [DF141Granted containsObject:bundle];}
}
static BOOL DF141SetBool(id object,NSString *name,BOOL value) {
 SEL s=NSSelectorFromString(name);
 Method m=class_getInstanceMethod(object_getClass(object),s);
 char r[16]={0},a[16]={0};
 if(!m || method_getNumberOfArguments(m)!=3)return NO;
 method_getReturnType(m,r,sizeof(r));method_getArgumentType(m,2,a,sizeof(a));
 if(r[0]!='v' || (a[0]!='B' && a[0]!='c'))return NO;
 ((void(*)(id,SEL,BOOL))objc_msgSend)(object,s,value);
 return YES;
}
static id DF141CreateOwnedDeclaration(NSString *bundle) {
 if(!DF141GrantedBundle(bundle))return nil;
 Class cls=objc_getClass("CRCarPlayAppDeclaration");
 SEL set=sel_registerName("setBundleIdentifier:");
 if(!DF141Exact(cls,set,"v24@0:8@16"))return nil;
 id created=[[cls alloc] init];
 ((void(*)(id,SEL,id))objc_msgSend)(created,set,bundle);
 if(![DF141Bundle(created) isEqualToString:bundle])return nil;
 objc_setAssociatedObject(created,&DF141OwnedDeclarationKey,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
 return created;
}
BOOL DFHome141InfoHasDeclaration(id info) {
 SEL s=sel_registerName("carPlayDeclaration");
 return DF141Exact(object_getClass(info),s,"@16@0:8") &&
        ((id(*)(id,SEL))objc_msgSend)(info,s)!=nil;
}
// Log19 proves actual DBApplicationInfo remains nil despite FBS admission.
// Complete that very object, preserving all existing native declarations.
BOOL DFHome141CompleteInfo(id info) {
 Class db=objc_getClass("DBApplicationInfo");
 NSString *bundle=DF141Bundle(info);
 if(!db || ![info isKindOfClass:db] || !DF141GrantedBundle(bundle) ||
    DFHome141InfoHasDeclaration(info))return NO;
 SEL get=sel_registerName("carPlayDeclaration");
 if(!DF141Exact(object_getClass(info),get,"@16@0:8"))return NO;
 @try {
   id declaration=DF141CreateOwnedDeclaration(bundle);
   if(!declaration)return NO;
   SEL set=sel_registerName("setCarPlayDeclaration:");
   Ivar slot=NULL;
   NSString *route=@"none";
   if(DF141Exact(object_getClass(info),set,"v24@0:8@16")) {
      ((void(*)(id,SEL,id))objc_msgSend)(info,set,declaration);route=@"setter";
   } else {
      slot=class_getInstanceVariable(object_getClass(info),"_carPlayDeclaration");
      const char *type=slot?ivar_getTypeEncoding(slot):NULL;
      if(!type || type[0]!='@' || type[1]=='?' || object_getIvar(info,slot)!=nil) {
        DF141Log([NSString stringWithFormat:@"declaration-attach-unavailable bundle=%@ ivarType=%s",bundle,type?:"absent"]);
        return NO;
      }
      object_setIvarWithStrongDefault(info,slot,declaration);route=@"runtime-object-ivar";
   }
   id actual=((id(*)(id,SEL))objc_msgSend)(info,get);
   BOOL verified=actual==declaration && [DF141Bundle(actual) isEqual:bundle];
   if(!verified && slot && object_getIvar(info,slot)==declaration)
      object_setIvarWithStrongDefault(info,slot,nil);
   DF141Log([NSString stringWithFormat:@"declaration-attached bundle=%@ route=%@ getterReadback=%d",bundle,route,verified]);
   return verified;
 } @catch(NSException *e) {DF141Log([NSString stringWithFormat:@"declaration-attach-exception bundle=%@ exception=%@",bundle,e.name]);return NO;}
}
static id DF141Policy(id evaluator,SEL s,id declaration) {
 // Original ARM64 0x2f2c1c..0x2f2c28 stores the ORIGINAL evaluator return
 // in x20; subsequent setters act on that POLICY, not DBApplicationInfo.
 id policy=DF141OriginalPolicy?DF141OriginalPolicy(evaluator,s,declaration):nil;
 NSString *bundle=DF141Bundle(declaration);
 if(!policy || !DF141GrantedBundle(bundle) ||
    ![objc_getAssociatedObject(declaration,&DF141OwnedDeclarationKey) boolValue])return policy;
 @try {
   BOOL launch=DF141SetBool(policy,@"setLaunchAsCarApplication:",YES);
   BOOL capable=DF141SetBool(policy,@"setCarPlaySupported:",YES);
   BOOL display=DF141SetBool(policy,@"setCanDisplayOnCarScreen:",YES);
   BOOL phone=DF141SetBool(policy,@"setLaunchUsingTemplateUI:",NO);
   DF141Log([NSString stringWithFormat:@"selected-original-policy bundle=%@ class=%@ launch=%d capable=%d display=%d phone=%d; icon-and-tap-unverified",
      bundle,NSStringFromClass([policy class]),launch,capable,display,phone]);
 } @catch(NSException *e) {DF141Log([NSString stringWithFormat:@"policy exception=%@",e.name]);}
 return policy;
}
static id DF141Factory(id receiver,SEL s) {
 // Forward exactly once and retain the original library object/metadata.
 id library=DF141OriginalFactory?DF141OriginalFactory(receiver,s):nil;
 if(!library || !DFHome140Enabled())return library;
 @try {
   NSInteger count=DFHome136ReconcileVerifiedLibrary(library);
   DF141Log([NSString stringWithFormat:@"original-DashBoard-factory returned=%@ newRecords=%ld; not-icon-proof",
             NSStringFromClass([library class]),(long)count]);
 } @catch(NSException *e) {DF141Log([NSString stringWithFormat:@"factory-postprocess exception=%@",e.name]);}
 return library;
}
static void DF141Install(NSUInteger attempt) {
 if(DF141OriginalFactory || attempt>10)return;
 Class proxy=objc_getClass("LSBundleProxy"),dash=objc_getClass("DashBoard");
 SEL s3=sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:");
 SEL s2=sel_registerName("entitlementValueForKey:ofClass:");
 SEL factory=sel_registerName("_newApplicationLibrary");
 Class policy=objc_getClass("CRCarPlayAppPolicyEvaluator");
 SEL evaluate=sel_registerName("effectivePolicyForAppDeclaration:");
 DF141Hook hook=(DF141Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(hook && DF141Exact(proxy,s3,"@40@0:8@16#24#32") &&
    DF141Exact(proxy,s2,"@32@0:8@16#24") &&
    DF141Exact(object_getClass(dash),factory,"@16@0:8") &&
    DF141Exact(policy,evaluate,"@24@0:8@16")) {
   if(!DF141Original3)hook(proxy,s3,(IMP)DF141Entitlement3,(IMP *)&DF141Original3);
   if(!DF141Original2)hook(proxy,s2,(IMP)DF141Entitlement2,(IMP *)&DF141Original2);
   if(DF141Original3 && DF141Original2) {
     if(!DF141OriginalPolicy)hook(policy,evaluate,(IMP)DF141Policy,(IMP *)&DF141OriginalPolicy);
   }
   if(DF141Original3 && DF141Original2 && DF141OriginalPolicy)
     hook(object_getClass(dash),factory,(IMP)DF141Factory,(IMP *)&DF141OriginalFactory);
   DF141Log([NSString stringWithFormat:@"ABI-checked hooks typed3=%d typed2=%d DashBoardFactory=%d; scope=CarPlay; switch=%d",
             DF141Original3!=NULL,DF141Original2!=NULL,DF141OriginalFactory!=NULL,DFHome140Enabled()]);
 }
 if(!DF141OriginalFactory && attempt<10)
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{DF141Install(attempt+1);});
}
__attribute__((constructor)) static void DF141Start(void) {
 @autoreleasepool {
   if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16 ||
      ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
   DF141Granted=[NSMutableSet set];
   // Arm early even if switch OFF: each answer rechecks the switch. This
   // intercepts initial library construction without waiting for a UI lookup.
   DF141Install(0);
 }
}
