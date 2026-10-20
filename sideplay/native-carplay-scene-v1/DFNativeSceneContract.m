#import "DFNativeSceneContract.h"
#import <math.h>
NSString *const DFNativeSceneOwnerRecordPath = @"/var/mobile/Library/Preferences/com.duoface.native-scene-owner.v1.plist";
static BOOL DFFiniteRect(CGRect r) {
    return isfinite(r.origin.x) && isfinite(r.origin.y) &&
           isfinite(r.size.width) && isfinite(r.size.height) &&
           r.size.width > 0 && r.size.height > 0;
}
BOOL DFNativeSceneUsable(CGRect full, CGFloat t, CGFloat l, CGFloat b, CGFloat r,
                         CGRect *usable) {
    if(!DFFiniteRect(full) || !isfinite(t) || !isfinite(l) ||
       !isfinite(b) || !isfinite(r) || t<0 || l<0 || b<0 || r<0)return NO;
    CGRect u=CGRectMake(full.origin.x+l,full.origin.y+t,
                       full.size.width-l-r,full.size.height-t-b);
    if(!DFFiniteRect(u) || u.size.width<100 || u.size.height<60 ||
       !CGRectContainsRect(full,u))return NO;
    if(usable)*usable=u;
    return YES;
}
BOOL DFNativeSceneSplit(CGRect usable,CGFloat ratio,CGFloat divider,
                        CGRect *first,CGRect *second) {
    if(!DFFiniteRect(usable) || !isfinite(ratio) || !isfinite(divider) ||
       ratio<0.10 || ratio>0.90 || divider<0 || divider>30 ||
       usable.size.width-divider<140)return NO;
    CGFloat available=usable.size.width-divider;
    CGFloat left=round(available*ratio);
    CGRect a=CGRectMake(usable.origin.x,usable.origin.y,left,usable.size.height);
    CGRect b=CGRectMake(CGRectGetMaxX(a)+divider,usable.origin.y,
                       available-left,usable.size.height);
    if(!DFFiniteRect(a) || !DFFiniteRect(b) ||
       !CGRectContainsRect(usable,a) || !CGRectContainsRect(usable,b))return NO;
    if(first)*first=a;if(second)*second=b;
    return YES;
}
static BOOL DFNum(id v) { return [v isKindOfClass:NSNumber.class] && isfinite([v doubleValue]); }
NSDictionary *DFNativeSceneOwnerRecord(NSString *session,CGRect full,CGRect usable,
                                      BOOL nativeChromeVisible,NSTimeInterval now) {
    if(![[NSUUID alloc] initWithUUIDString:session] ||
       !isfinite(now) || now<=0 || !DFFiniteRect(full) || !DFFiniteRect(usable) ||
       !CGRectContainsRect(full,usable))return nil;
    return @{@"Version":@1,@"Kind":@"native-dash-readonly",@"Session":session,
             @"Timestamp":@(now),@"ChromeObserved":@(nativeChromeVisible),
             @"FullX":@(full.origin.x),@"FullY":@(full.origin.y),
             @"FullW":@(full.size.width),@"FullH":@(full.size.height),
             @"UsableX":@(usable.origin.x),@"UsableY":@(usable.origin.y),
             @"UsableW":@(usable.size.width),@"UsableH":@(usable.size.height)};
}
BOOL DFNativeSceneValidateOwnerRecord(NSDictionary *record,NSString *session,
                                       NSTimeInterval now) {
    if(![record isKindOfClass:NSDictionary.class] ||
       ![record[@"Version"] isEqual:@1] ||
       ![record[@"Kind"] isEqual:@"native-dash-readonly"] ||
       ![record[@"Session"] isKindOfClass:NSString.class] ||
       ![[NSUUID alloc] initWithUUIDString:record[@"Session"]] ||
       (session && ![record[@"Session"] isEqual:session]) ||
       !DFNum(record[@"Timestamp"]) || !isfinite(now))return NO;
    NSTimeInterval age=now-[record[@"Timestamp"] doubleValue];
    if(age<0 || age>3.0)return NO;
    for(NSString *key in @[@"FullX",@"FullY",@"FullW",@"FullH",
                            @"UsableX",@"UsableY",@"UsableW",@"UsableH", @"ChromeObserved"])
        if(!DFNum(record[key]))return NO;
    CGRect f=CGRectMake([record[@"FullX"] doubleValue],[record[@"FullY"] doubleValue],
                        [record[@"FullW"] doubleValue],[record[@"FullH"] doubleValue]);
    CGRect u=CGRectMake([record[@"UsableX"] doubleValue],[record[@"UsableY"] doubleValue],
                        [record[@"UsableW"] doubleValue],[record[@"UsableH"] doubleValue]);
    return DFFiniteRect(f) && DFFiniteRect(u) &&
           u.size.width>=100 && u.size.height>=60 && CGRectContainsRect(f,u);
}
