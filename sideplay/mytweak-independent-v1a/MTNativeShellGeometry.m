#import "MTNativeShellGeometry.h"
#import <math.h>
NSString *MTNativeShellRecordPath(void) {
    return @"/var/mobile/Library/Preferences/com.duoface.mytweak.shell-scene.plist";
}
static BOOL MTNumberFinite(id n) {
    return [n isKindOfClass:NSNumber.class] && isfinite([n doubleValue]);
}
BOOL MTNativeShellUsableRect(CGRect bounds,NSDictionary *record,CGRect *out) {
    if (CGRectIsEmpty(bounds) || bounds.size.width<240 || bounds.size.height<100 ||
        ![record isKindOfClass:NSDictionary.class]) return NO;
    if (![record[@"Producer"] isEqualToString:@"IndependentDuoFaceShell"] ||
        ![record[@"Kind"] isEqualToString:@"NativeCarPlayWindowScene"] ||
        ![record[@"CarPlayRole"] isEqual:@YES] ||
        ![record[@"GeometryValid"] isEqual:@YES] ||
        ![record[@"NativeContentExcludesChrome"] isEqual:@YES])return NO;
    for (NSString *key in @[@"X",@"Y",@"Width",@"Height",@"Timestamp",@"DisplayAspect"])
        if (!MTNumberFinite(record[key]))return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[record[@"Timestamp"] doubleValue];
    if (age<0 || age>4.0)return NO;
    CGFloat aspect=[record[@"DisplayAspect"] doubleValue];
    if (aspect<=0 || fabs((bounds.size.width/bounds.size.height)/aspect-1.0)>0.12)
        return NO;
    CGFloat x=[record[@"X"] doubleValue],y=[record[@"Y"] doubleValue],
            w=[record[@"Width"] doubleValue],h=[record[@"Height"] doubleValue];
    if (x<-0.005 || y<-0.005 || w<0.55 || h<0.55 ||
        x+w>1.005 || y+h>1.005)return NO;
    CGRect content=CGRectMake(bounds.origin.x+x*bounds.size.width,
       bounds.origin.y+y*bounds.size.height,w*bounds.size.width,h*bounds.size.height);
    if (CGRectEqualToRect(content,bounds))return NO;
    if (out)*out=content;
    return YES;
}
