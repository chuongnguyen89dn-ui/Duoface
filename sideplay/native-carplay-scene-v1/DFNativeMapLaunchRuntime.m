// First-party implementation of the native object contract independently
// verified in original DEB SHA256 d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd.
// No vendor implementation is included. No scene, workspace or application is
// constructed here: the existing library supplies the actual application info.
#import "DFNativeMapLaunchRuntime.h"
#import "../duoface-native-scene-host/DFNativeMapLeasePolicy.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

static BOOL DFLaunchRefuse(NSString **reason,NSString *value) {
 if(reason)*reason=value;
 return NO;
}
static BOOL DFLaunchInstance(id object,Class expected) {
 if(!object || !expected || object_isClass(object))return NO;
 for(Class cls=object_getClass(object);cls;cls=class_getSuperclass(cls))
  if(cls==expected)return YES;
 return NO;
}
static BOOL DFLaunchObjectType(const char *type) {
 if(!type || type[0]!='@')return NO;
 // An object or a named object is ABI-compatible; a block is a different
 // semantic argument and must never pass as native app-info/event context.
 if(type[1]=='\0')return YES;
 size_t length=strlen(type);
 return length>3 && type[1]=='"' && type[length-1]=='"';
}
static BOOL DFLaunchType(Method method,unsigned int index,BOOL result,
                         const char *expected) {
 char *actual=result?method_copyReturnType(method):method_copyArgumentType(method,index);
 BOOL match=actual && (expected[0]=='@'?DFLaunchObjectType(actual):!strcmp(actual,expected));
 free(actual);
 return match;
}
static BOOL DFLaunchMethodShape(Method method,unsigned int count,const char *result) {
 return method && method_getNumberOfArguments(method)==count &&
     DFLaunchType(method,0,YES,result) &&
     DFLaunchType(method,0,NO,"@") && DFLaunchType(method,1,NO,":");
}
static Method DFLaunchObjectMethod(id receiver,const char *name,unsigned int arguments) {
 if(!receiver)return NULL;
 Method method=class_getInstanceMethod(object_getClass(receiver),sel_registerName(name));
 if(!DFLaunchMethodShape(method,arguments+2,"@"))return NULL;
 for(unsigned int index=2;index<arguments+2;index++)
  if(!DFLaunchType(method,index,NO,"@"))return NULL;
 return method;
}
static Method DFLaunchFactory(Class cls,const char *name,unsigned int arguments) {
 Method method=cls?class_getClassMethod(cls,sel_registerName(name)):NULL;
 if(!DFLaunchMethodShape(method,arguments+2,"@"))return NULL;
 for(unsigned int index=2;index<arguments+2;index++)
  if(!DFLaunchType(method,index,NO,"@"))return NULL;
 return method;
}
static id DFLaunchReadObject(id object,const char *name) {
 if(!DFLaunchObjectMethod(object,name,0))return nil;
 return ((id(*)(id,SEL))objc_msgSend)(object,sel_registerName(name));
}
static BOOL DFLaunchReadBool(id object,const char *name,BOOL *result) {
 Method method=object?class_getInstanceMethod(object_getClass(object),sel_registerName(name)):NULL;
 if(DFLaunchMethodShape(method,2,"B")) {
  *result=((BOOL(*)(id,SEL))objc_msgSend)(object,sel_registerName(name));return YES;
 }
 if(DFLaunchMethodShape(method,2,"c")) {
  *result=((signed char(*)(id,SEL))objc_msgSend)(object,sel_registerName(name))!=0;return YES;
 }
 return NO;
}
static BOOL DFLaunchReadDouble(id object,const char *name,double *result) {
 Method method=object?class_getInstanceMethod(object_getClass(object),sel_registerName(name)):NULL;
 if(!DFLaunchMethodShape(method,2,"d"))return NO;
 *result=((double(*)(id,SEL))objc_msgSend)(object,sel_registerName(name));return YES;
}
static BOOL DFLaunchStringEquals(id object,NSString *expected) {
 return DFLaunchInstance(object,NSString.class) && [object isEqualToString:expected];
}
static BOOL DFLaunchRequestID(id value) {
 return DFLaunchInstance(value,NSString.class) &&
        [[NSUUID alloc]initWithUUIDString:value]!=nil;
}
static BOOL DFLaunchOwnedContext(id value) {
 // Do not introduce a link-time Objective-C class dependency on the Dock dylib.
 return DFLaunchInstance(value,objc_getClass("DFNativeMapLaunchContext"));
}
static DFNativeMapLaunchContext *DFLaunchReadContext(
 DFNativeMapLaunchContextProvider provider,id root,id window,
 NSString *requestID,NSString **reason) {
 if(!provider || !root || !window || !DFLaunchRequestID(requestID)) {
  DFLaunchRefuse(reason,@"native-launch-context-provider-or-request-unavailable");return nil;
 }
 @try {
  DFNativeMapLaunchContext *context=provider(root,window,requestID,reason);
  if(!DFLaunchOwnedContext(context) ||
     !DFNativeMapLaunchContextsMatch(context,context) ||
     context.root!=root || context.window!=window ||
     !DFLaunchStringEquals(context.requestID,requestID)) {
   if(context || !reason || !*reason)
    DFLaunchRefuse(reason,@"native-launch-context-identity-unverified");
   return nil;
  }
  return context;
 } @catch(__unused NSException *exception) {
  DFLaunchRefuse(reason,@"native-launch-context-provider-exception");return nil;
 }
}
static BOOL DFLaunchEnvironment(NSString **reason) {
 NSString *process=NSProcessInfo.processInfo.processName;
 if(!NSThread.isMainThread ||
    !([process isEqual:@"CarPlay"] || [process isEqual:@"CarPlayApp"]))
  return DFLaunchRefuse(reason,@"native-launch-requires-carplay-main-thread");
 if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)
  return DFLaunchRefuse(reason,@"native-launch-os-version-unverified");
 return YES;
}
static DFNativeMapLaunchContextProvider DFLaunchProvider(void) {
 return (DFNativeMapLaunchContextProvider)dlsym(RTLD_DEFAULT,
                                      DF_NATIVE_MAP_LAUNCH_CONTEXT_SYMBOL);
}

