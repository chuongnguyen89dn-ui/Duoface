// Separate diagnostic: no Logos hooks, no app admission or scene mutation.
#import <Foundation/Foundation.h>
extern void DFNativeSceneProbeStart(void);
%ctor {
 @autoreleasepool {
    NSString *p=NSProcessInfo.processInfo.processName;
    if(![p isEqual:@"CarPlay"] && ![p isEqual:@"CarPlayApp"])return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,10*NSEC_PER_SEC),
                   dispatch_get_main_queue(),^{DFNativeSceneProbeStart();});
 }
}
