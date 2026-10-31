// QA143: first-party CarPlay Home tap -> genuine DuoFace icon -> existing hosted scene.
// Exact iOS16.7.16 selector v32@0:8@16@24 from physical Log21.
// Never invent a native DBApplication, spoof permissions, or synthesize a CPWindow.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import "DFHome140Consent.h"
#import "DFEnabledAppsPolicy.h"

typedef void (*DF143Hook)(Class,SEL,IMP,IMP *);
static void (*DF143Original)(id,SEL,id,id);
static NSString *const DF143HostID=@"com.duoface.native.scenehost";
static NSString *const DF143Path=@"/var/mobile/Library/Preferences/com.duoface.nativehost.home143-request.plist";
static NSString *const DF143LogPath=@"/var/mobile/Library/Logs/DuoFaceHomeLaunch143.log";
static unsigned long DF143Sequence;
static void DF143Log(NSString *message) {
 NSString *line=[NSString stringWithFormat:@"[DFHome143] time=%.3f pid=%d %@\n",
                  NSDate.date.timeIntervalSince1970,getpid(),message?:@""];
 int fd=open(DF143LogPath.fileSystemRepresentation,O_CREAT|O_WRONLY|O_APPEND,0644);
 if(fd<0)return;
 NSData *d=[line dataUsingEncoding:NSUTF8StringEncoding];
 if(d.length)(void)write(fd,d.bytes,d.length);
 close(fd);
}
// Never invoke an unknown ABI. Only exact no-argument object getters.
static id DF143Getter(id o,const char *methodName) {
 if(!o || !methodName)return nil;
 SEL sel=sel_registerName(methodName);
 Method method=class_getInstanceMethod(object_getClass(o),sel);
 if(!method || strcmp(method_getTypeEncoding(method),"@16@0:8"))return nil;
 @try {return ((id(*)(id,SEL))objc_msgSend)(o,sel);}
 @catch(__unused NSException *e){return nil;}
}
// A measured object graph may expose bundleIdentifier directly or on an icon model.
// No KVC, no raw ivar reads, no arbitrary selector invocation.
static NSString *DF143Bundle(id object,NSUInteger depth) {
 if(!object || depth>=3)return nil;
 for(const char *const *s=(const char*[]){ "bundleIdentifier","bundleID",
        "applicationIdentifier","displayIdentifier",NULL };*s;s++) {
   id value=DF143Getter(object,*s);
   if([value isKindOfClass:NSString.class] && ((NSString *)value).length)
      return value;
 }
 static const char *const nested[]={"application","representedApplication",
        "applicationInfo","icon","representedIcon","model",NULL};
 for(unsigned i=0;nested[i];i++) {
   id child=DF143Getter(object,nested[i]);
   if(child && child!=object) {
     NSString *bundle=DF143Bundle(child,depth+1);
     if(bundle.length)return bundle;
   }
 }
 return nil;
}
static BOOL DF143Chosen(NSString *bundle) {
 return [bundle isKindOfClass:NSString.class] &&
        DFHome140Enabled() &&
        DFIsRecommendedAppID(bundle) &&
        DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs());
}
static UIView *DF143FindHostInView(UIView *root,Class tappedClass,
                                   unsigned *count,NSUInteger depth) {
 if(!root || !count || ++(*count)>3500 || depth>30)return nil;
 if(!root.hidden && root.alpha>.05 && [root isKindOfClass:tappedClass] &&
    [DF143Bundle(root,0) isEqualToString:DF143HostID])return root;
 for(UIView *child in root.subviews) {
    UIView *match=DF143FindHostInView(child,tappedClass,count,depth+1);
    if(match)return match;
    if(*count>3500)break;
 }
 return nil;
}
static id DF143NativeHostIcon(id selected) {
 if(![selected isKindOfClass:UIView.class])return nil;
 Class tappedClass=object_getClass(selected);
 unsigned n=0;
 for(UIWindow *window in UIApplication.sharedApplication.windows) {
    if(window.hidden || window.alpha<.05)continue;
    UIView *found=DF143FindHostInView(window,tappedClass,&n,0);
    if(found)return found;
 }
 return nil;
}
static void DF143Launch(id owner,SEL selector,id manager,id iconView) {
 // One original forwarding path. Never intercept a known Apple, native, disabled,
 // unrecognized, or non-UIView tap.
 NSString *bundle=DF143Bundle(iconView,0);
 if(DFHome140Enabled())DF143Log([NSString stringWithFormat:@"home-callback class=%@ bundle=%@ view=%d",NSStringFromClass([iconView class]),bundle?:@"unresolved",[iconView isKindOfClass:UIView.class]]);
 if(!DF143Chosen(bundle) || ![iconView isKindOfClass:UIView.class]) {
    DF143Original(owner,selector,manager,iconView);
    return;
 }
 id duofaceView=DF143NativeHostIcon(iconView);
 if(!duofaceView || duofaceView==iconView) {
    DF143Log([NSString stringWithFormat:
        @"selected-foreign-app bundle=%@ host-icon-not-visible original-forwarded",
        bundle]);
    DF143Original(owner,selector,manager,iconView);
    return;
 }
 // The selected icon and the original DuoFace icon are BOTH genuine UIViews
 // provided by the same native CarPlay Home, never constructed synthetic icons.
 NSString *id143=NSUUID.UUID.UUIDString;
 NSDictionary *request=@{@"Version":@1,@"ID":id143,@"Sequence":@(++DF143Sequence),
             @"BundleID":bundle,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
             @"HostBundleID":DF143HostID,@"Origin":@"CarPlayHomeTap143"};
 if(![request writeToFile:DF143Path atomically:YES]) {
    DF143Log([NSString stringWithFormat:@"request-write-failed bundle=%@ original-forwarded",bundle]);
    DF143Original(owner,selector,manager,iconView);
    return;
 }
 DF143Log([NSString stringWithFormat:@"selected-tap-redirect-to-existing-duoface-icon bundle=%@ hostClass=%@ targetClass=%@",
      bundle,NSStringFromClass([duofaceView class]),NSStringFromClass([iconView class])]);
 // The real Home controller follows the original native app launch route.
 // Native/unselected callbacks were forwarded untouched above.
 DF143Original(owner,selector,manager,duofaceView);
}
static void DF143Install(NSUInteger tries) {
 if(DF143Original || tries>15)return;
 Class home=objc_getClass("DBDashboardHomeViewController");
 SEL action=sel_registerName("iconManager:launchIconForIconView:");
 Method m=home?class_getInstanceMethod(home,action):NULL;
 DF143Hook hook=(DF143Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(hook && m && method_getTypeEncoding(m) &&
    !strcmp(method_getTypeEncoding(m),"v32@0:8@16@24")) {
     hook(home,action,(IMP)DF143Launch,(IMP *)&DF143Original);
     DF143Log([NSString stringWithFormat:@"hook-installed=%d exact=v32@0:8@16@24",
              DF143Original!=NULL]);
 }else if(tries==0) {
     DF143Log([NSString stringWithFormat:@"hook-not-ready class=%d type=%s provider=%d",
          home!=Nil,m?method_getTypeEncoding(m):"absent",hook!=NULL]);
 }
 if(!DF143Original && tries<15)
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),
                  dispatch_get_main_queue(),^{DF143Install(tries+1);});
}
__attribute__((constructor)) static void DF143Init(void) {
 if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16 ||
    ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
 dispatch_async(dispatch_get_main_queue(),^{DF143Install(0);});
}
