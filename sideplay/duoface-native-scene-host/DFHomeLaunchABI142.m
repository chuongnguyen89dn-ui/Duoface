// QA142 current CarPlay Home ABI measurement. Read-only, no runtime replacement.
// The signed build must report exact available methods before any launch change.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>

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
  DF142Record(@"read-only-abi-report-complete no-launch-mutation");
}
@end
__attribute__((constructor)) static void DF142Init(void) {
  if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16 ||
     ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
  [DFHomeLaunch142 performSelectorOnMainThread:@selector(sample)
                                     withObject:nil waitUntilDone:NO];
}
