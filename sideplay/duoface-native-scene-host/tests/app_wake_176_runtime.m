#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <unistd.h>
static NSDictionary *snapshot,*pulse;
static NSUInteger wakes;
static NSTimeInterval DF177TouchLastSentAt;
static BOOL DF177AppTouchEnabled(void){return YES;}
static void DF177AppTouchNoteBegan(NSString *bundle){(void)bundle;wakes++;}
static NSDictionary *readRecord(NSString *path){return [path containsString:@"wake-state"]?snapshot:pulse;}
#define DF176_WAKE_READ_RECORD(path) readRecord(path)
#define DF177_APP_SIDE_SENDER 1
#import "../DFAppWakeGate176.h"
static void check(BOOL ok){if(!ok)abort();}
static UIEvent *event(UITouch *touch,UITouchPhase phase){
 touch.phase=phase;UIEvent *e=[UIEvent new];e.type=UIEventTypeTouches;e.allTouches=[NSSet setWithObject:touch];return e;
}
static void state(BOOL hidden,BOOL validPID){
 double now=NSDate.date.timeIntervalSince1970;
 pulse=@{@"Version":@1,@"Active":@YES,@"Session":@"01234567-89AB-CDEF-0123-456789ABCDEF",@"Timestamp":@(now)};
 snapshot=@{@"Version":@1,@"Session":pulse[@"Session"],@"Eligible":@YES,
 @"Processes":@{@"test.app":@(validPID?getpid():getpid()+1)},
 @"Until":@(now+(hidden?-1:10)),@"Timestamp":@(now)};
}
int main(void){@autoreleasepool{
 UITouch *t=[UITouch new];state(YES,NO);
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseBegan),@"test.app"));
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseEnded),@"test.app"));
 state(YES,YES);
 NSMutableDictionary *bad=[snapshot mutableCopy];bad[@"Timestamp"]=@(NSDate.date.timeIntervalSince1970-2);snapshot=bad;
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseBegan),@"test.app"));
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseEnded),@"test.app"));
 state(YES,YES);bad=[snapshot mutableCopy];bad[@"Session"]=NSUUID.UUID.UUIDString;snapshot=bad;
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseBegan),@"test.app"));
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseEnded),@"test.app"));
 state(NO,YES);
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseBegan),@"test.app"));
 state(YES,YES);
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseMoved),@"test.app"));
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseEnded),@"test.app"));
 check(DF176ConsumeWakeEvent(event(t,UITouchPhaseBegan),@"test.app"));check(wakes==1);
 UITouch *second=[UITouch new];second.phase=UITouchPhaseBegan;t.phase=UITouchPhaseStationary;
 UIEvent *multi=[UIEvent new];multi.type=UIEventTypeTouches;multi.allTouches=[NSSet setWithObjects:t,second,nil];
 check(DF176ConsumeWakeEvent(multi,@"test.app"));check(wakes==1);
 check(DF176ConsumeWakeEvent(event(second,UITouchPhaseEnded),@"test.app"));
 state(NO,YES);
 check(DF176ConsumeWakeEvent(event(t,UITouchPhaseMoved),@"test.app"));
 check(DF176ConsumeWakeEvent(event(t,UITouchPhaseCancelled),@"test.app"));
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseBegan),@"test.app"));
 check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseEnded),@"test.app"));
 check(wakes==1);NSLog(@"QA176_APP_DELIVERY_GATE_MODEL_PASS");
 return 0;
}}
