// QA136: non-invasive discovery of the ACTUAL in-process CarPlay Home
// application library. Never create a replacement instance or patch OS classes.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import <stdlib.h>
#import "DFHomePublisher136Config.h"
#import "DFEnabledAppsPolicy.h"
extern NSInteger DFHome136ReconcileVerifiedLibrary(id library);
static NSString *const DFHome136LogPath=
 @"/var/mobile/Library/Logs/DuoFaceHomePublisher136.log";
static NSUInteger sAttempts=0;
static int sHomeToken=-1,sAppsToken=-1;
static void DFHome136Log(NSString *s) {
 NSString *line=[NSString stringWithFormat:@"[DFHome136] pid=%d %@\n",getpid(),s?:@""];
 NSLog(@"%@",line);
 int fd=open(DFHome136LogPath.fileSystemRepresentation,O_CREAT|O_APPEND|O_WRONLY,0644);
 if(fd<0)return;
 NSData *d=[line dataUsingEncoding:NSUTF8StringEncoding];
 if(d.length)(void)write(fd,d.bytes,d.length);
 close(fd);
}
static id DFHome136GetLibrary(id source) {
 if(!source)return nil;
 Class library=objc_getClass("FBSApplicationLibrary");
 if(library && [source isKindOfClass:library])return source;
 for(NSString *method in @[@"applicationLibrary",@"_applicationLibrary",
                           @"appLibrary",@"_appLibrary"]) {
   SEL selector=NSSelectorFromString(method);
   Method m=class_getInstanceMethod(object_getClass(source),selector);
   if(!m || !method_getTypeEncoding(m) ||
      strcmp(method_getTypeEncoding(m),"@16@0:8")!=0)continue;
   @try {
      id value=((id(*)(id,SEL))objc_msgSend)(source,selector);
      if(library && [value isKindOfClass:library])return value;
   } @catch(__unused NSException *e) {continue;}
 }
 // When no verified getter exists, inspect object-typed own ivars only.
 // This does not change UIKit/CarPlay state or allocate an FBS library.
 for(Class cursor=object_getClass(source);cursor;cursor=class_getSuperclass(cursor)) {
   unsigned int count=0;
   Ivar *ivars=class_copyIvarList(cursor,&count);
   if(!ivars)continue;
   for(unsigned int n=0;n<count;n++) {
      const char *kind=ivar_getTypeEncoding(ivars[n]);
      const char *name=ivar_getName(ivars[n]);
      if(!kind || kind[0]!='@' || !name)continue;
      NSString *key=[NSString stringWithUTF8String:name];
      if(![key.localizedLowercaseString containsString:@"library"])continue;
      @try {
        id value=object_getIvar(source,ivars[n]);
        if(library && [value isKindOfClass:library]){
          free(ivars);
          return value;
        }
      } @catch(__unused NSException *ex) {}
   }
   free(ivars);
 }
 return nil;
}
static id DFHome136Walk(UIViewController *root,NSUInteger depth) {
 if(!root || depth>5)return nil;
 id lib=DFHome136GetLibrary(root);
 if(lib)return lib;
 if(root.presentedViewController) {
    lib=DFHome136Walk(root.presentedViewController,depth+1);
    if(lib)return lib;
 }
 for(UIViewController *child in root.childViewControllers) {
    lib=DFHome136Walk(child,depth+1);
    if(lib)return lib;
 }
 return nil;
}
static void DFHome136Search(NSString *reason) {
 if(!DFHome136Enabled())return;
 UIApplication *app=UIApplication.sharedApplication;
 id lib=DFHome136GetLibrary(app);
 if(!lib)lib=DFHome136GetLibrary(app.delegate);
 for(UIWindow *window in app.windows) {
    if(lib)break;
    lib=DFHome136GetLibrary(window);
    if(!lib)lib=DFHome136Walk(window.rootViewController,0);
 }
 if(lib) {
    NSInteger added=DFHome136ReconcileVerifiedLibrary(lib);
    DFHome136Log([NSString stringWithFormat:
       @"verified-library=%@ reconcile=%ld reason=%@",
       NSStringFromClass([lib class]),(long)added,reason]);
 } else DFHome136Log([NSString stringWithFormat:
       @"native-FBS-library-instance-not-exposed reason=%@; no mutation",
       reason]);
}
static void DFHome136Retry(NSUInteger generation,NSUInteger attempt) {
 if(generation!=sAttempts || !DFHome136Enabled() || attempt>6)return;
 DFHome136Search(@"live-system-home-lookup");
 if(generation!=sAttempts || attempt>=6)return;
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC),
                dispatch_get_main_queue(),^{DFHome136Retry(generation,attempt+1);});
}
static void DFHome136Refresh(NSString *reason) {
 if(![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(),^{DFHome136Refresh(reason);});return;
 }
 ++sAttempts;
 if(!DFHome136Enabled()){
    DFHome136Log(@"user Home switch OFF or kill switch; no mutation");
    return;
 }
 DFHome136Search(reason);
 DFHome136Retry(sAttempts,1);
}
__attribute__((constructor)) static void DFHome136Start(void) {
 @autoreleasepool {
  NSOperatingSystemVersion os=NSProcessInfo.processInfo.operatingSystemVersion;
  if(os.majorVersion!=16 ||
     ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
  dispatch_async(dispatch_get_main_queue(),^{
    int a=notify_register_dispatch(DFHome136Changed,&sHomeToken,
              dispatch_get_main_queue(),^(__unused int token){
                DFHome136Refresh(@"user-Home-toggle");
              });
    int b=notify_register_dispatch(DFEnabledAppsChangedNotification,&sAppsToken,
              dispatch_get_main_queue(),^(__unused int token){
                DFHome136Refresh(@"selected-apps-updated");
              });
    DFHome136Log([NSString stringWithFormat:
      @"started no-hook no-new-library notify home=%d enabled=%d",a,b]);
    DFHome136Refresh(@"CarPlay-start");
  });
 }
}
