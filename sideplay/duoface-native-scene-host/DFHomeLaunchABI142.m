// QA142 current CarPlay Home ABI measurement. Read-only, no runtime replacement.
// The signed build must report exact available methods before any launch change.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import <stdlib.h>

static void DF142Record(NSString *line) {
  NSString *full=[NSString stringWithFormat:@"[DFHome142] %@\n",line];
  NSData *data=[full dataUsingEncoding:NSUTF8StringEncoding];
  int fd=open("/var/mobile/Library/Logs/DuoFaceHomeLaunch142.log",
              O_CREAT|O_WRONLY|O_APPEND,0644);
  if(fd>=0){ if(data.length)(void)write(fd,data.bytes,data.length);close(fd); }
}
static void DF142Method(const char *cls, const char *sel, BOOL meta) {
  Class klass=objc_getClass(cls);
  Method m=meta?class_getClassMethod(klass,sel_registerName(sel)):
                class_getInstanceMethod(klass,sel_registerName(sel));
  DF142Record([NSString stringWithFormat:@"method=%c[%s %s] types=%s",
        meta?'+':'-',cls,sel,m?method_getTypeEncoding(m):"absent"]);
}
@interface DFHomeLaunch142 : NSObject
+ (void)sample;
@end
@implementation DFHomeLaunch142
+ (void)sample {
  DF142Method("DBDashboardHomeViewController","iconManager:launchIcon:",NO);
  DF142Method("DBDashboardHomeViewController","iconManager:launchIconForIconView:",NO);
  DF142Method("DBWorkspace","initWithOwner:",NO);
  DF142Method("DBWorkspace","requestStateChange:",NO);
  DF142Method("DBWorkspace","state",NO);
  DF142Method("DBDashboardWorkspaceOwner","init",NO);
  DF142Method("DBApplicationController","sharedInstance",YES);
  DF142Method("DBApplicationController","applicationWithBundleIdentifier:",NO);
  DF142Method("DBMutableWorkspaceStateChangeRequest","activateApplication:",NO);
  DF142Method("DBWorkspaceState","activeBundleIdentifier",NO);

  // Discover renamed iOS16 Dashboard selectors by their actual own methods.
  // A present literal alone is not proof of a runnable class or correct ABI.
  int capacity=objc_getClassList(NULL,0);
  if(capacity>0 && capacity<20000) {
    Class __unsafe_unretained *classes=(Class __unsafe_unretained *)calloc((size_t)capacity,sizeof(Class));
    if(classes) {
      int n=objc_getClassList(classes,capacity);
      unsigned count=0;
      for(int i=0;i<n && count<48;i++) {
        const char *cname=class_getName(classes[i]);
        if(!cname || strncmp(cname,"DB",2))continue;
        NSString *className=[NSString stringWithUTF8String:cname];
        if([className rangeOfString:@"Home"].location==NSNotFound &&
           [className rangeOfString:@"Icon"].location==NSNotFound &&
           [className rangeOfString:@"Workspace"].location==NSNotFound)continue;
        unsigned int total=0;
        Method *methods=class_copyMethodList(classes[i],&total);
        for(unsigned int k=0;k<total && count<48;k++) {
          const char *selector=sel_getName(method_getName(methods[k]));
          if(!selector || (!strstr(selector,"launchIcon") &&
             !strstr(selector,"activateApplication") &&
             !strstr(selector,"requestStateChange")))continue;
          DF142Record([NSString stringWithFormat:@"candidate=%s selector=%s types=%s",
             cname,selector,method_getTypeEncoding(methods[k])]);
          count++;
        }
        free(methods);
      }
      free(classes);
      DF142Record([NSString stringWithFormat:@"candidate-count=%u",count]);
    }
  }
  DF142Record(@"read-only-abi-report-complete no-launch-mutation");
}
@end
__attribute__((constructor)) static void DF142Init(void) {
  if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16 ||
     ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
  [DFHomeLaunch142 performSelectorOnMainThread:@selector(sample)
                                     withObject:nil waitUntilDone:NO];
}
