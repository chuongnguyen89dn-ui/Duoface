// First-party cross-process physical CarPlay pane readback. No vendor code.
// Pure Foundation/CoreGraphics: PASS only on two independent live owners.
#ifndef DF_CARPLAY_PHYSICAL_PANE_BINDING_H
#define DF_CARPLAY_PHYSICAL_PANE_BINDING_H
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
static inline BOOL DFPhysicalMapValidRect(NSString *string,CGRect *out) {
 if(![string isKindOfClass:NSString.class] || string.length>200)return NO;
 CGRect r=CGRectFromString(string);
 if(CGRectIsNull(r)||CGRectIsInfinite(r)|| !isfinite(r.origin.x) ||
    !isfinite(r.origin.y)||!isfinite(r.size.width)||!isfinite(r.size.height)||
    r.size.width<90||r.size.height<120)return NO;
 if(out)*out=r;
 return YES;
}
static inline BOOL DFPhysicalMapNearRect(CGRect a,CGRect b,CGFloat delta) {
 return fabs(a.origin.x-b.origin.x)<=delta &&
        fabs(a.origin.y-b.origin.y)<=delta &&
        fabs(a.size.width-b.size.width)<=delta &&
        fabs(a.size.height-b.size.height)<=delta;
}
static inline NSDictionary *DFPhysicalMapVerifyPane(
 NSDictionary *sample,NSDictionary *heartbeat,NSDictionary *dockPlan,
 NSInteger desiredSlot,NSTimeInterval now) {
 NSDictionary *fail=@{@"Verified":@NO,@"Reason":@"physical-duoface-slot-not-verified"};
 if(![sample isKindOfClass:NSDictionary.class] ||
    ![heartbeat isKindOfClass:NSDictionary.class] ||
    ![dockPlan isKindOfClass:NSDictionary.class] ||
    !isfinite(now))return fail;
 if(![sample[@"Version"] isEqual:@1] ||
    ![sample[@"Owner"] isEqual:@"SpringBoard"] ||
    ![sample[@"Session"] isKindOfClass:NSString.class] ||
    ![[NSUUID alloc]initWithUUIDString:sample[@"Session"]] ||
    ![sample[@"Session"] isEqual:heartbeat[@"Session"]] ||
    ![heartbeat[@"Active"] isEqual:@YES] ||
    ![sample[@"Timestamp"] isKindOfClass:NSNumber.class] ||
    ![heartbeat[@"Timestamp"] isKindOfClass:NSNumber.class] ||
    ![sample[@"ActiveSlots"] isEqual:@2] ||
    ![sample[@"Focus"] isEqual:@(-1)] ||
    ![dockPlan[@"status"] isEqual:@"measured-carplay-content-split-plan"] ||
    ![dockPlan[@"dockMeasured"] isEqual:@YES] ||
    desiredSlot<0 || desiredSlot>1)return fail;
 double age=now-[sample[@"Timestamp"] doubleValue];
 double pulse=now-[heartbeat[@"Timestamp"] doubleValue];
 if(!isfinite(age)||age<0||age>1.75||!isfinite(pulse)||pulse<0||pulse>2.5)
   return @{ @"Verified":@NO,@"Reason":@"stale-physical-slot-or-session" };
 NSArray *windows=sample[@"Windows"];
 if(![windows isKindOfClass:NSArray.class] || windows.count!=2)return fail;
 NSMutableSet *seen=[NSMutableSet new];
 CGRect rects[2];
 for(id entry in windows) {
    if(![entry isKindOfClass:NSDictionary.class] ||
       ![entry[@"VisualSlot"] isKindOfClass:NSNumber.class] ||
       ![entry[@"PhysicalSlot"] isKindOfClass:NSNumber.class] ||
       ![entry[@"OnExternalScreen"] isEqual:@YES] ||
       ![entry[@"WindowVisible"] isEqual:@YES])return fail;
    NSInteger v=[entry[@"VisualSlot"] integerValue];
    NSInteger physical=[entry[@"PhysicalSlot"] integerValue];
    if(v<0||v>1||physical<0||physical>1||[seen containsObject:@(v)] ||
       ![entry[@"HasLiveApp"] isKindOfClass:NSNumber.class] ||
       !DFPhysicalMapValidRect(entry[@"Frame"],&rects[v]))return fail;
    if(v==desiredSlot && [entry[@"HasLiveApp"] boolValue])
       return @{@"Verified":@NO,@"Reason":@"target-duoface-slot-already-hosts-app"};
    [seen addObject:@(v)];
 }
 if(seen.count!=2)return fail;
 NSDictionary *usable=dockPlan[@"usableRect"];
 CGRect safe=CGRectMake([usable[@"x"] doubleValue],[usable[@"y"] doubleValue],
             [usable[@"width"] doubleValue],[usable[@"height"] doubleValue]);
 if(!CGRectContainsRect(safe,rects[0]) || !CGRectContainsRect(safe,rects[1]))
    return fail;
 for(NSInteger slot=0;slot<2;slot++) {
   NSDictionary *planned=dockPlan[slot==0?@"visualSlot0":@"visualSlot1"];
   CGRect target=CGRectMake([planned[@"x"] doubleValue],[planned[@"y"] doubleValue],
               [planned[@"width"] doubleValue],[planned[@"height"] doubleValue]);
   if(!DFPhysicalMapNearRect(rects[slot],target,2.0))
       return @{ @"Verified":@NO,@"Reason":@"native-dock-and-duoface-physical-geometry-disagree" };
 }
 return @{@"Verified":@YES,@"Reason":@"two-owners-measured-same-screen-pane",
          @"Target":NSStringFromCGRect(rects[desiredSlot]),
          @"VisualSlot":@(desiredSlot),@"Session":sample[@"Session"]};
}
#endif
