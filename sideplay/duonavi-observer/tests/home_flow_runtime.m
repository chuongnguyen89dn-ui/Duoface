// Functional test of ACTUAL forwarding wrappers on Foundation runtime.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
static NSMutableArray *events;
static void DNLog(NSString *event,NSDictionary *fields){[events addObject:@{@"event":event,@"fields":fields}];}
#import "../HomeFlowTrace.h"
static BOOL failSnapshot;
static NSDictionary *DNFlowSnapshot(id receiver){
 if(failSnapshot)@throw [NSException exceptionWithName:@"ObserverFailure" reason:nil userInfo:nil];
 return @{@"identity":DNFlowIdentity(receiver),@"bool":DNFlowBoolGet(receiver,"flag")};
}
static void FakeHook(Class cls,SEL sel,IMP imp,IMP *old){*old=method_setImplementation(class_getInstanceMethod(cls,sel),imp);}
@interface DNTestForward:NSObject
@property NSUInteger calls,value;
@property CGRect capturedFrame;
@property NSInteger capturedSlot;
@property(strong) id producedObject;
@property BOOL flag;
@property(strong) id first,second;
@property SEL command;
- (void)noArgs;
- (void)one:(id)a;
- (void)two:(id)a completion:(void(^)(void))b;
- (void)number:(NSUInteger)a;
- (void)boolean:(BOOL)a;
- (void)object:(id)a boolean:(BOOL)b;
- (void)throwing:(id)a;
- (void)homeButtonUp:(id)a;
- (id)appForBundleIdentifier:(id)bundle frame:(CGRect)frame;
- (void)showAppPickerForSlot:(NSInteger)slot;
@end
@implementation DNTestForward
- (void)noArgs{self.calls++;self.command=_cmd;}
- (void)one:(id)a{self.calls++;self.first=a;self.command=_cmd;}
- (void)two:(id)a completion:(void(^)(void))b{self.calls++;self.first=a;self.second=b;self.command=_cmd;}
- (void)number:(NSUInteger)a{self.calls++;self.value=a;self.command=_cmd;}
- (void)boolean:(BOOL)a{self.calls++;self.flag=a;self.command=_cmd;}
- (void)object:(id)a boolean:(BOOL)b{self.calls++;self.first=a;self.flag=b;self.command=_cmd;}
- (void)throwing:(id)a{self.calls++;self.first=a;@throw [NSException exceptionWithName:@"OriginalException" reason:@"must propagate" userInfo:nil];}
- (void)homeButtonUp:(id)a{self.calls++;self.first=a;self.command=_cmd;}
- (id)appForBundleIdentifier:(id)bundle frame:(CGRect)frame {
 self.calls++;self.first=bundle;self.capturedFrame=frame;self.command=_cmd;
 return self.producedObject;
}
- (void)showAppPickerForSlot:(NSInteger)slot {
 self.calls++;self.capturedSlot=slot;self.command=_cmd;
}
@end
@interface DNTestChild:DNTestForward @end
@implementation DNTestChild @end
#define CHECK(x) do{if(!(x)){NSLog(@"FAILED L%d %s",__LINE__,#x);return 1;}}while(0)
static DNFlowSpec specs[12];
static BOOL Install(unsigned n,const char *selector,DNFlowKind kind){
 Method m=class_getInstanceMethod(DNTestForward.class,sel_registerName(selector));
 specs[n]=(DNFlowSpec){"DNTestForward",selector,method_getTypeEncoding(m),kind,0,0,0,0};
 return DNFlowInstallOne(&specs[n],DNTestForward.class,FakeHook);
}
int main(void){@autoreleasepool{
 events=[NSMutableArray new];DNTestForward *o=[DNTestForward new];id marker=[NSObject new];
 (void)&DNHomeFlowInstall;
 CHECK(Install(0,"noArgs",DNFlowVoid));[o noArgs];CHECK(o.calls==1 && o.command==@selector(noArgs));
 CHECK(DNFlowInstallOne(&specs[0],DNTestForward.class,FakeHook));[o noArgs];CHECK(o.calls==2);
 CHECK(Install(1,"one:",DNFlowObjectArg));[o one:marker];CHECK(o.calls==3&&o.first==marker&&o.command==@selector(one:));
 __block int completions=0;void(^completion)(void)=^{completions++;};
 CHECK(Install(2,"two:completion:",DNFlowTwoObjects));[o two:marker completion:completion];
 CHECK(o.calls==4&&o.first==marker&&o.second==completion&&completions==0&&o.command==@selector(two:completion:));
 CHECK(Install(3,"number:",DNFlowUInt));[o number:NSUIntegerMax];CHECK(o.calls==5&&o.value==NSUIntegerMax);
 CHECK(Install(4,"boolean:",DNFlowBool));[o boolean:YES];CHECK(o.calls==6&&o.flag);
 CHECK(Install(5,"object:boolean:",DNFlowObjectBool));[o object:marker boolean:NO];CHECK(o.calls==7&&o.first==marker&&!o.flag);
 CHECK(Install(6,"throwing:",DNFlowObjectArg));BOOL propagated=NO;
 @try{[o throwing:marker];}@catch(NSException *e){propagated=[e.name isEqual:@"OriginalException"];}
 CHECK(propagated&&o.calls==8&&o.first==marker);
 failSnapshot=YES;[o one:marker];CHECK(o.calls==9);failSnapshot=NO;
 DNFlowSpec wrong={"DNTestForward","noArgs","v24@0:8@16",DNFlowObjectArg,0,0,0,0};
 CHECK(!DNFlowInstallOne(&wrong,DNTestForward.class,FakeHook)&&wrong.refused);
 DNFlowSpec inherited={"DNTestChild","noArgs","v16@0:8",DNFlowVoid,0,0,0,0};
 CHECK(!DNFlowInstallOne(&inherited,DNTestChild.class,FakeHook));
 CHECK(Install(7,"homeButtonUp:",DNFlowObjectArg));[o homeButtonUp:marker];CHECK(o.calls==10&&o.first==marker);
 [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.1]];
 CHECK(o.calls==10&&completions==0);
 CHECK([[events description] containsString:@"after-1000ms"]);
 CHECK([[events description] containsString:@"throw-unwind"]);
 atomic_store(&dnFlowSequence,10000);[o one:marker];CHECK(o.calls==11); // Budget never blocks original.
 puts("HOMEFLOW_ACTUAL_WRAPPERS_EXACT_ONCE_ARGS_BLOCK_IDENTITY_64BIT_THROW_ABI_INHERITANCE_BUDGET_AND_DELAYED_READBACK_PASS");
 return 0;
}}
