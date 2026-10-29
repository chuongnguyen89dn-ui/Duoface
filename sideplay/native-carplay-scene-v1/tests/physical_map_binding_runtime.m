// Foundation/CoreGraphics source-only contract for cross-process CarPlay maps pane.
// No device, private API, process mutation or real plist files used.
#import <Foundation/Foundation.h>
#import "DFCarPlayPhysicalPaneBinding.h"
static void yes(BOOL cond,NSString *why){if(!cond){NSLog(@"PHYSICAL_MAP_FAIL %@",why);abort();}}
static NSDictionary *window(NSInteger p,NSInteger v,NSString *frame,BOOL occupied){
 return @{@"PhysicalSlot":@(p),@"VisualSlot":@(v),@"Frame":frame,
          @"WindowVisible":@YES,@"OnExternalScreen":@YES,@"HasLiveApp":@(occupied)};
}
int main(void){@autoreleasepool{
 NSString *uuid=NSUUID.UUID.UUIDString;
 double now=1700000000.0;
 NSDictionary *heartbeat=@{@"Session":uuid,@"Active":@YES,@"Timestamp":@(now)};
 NSDictionary *plan=@{@"status":@"measured-carplay-content-split-plan",
   @"dockMeasured":@YES,
   @"usableRect":@{@"x":@45,@"y":@0,@"width":@462,@"height":@240},
   @"visualSlot0":@{@"x":@45,@"y":@0,@"width":@231,@"height":@240},
   @"visualSlot1":@{@"x":@276,@"y":@0,@"width":@231,@"height":@240}};
 NSDictionary *(^sample)(NSArray *)=^NSDictionary *(NSArray *windows){
   return @{@"Version":@1,@"Owner":@"SpringBoard",@"Session":uuid,
     @"Timestamp":@(now),@"ActiveSlots":@2,@"Focus":@(-1),@"Windows":windows};
 };
 NSArray *windows=@[window(0,0,@"{{45, 0}, {231, 240}}",NO),
                     window(1,1,@"{{276, 0}, {231, 240}}",YES)];
 NSDictionary *ok=DFPhysicalMapVerifyPane(sample(windows),heartbeat,plan,0,now+.5);
 yes([ok[@"Verified"] isEqual:@YES],@"measured empty DuoFace pane accepted");
 yes(CGRectEqualToRect(CGRectFromString(ok[@"Target"]),CGRectMake(45,0,231,240)),
     @"physical target selected not arbitrary scale");
 NSDictionary *occupied=DFPhysicalMapVerifyPane(sample(windows),heartbeat,plan,1,now+.5);
 yes([occupied[@"Reason"] isEqual:@"target-duoface-slot-already-hosts-app"],
     @"cannot hide live YouTube/Maps slot");
 NSArray *mismatched=@[window(0,0,@"{{40, 0}, {231, 240}}",NO),
                      windows[1]];
 NSDictionary *m=DFPhysicalMapVerifyPane(sample(mismatched),heartbeat,plan,0,now+.5);
 yes(![m[@"Verified"] boolValue],@"native dock and physical window must agree");
 yes(![DFPhysicalMapVerifyPane(sample(windows),heartbeat,plan,0,now+3)[@"Verified"] boolValue],
      @"stale scene observation rejected");
 NSDictionary *otherPulse=@{@"Session":NSUUID.UUID.UUIDString,
                            @"Active":@YES,@"Timestamp":@(now)};
 yes(![DFPhysicalMapVerifyPane(sample(windows),otherPulse,plan,0,now)[@"Verified"] boolValue],
     @"cross-session receipt rejected");
 NSArray *duplicate=@[window(0,0,@"{{45, 0}, {231, 240}}",NO),
                      window(1,0,@"{{276, 0}, {231, 240}}",NO)];
 yes(![DFPhysicalMapVerifyPane(sample(duplicate),heartbeat,plan,0,now)[@"Verified"] boolValue],
      @"duplicate physical visual mapping rejected");
 NSMutableDictionary *disabled=[heartbeat mutableCopy];disabled[@"Active"]=@NO;
 yes(![DFPhysicalMapVerifyPane(sample(windows),disabled,plan,0,now)[@"Verified"] boolValue],
      @"disconnected CarPlay rejected");
 NSLog(@"DF_PHYSICAL_MAP_BINDING_RUNTIME_PASS");
}return 0;}
