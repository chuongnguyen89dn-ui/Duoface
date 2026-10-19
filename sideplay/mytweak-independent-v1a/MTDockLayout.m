#import "MTDockLayout.h"
#import <math.h>
NSString *MTDockRecordPath(void) {
    return @"/var/mobile/Library/Preferences/com.duoface.mytweak.native-dock.plist";
}
static BOOL MTNumber(id n) {
    if (![n isKindOfClass:NSNumber.class]) return NO;
    return isfinite([n doubleValue]);
}
BOOL MTDockContentRect(CGRect full,NSDictionary *record,CGRect *out) {
    if (![record isKindOfClass:NSDictionary.class] || CGRectIsEmpty(full) ||
        full.size.width<240 || full.size.height<100) return NO;
    if (![record[@"Producer"] isEqual:@"CarPlay"] ||
        ![record[@"Kind"] isEqual:@"real-DBDockWindow"] ||
        ![record[@"Visible"] isEqual:@YES]) return NO;
    for (NSString *k in @[@"X",@"Y",@"Width",@"Height",@"Timestamp",@"DisplayAspect"])
        if (!MTNumber(record[k])) return NO;
    // Ignore old geometry from a previous CarPlay session or an absent Dock.
    NSTimeInterval age=[NSDate.date timeIntervalSince1970]-[record[@"Timestamp"] doubleValue];
    if (age<0 || age>9.0)return NO;
    CGFloat a=[record[@"DisplayAspect"] doubleValue];
    if (a<=0.3 || !isfinite(a)) return NO;
    CGFloat hostAspect=full.size.width/full.size.height;
    if (fabs(hostAspect/a-1.0)>0.32)return NO;
    CGFloat x=[record[@"X"] doubleValue],y=[record[@"Y"] doubleValue];
    CGFloat w=[record[@"Width"] doubleValue],h=[record[@"Height"] doubleValue];
    if (x<-0.015 || y<-0.015 || w<0.023 || h<0.023 ||
        x+w>1.015 || y+h>1.015)return NO;
    NSString *edge=record[@"Edge"];
    CGRect cropped=CGRectZero;
    if ([edge isEqualToString:@"left"] && x<0.03 && w<0.27 && h>0.5) {
        CGFloat offset=fmax(0,x+w);
        cropped=CGRectMake(full.origin.x+full.size.width*offset,full.origin.y,
                          full.size.width*(1-offset),full.size.height);
    } else if ([edge isEqualToString:@"right"] && x+w>0.97 && w<0.27 && h>0.5) {
        cropped=CGRectMake(full.origin.x,full.origin.y,
                          full.size.width*fmin(1,x),full.size.height);
    } else if ([edge isEqualToString:@"top"] && y<0.03 && h<0.27 && w>0.5) {
        CGFloat offset=fmax(0,y+h);
        cropped=CGRectMake(full.origin.x,full.origin.y+full.size.height*offset,
                          full.size.width,full.size.height*(1-offset));
    } else if ([edge isEqualToString:@"bottom"] && y+h>0.97 && h<0.27 && w>0.5) {
        cropped=CGRectMake(full.origin.x,full.origin.y,
                          full.size.width,full.size.height*fmin(1,y));
    } else return NO;
    if (cropped.size.width<full.size.width*0.50 ||
        cropped.size.height<full.size.height*0.50)return NO;
    if (out)*out=cropped;
    return YES;
}
