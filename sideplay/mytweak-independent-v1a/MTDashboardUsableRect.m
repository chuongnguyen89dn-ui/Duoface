#import "MTDashboardUsableRect.h"
#import <math.h>
static BOOL MTFiniteNumber(id n) {
    return [n isKindOfClass:NSNumber.class] && isfinite([n doubleValue]);
}
BOOL MTDashboardUsableRect(CGRect full,NSDictionary *record,CGRect *out) {
    if (![record isKindOfClass:NSDictionary.class] ||
        CGRectIsEmpty(full) || full.size.width<240 || full.size.height<100)
        return NO;
    if (![record[@"Producer"] isEqual:@"CarPlay"] ||
        ![record[@"Kind"] isEqual:@"CarPlayRootWindowSafeArea"] ||
        ![record[@"UsableValid"] isEqual:@YES] ||
        ![record[@"HasNonzeroInsets"] isEqual:@YES])
        return NO;
    for (NSString *k in @[@"X",@"Y",@"Width",@"Height",@"Timestamp",@"DisplayAspect"])
        if (!MTFiniteNumber(record[k]))return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-
                        [record[@"Timestamp"] doubleValue];
    if (age<0 || age>5.0)return NO;
    CGFloat aspect=[record[@"DisplayAspect"] doubleValue];
    if (aspect<0.3 || fabs(full.size.width/full.size.height/aspect-1.0)>0.15)
        return NO;
    CGFloat x=[record[@"X"] doubleValue], y=[record[@"Y"] doubleValue];
    CGFloat w=[record[@"Width"] doubleValue], h=[record[@"Height"] doubleValue];
    if (x<-0.005 || y<-0.005 || w<0.5 || h<0.5 ||
        x+w>1.005 || y+h>1.005)return NO;
    // This is a verified native *usable region*, not a proof of AppDock visible.
    CGRect usable=CGRectMake(full.origin.x+full.size.width*x,
                             full.origin.y+full.size.height*y,
                             full.size.width*w,full.size.height*h);
    if (!isfinite(usable.origin.x) || !isfinite(usable.origin.y) ||
        !isfinite(usable.size.width) || !isfinite(usable.size.height))
        return NO;
    if (out)*out=usable;
    return YES;
}
