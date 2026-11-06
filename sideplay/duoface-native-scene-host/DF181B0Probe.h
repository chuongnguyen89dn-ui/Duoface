// QA181 b0probe1: scalar-only, bounded observation; never changes scene state.
#import "DFDeepTrace.h"
#import <UIKit/UIKit.h>
static inline BOOL DF181B0InScope(NSString *bundle, BOOL nativeCarPlay) {
    return nativeCarPlay || [bundle isEqualToString:@"native-carplay"] ||
           [bundle isEqualToString:@"com.google.Maps"] ||
           [bundle isEqualToString:@"com.waze.iphone"];
}
static inline void DF181B0Record(NSString *path, NSString *bundle,
                                 NSString *event, NSString *sceneID,
                                 NSString *owner, NSString *size,
                                 NSString *display, NSString *detail) {
    if(!DF181B0InScope(bundle, [path isEqualToString:@"stock"]))return;
    @try {
        static NSMutableDictionary<NSString *, NSNumber *> *last;
        static dispatch_once_t once;
        dispatch_once(&once, ^{ last=[NSMutableDictionary new]; });
        NSString *key=[NSString stringWithFormat:@"%@|%@|%@|%@|%@",
                      path?:@"unknown",bundle?:@"unknown",event?:@"unknown",
                      sceneID?:@"unknown",owner?:@"unknown"];
        NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
        @synchronized(last) {
            NSNumber *previous=last[key];
            if(previous && now-previous.doubleValue<1.5)return;
            if(last.count>96)[last removeAllObjects];
            last[key]=@(now);
        }
        NSString *safeDetail=detail.length>256?[detail substringToIndex:256]:detail;
        DFDeepTrace(@"qa181-b0",[NSString stringWithFormat:
            @"qa181-b0 path=%@ bundle=%@ event=%@ sceneID=%@ owner=%@ size=%@ display=%@ detail=%@",
            path?:@"unknown",bundle?:@"unknown",event?:@"unknown",
            sceneID?:@"unknown",owner?:@"unknown",size?:@"unknown",
            display?:@"unknown",safeDetail?:@"-"]);
    } @catch(NSException *ignored) {(void)ignored;}
}
