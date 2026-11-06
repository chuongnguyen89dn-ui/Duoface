// First-party pre-dispatch proof. The existing native coordinator remains final owner.
#ifndef DF_MAP_REPLACE_180_H
#define DF_MAP_REPLACE_180_H
#import <Foundation/Foundation.h>
#import "DFNativeMapLeasePolicy.h"
NS_INLINE BOOL DF180EmptyPaneReadbackReady(id sample,id pulse,NSString *session,
    NSInteger visual,NSInteger physical,NSTimeInterval releasedAt,NSTimeInterval now) {
    if(![sample isKindOfClass:NSDictionary.class] ||
       ![pulse isKindOfClass:NSDictionary.class] ||
       ![session isKindOfClass:NSString.class] || ![[NSUUID alloc]initWithUUIDString:session] ||
       !isfinite(releasedAt) || !isfinite(now) || now<releasedAt ||
       visual<0 || visual>1 || physical<0 || physical>1 ||
       ![sample[@"Version"] isEqual:@1] || ![sample[@"Owner"] isEqual:@"SpringBoard"] ||
       ![sample[@"Session"] isEqual:session] || ![pulse[@"Session"] isEqual:session] ||
       ![pulse[@"Active"] isEqual:@YES] || ![sample[@"ActiveSlots"] isEqual:@2] ||
       ![sample[@"Focus"] isEqual:@(-1)] ||
       ![sample[@"Timestamp"] isKindOfClass:NSNumber.class] ||
       ![pulse[@"Timestamp"] isKindOfClass:NSNumber.class])return NO;
    double stamp=[sample[@"Timestamp"] doubleValue],beat=[pulse[@"Timestamp"] doubleValue];
    if(!isfinite(stamp) || stamp<releasedAt || stamp>now || now-stamp>1.5 ||
       !isfinite(beat) || beat>now || now-beat>2.5)return NO;
    NSArray *windows=sample[@"Windows"];
    if(![windows isKindOfClass:NSArray.class] || windows.count!=2)return NO;
    NSMutableSet *vs=[NSMutableSet new],*ps=[NSMutableSet new];BOOL found=NO;
    for(id window in windows) {
        if(![window isKindOfClass:NSDictionary.class] ||
           !DFNativeMapValidSlotValue(window[@"VisualSlot"]) ||
           !DFNativeMapValidSlotValue(window[@"PhysicalSlot"]) ||
           ![window[@"WindowVisible"] isEqual:@YES] ||
           ![window[@"OnExternalScreen"] isEqual:@YES] ||
           ![window[@"HasLiveApp"] isKindOfClass:NSNumber.class] ||
           [vs containsObject:window[@"VisualSlot"]] || [ps containsObject:window[@"PhysicalSlot"]])return NO;
        [vs addObject:window[@"VisualSlot"]];[ps addObject:window[@"PhysicalSlot"]];
        if([window[@"VisualSlot"] integerValue]==visual) {
            found=[window[@"PhysicalSlot"] integerValue]==physical &&
                  ![window[@"HasLiveApp"] boolValue];
        }
    }
    return found;
}
#endif