static BOOL DFLaunchViewVisibleWithinRoot(id view,id rootView,id window,Class viewClass) {
 BOOL crossedRoot=NO;
 NSHashTable *seen=[NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
 for(NSUInteger depth=0;view && depth<64;depth++) {
  if(!DFLaunchInstance(view,viewClass) || [seen containsObject:view])return NO;
  [seen addObject:view];
  BOOL hidden=YES;double alpha=0;
  if(!DFLaunchReadBool(view,"isHidden",&hidden) || hidden ||
     !DFLaunchReadDouble(view,"alpha",&alpha) || !isfinite(alpha) || alpha<=0.01 ||
     DFLaunchReadObject(view,"window")!=window)return NO;
  if(view==rootView)crossedRoot=YES;
  if(view==window)return crossedRoot;
  if(!DFLaunchObjectMethod(view,"superview",0))return NO;
  view=DFLaunchReadObject(view,"superview");
 }
 return NO;
}
static BOOL DFLaunchPresentationReady(DFNativeMapLaunchContext *context,
                                      DFNativeMapLaunchRuntime runtime,
                                      id *acceptedBase,
                                      NSString **reason) {
 if(acceptedBase)*acceptedBase=nil;
 id root=context.root,window=context.window;
 Class homeClass=runtime.classNamed("DBDashboardHomeViewController");
 Class controllerClass=runtime.classNamed("UIViewController");
 Class viewClass=runtime.classNamed("UIView");
 if(!homeClass || !controllerClass || !viewClass ||
    !DFLaunchInstance(root,controllerClass))
  return DFLaunchRefuse(reason,@"native-launch-home-class-unverified");
 // Original normal dispatch requires no current base, or an exact pane VC
 // it already owns. The additional first-party case below is only our exact
 // independently bound live DuoFace base. Never force past another app or
 // copy the original timed forced-dispatch fallback.
 if(!DFLaunchObjectMethod(root,"currentBaseViewController",0))
  return DFLaunchRefuse(reason,@"native-launch-current-base-abi-unverified");
 id base=DFLaunchReadObject(root,"currentBaseViewController");
 id rootView=DFLaunchReadObject(root,"viewIfLoaded");
 if(!DFLaunchInstance(rootView,viewClass))
  return DFLaunchRefuse(reason,@"native-launch-home-view-unverified");
 if(base) {
  Class sceneController=runtime.classNamed("DBApplicationSceneViewController");
  Class infoClass=runtime.classNamed("DBApplicationInfo");
  if(base!=context.ownedBase || !DFLaunchInstance(base,sceneController))
   return DFLaunchRefuse(reason,@"native-launch-current-base-not-verified-duoface-owner");
  id info=DFLaunchReadObject(base,"applicationInfo");
  if(!info)info=DFLaunchReadObject(base,"proxyApplicationInfo");
  if(!DFLaunchInstance(info,infoClass) ||
     !DFLaunchStringEquals(DFLaunchReadObject(info,"bundleIdentifier"),@"com.duoface.native.scenehost"))
   return DFLaunchRefuse(reason,@"native-launch-owned-base-bundle-unverified");
  // ownedBase comes from the live provider, which already verifies the unique
  // foreground FBScene, physical/host session, visible ancestors, window and
  // controller ancestry. UIKit controller ownership does not require its view
  // to descend through root.viewIfLoaded (native containers may be siblings).
  // Recheck the loaded leaf and exact window here; never turn Rejected into Applied.
  id baseView=DFLaunchReadObject(base,"viewIfLoaded");
  BOOL hidden=YES;double alpha=0;
  if(!DFLaunchInstance(baseView,viewClass) ||
     DFLaunchReadObject(baseView,"window")!=window ||
     DFLaunchReadObject(rootView,"window")!=window ||
     !DFLaunchReadBool(baseView,"isHidden",&hidden) || hidden ||
     !DFLaunchReadDouble(baseView,"alpha",&alpha) || !isfinite(alpha) || alpha<=0.01)
   return DFLaunchRefuse(reason,@"native-launch-owned-base-view-unverified");
  NSHashTable *ancestors=[NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
  for(id cursor=base;cursor && ancestors.count<32;cursor=DFLaunchReadObject(cursor,"parentViewController")) {
   if(!DFLaunchInstance(cursor,controllerClass) || [ancestors containsObject:cursor])break;
   [ancestors addObject:cursor];
   if(!DFLaunchObjectMethod(cursor,"presentedViewController",0) ||
      DFLaunchReadObject(cursor,"presentedViewController"))
    return DFLaunchRefuse(reason,@"native-launch-presentation-in-progress");
   if(cursor==root) {
    if(acceptedBase)*acceptedBase=base;
    return YES;
   }
  }
  return DFLaunchRefuse(reason,@"native-launch-owned-base-ancestry-unverified");
 }
 NSMutableArray *queue=[NSMutableArray arrayWithObject:@{@"node":root,@"depth":@0}];
 NSHashTable *seen=[NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
 NSUInteger visibleHomes=0;
 for(NSUInteger index=0;index<queue.count && index<128;index++) {
  NSDictionary *entry=queue[index];id node=entry[@"node"];
  NSUInteger depth=[entry[@"depth"] unsignedIntegerValue];
  if(depth>12 || !DFLaunchInstance(node,controllerClass) || [seen containsObject:node])
   return DFLaunchRefuse(reason,@"native-launch-home-hierarchy-unverified");
  [seen addObject:node];
  if(!DFLaunchObjectMethod(node,"presentedViewController",0) ||
     DFLaunchReadObject(node,"presentedViewController"))
   return DFLaunchRefuse(reason,@"native-launch-presentation-in-progress");
  if(DFLaunchInstance(node,homeClass) &&
     DFLaunchViewVisibleWithinRoot(DFLaunchReadObject(node,"viewIfLoaded"),rootView,window,viewClass))
   visibleHomes++;
  id children=DFLaunchReadObject(node,"childViewControllers");
  if(!DFLaunchInstance(children,NSArray.class))
   return DFLaunchRefuse(reason,@"native-launch-home-children-unverified");
  for(id child in children) {
   if(queue.count>=128 || !DFLaunchInstance(child,controllerClass) ||
      DFLaunchReadObject(child,"parentViewController")!=node)
    return DFLaunchRefuse(reason,@"native-launch-home-ancestry-unverified");
   [queue addObject:@{@"node":child,@"depth":@(depth+1)}];
  }
 }
 return visibleHomes==1?YES:DFLaunchRefuse(reason,@"native-launch-visible-home-not-unique");
}
DFNativeMapLaunchContext *DFNativeMapResolveLaunchContext(
 id expectedRoot,id expectedWindow,NSString *requestID,NSString **reason) {
 if(reason)*reason=nil;
 if(!DFLaunchEnvironment(reason))return nil;
 return DFLaunchReadContext(DFLaunchProvider(),expectedRoot,expectedWindow,requestID,reason);
}

typedef NS_ENUM(unsigned char,DFLaunchEventInteger) {
 DFLaunchEventIntegerUnsupported=0,DFLaunchEventSigned64,DFLaunchEventUnsigned64,
 DFLaunchEventSigned32,DFLaunchEventUnsigned32
};
static DFLaunchEventInteger DFLaunchEventFactoryABI(Class eventClass) {
 Method method=eventClass?class_getClassMethod(eventClass,
                                    sel_registerName("eventWithType:context:")):NULL;
 if(!DFLaunchMethodShape(method,4,"@") || !DFLaunchType(method,3,NO,"@"))
  return DFLaunchEventIntegerUnsupported;
 if(DFLaunchType(method,2,NO,"q"))return DFLaunchEventSigned64;
 if(DFLaunchType(method,2,NO,"Q"))return DFLaunchEventUnsigned64;
 if(DFLaunchType(method,2,NO,"i"))return DFLaunchEventSigned32;
 if(DFLaunchType(method,2,NO,"I"))return DFLaunchEventUnsigned32;
 return DFLaunchEventIntegerUnsupported;
}
static id DFLaunchEvent(Class eventClass,DFLaunchEventInteger abi,id info) {
 SEL selector=sel_registerName("eventWithType:context:");
 // Each accepted encoding has its own typed call. Event 4 and the unchanged
 // native launch-info context are the proven original semantic contract.
 switch(abi) {
  case DFLaunchEventSigned64:
   return ((id(*)(id,SEL,int64_t,id))objc_msgSend)(eventClass,selector,INT64_C(4),info);
  case DFLaunchEventUnsigned64:
   return ((id(*)(id,SEL,uint64_t,id))objc_msgSend)(eventClass,selector,UINT64_C(4),info);
  case DFLaunchEventSigned32:
   return ((id(*)(id,SEL,int32_t,id))objc_msgSend)(eventClass,selector,INT32_C(4),info);
  case DFLaunchEventUnsigned32:
   return ((id(*)(id,SEL,uint32_t,id))objc_msgSend)(eventClass,selector,UINT32_C(4),info);
  default:return nil;
 }
}
BOOL DFNativeMapDispatchLaunchUsingRuntime(
 NSString *bundle,DFNativeMapLaunchContext *expected,
 DFNativeMapLaunchRuntime runtime,DFNativeMapLaunchRequestGuard stillCurrent,
 NSString **reason) {
 if(reason)*reason=nil;
 if(!NSThread.isMainThread || !DFNativeMapAllowedBundle(bundle) ||
    !runtime.classNamed || !runtime.contextProvider || !runtime.homeGeneration || !stillCurrent ||
    !DFLaunchOwnedContext(expected))
  return DFLaunchRefuse(reason,@"native-launch-request-or-runtime-invalid");
 NSString *stage=@"context";
 @try {
  NSString *requestID=[expected.requestID copy];
  id root=expected.root,window=expected.window;
  DFNativeMapLaunchContext *current=DFLaunchReadContext(runtime.contextProvider,
                                           root,window,requestID,reason);
  if(!current)return NO;
  if(!DFNativeMapLaunchContextsMatch(expected,current))
   return DFLaunchRefuse(reason,@"native-launch-context-changed-before-dispatch");
  if(!stillCurrent())return DFLaunchRefuse(reason,@"native-launch-request-no-longer-current");
  id acceptedBase=nil;
  if(!DFLaunchPresentationReady(current,runtime,&acceptedBase,reason))return NO;
  if(runtime.homeGeneration()!=expected.homeGeneration)
   return DFLaunchRefuse(reason,@"native-launch-home-generation-changed-before-factories");
  id dashboard=current.dashboard;
  Class applicationClass=runtime.classNamed("UIApplication");
  Class libraryClass=runtime.classNamed("FBSApplicationLibrary");
  Class infoClass=runtime.classNamed("DBApplicationInfo");
  Class declarationClass=runtime.classNamed("CRCarPlayAppDeclaration");
  Class launchClass=runtime.classNamed("DBApplicationLaunchInfo");
  Class eventClass=runtime.classNamed("DBEvent");
  if(!applicationClass || !libraryClass || !infoClass || !declarationClass ||
     !launchClass || !eventClass)
   return DFLaunchRefuse(reason,@"native-launch-required-class-unavailable");
  if(!DFLaunchFactory(applicationClass,"sharedApplication",0))
   return DFLaunchRefuse(reason,@"native-launch-shared-application-abi-unverified");
  Method handle=class_getInstanceMethod(object_getClass(dashboard),sel_registerName("handleEvent:"));
  if(!DFLaunchMethodShape(handle,3,"v") || !DFLaunchType(handle,2,NO,"@"))
   return DFLaunchRefuse(reason,@"native-launch-dashboard-event-abi-unverified");
  DFLaunchEventInteger eventABI=DFLaunchEventFactoryABI(eventClass);
  if(eventABI==DFLaunchEventIntegerUnsupported)
   return DFLaunchRefuse(reason,@"native-launch-event-factory-abi-unverified");
  const char *factory="launchInfoForApplication:";
  BOOL settings=NO;
  Method primary=class_getClassMethod(launchClass,sel_registerName(factory));
  if(primary) {
   if(!DFLaunchFactory(launchClass,factory,1))
    return DFLaunchRefuse(reason,@"native-launch-info-factory-abi-unverified");
  } else {
   factory="launchInfoForApplication:withActivationSettings:";settings=YES;
   if(!DFLaunchFactory(launchClass,factory,2))
    return DFLaunchRefuse(reason,@"native-launch-info-factory-unavailable");
  }
  stage=@"application-library";
  id application=((id(*)(id,SEL))objc_msgSend)(applicationClass,
                                                    sel_registerName("sharedApplication"));
  if(!DFLaunchInstance(application,applicationClass))
   return DFLaunchRefuse(reason,@"native-launch-shared-application-object-unverified");
  id library=DFLaunchReadObject(application,"sharedApplicationLibrary");
  if(!DFLaunchInstance(library,libraryClass))
   return DFLaunchRefuse(reason,@"native-launch-existing-library-unverified");
  if(!DFLaunchObjectMethod(library,"applicationInfoForBundleIdentifier:",1))
   return DFLaunchRefuse(reason,@"native-launch-application-lookup-abi-unverified");
  stage=@"application-info";
  id info=((id(*)(id,SEL,id))objc_msgSend)(library,
                         sel_registerName("applicationInfoForBundleIdentifier:"),bundle);
  if(!DFLaunchInstance(info,infoClass) ||
     !DFLaunchStringEquals(DFLaunchReadObject(info,"bundleIdentifier"),bundle))
   return DFLaunchRefuse(reason,@"native-launch-application-info-bundle-unverified");
  id declaration=DFLaunchReadObject(info,"carPlayDeclaration");
  if(!DFLaunchInstance(declaration,declarationClass) ||
     !DFLaunchStringEquals(DFLaunchReadObject(declaration,"bundleIdentifier"),bundle))
   return DFLaunchRefuse(reason,@"native-launch-carplay-declaration-unverified");
  stage=@"launch-info";
  id launchInfo=settings?
      ((id(*)(id,SEL,id,id))objc_msgSend)(launchClass,sel_registerName(factory),info,nil):
      ((id(*)(id,SEL,id))objc_msgSend)(launchClass,sel_registerName(factory),info);
  if(!DFLaunchInstance(launchInfo,launchClass))
   return DFLaunchRefuse(reason,@"native-launch-info-result-unverified");
  stage=@"event-factory";
  id event=DFLaunchEvent(eventClass,eventABI,launchInfo);
  if(!DFLaunchInstance(event,eventClass))
   return DFLaunchRefuse(reason,@"native-launch-event-result-unverified");
  // Native factories may synchronously invoke callbacks. Home, a replacement
  // dashboard or a dead weak identity must still win before the event is sent.
  current=DFLaunchReadContext(runtime.contextProvider,root,window,requestID,reason);
  if(!current)return NO;
  if(!DFNativeMapLaunchContextsMatch(expected,current))
   return DFLaunchRefuse(reason,@"native-launch-context-changed-before-event");
  id currentBase=nil;
  if(!DFLaunchPresentationReady(current,runtime,&currentBase,reason))return NO;
  if(currentBase!=acceptedBase)
   return DFLaunchRefuse(reason,@"native-launch-base-changed-during-preparation");
  // A late presentation getter may replace the base after the traversal's
  // first read. Check its actual pointer once more, without restarting a
  // native scan; then only pure first-party guards remain before dispatch.
  if(!DFLaunchObjectMethod(root,"currentBaseViewController",0) ||
     DFLaunchReadObject(root,"currentBaseViewController")!=acceptedBase)
   return DFLaunchRefuse(reason,@"native-launch-base-changed-before-event");
  if(!stillCurrent())return DFLaunchRefuse(reason,@"native-launch-request-no-longer-current");
  handle=class_getInstanceMethod(object_getClass(dashboard),sel_registerName("handleEvent:"));
  if(!DFLaunchMethodShape(handle,3,"v") || !DFLaunchType(handle,2,NO,"@"))
   return DFLaunchRefuse(reason,@"native-launch-dashboard-event-abi-changed");
  // Presentation getters and the request guard can reenter. A pure first-
  // party generation read is the final boundary; do not rescan UIKit again.
  if(runtime.homeGeneration()!=expected.homeGeneration)
   return DFLaunchRefuse(reason,@"native-launch-home-generation-changed-before-event");
  stage=@"handle-event";
  ((void(*)(id,SEL,id))objc_msgSend)(dashboard,sel_registerName("handleEvent:"),event);
  if(reason)*reason=@"native-launch-event-submitted-awaiting-observed-scene";
  return YES;
 } @catch(__unused NSException *exception) {
  return DFLaunchRefuse(reason,[@"native-launch-exception-" stringByAppendingString:stage]);
 }
}
static Class DFLaunchClassNamed(const char *name){return objc_getClass(name);}
BOOL DFNativeMapDispatchLaunchGuarded(NSString *bundle,DFNativeMapLaunchContext *expected,
                                     DFNativeMapLaunchRequestGuard stillCurrent,
                                     NSString **reason) {
 if(reason)*reason=nil;
 if(!DFLaunchEnvironment(reason))return NO;
 DFNativeMapLaunchRuntime runtime={DFLaunchClassNamed,DFLaunchProvider(),
  (uint64_t(*)(void))dlsym(RTLD_DEFAULT,DF_NATIVE_MAP_HOME_GENERATION_SYMBOL)};
 return DFNativeMapDispatchLaunchUsingRuntime(bundle,expected,runtime,stillCurrent,reason);
}
