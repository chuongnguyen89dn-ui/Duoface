// Executable replay of real 2026-10-28 Google Maps / native Dashboard
// 427x240 and the real 45px CarPlay side bar. NO fixed 45px assumption.
// Dock position must be observed in connected UIWindowScene sibling window.
#import <Foundation/Foundation.h>
#import "../DFCarPlayNativeMapViewportPlan.h"
static void check(BOOL ok,NSString *name) {
 if(!ok){NSLog(@"FAIL native-maps-viewport %@",name);exit(1);}
}
static NSArray *inventory(NSString *barFrame,BOOL right,BOOL twoBars,BOOL hasDashboard) {
    NSDictionary *bar=@{@"windowClass":@"DBStatusBarWindow",
      @"rootController":@"DBRootStatusBarViewController",
      @"hidden":@NO,@"bounds":@"{{0, 0}, {45, 240}}",
      @"dashboardRelativeFrame":barFrame?:@"nil"};
    NSDictionary *root=@{@"windowClass":@"UIWindow",
      @"rootController":hasDashboard?@"DBDashboardRootViewController":@"Other",
      @"hidden":@NO,@"bounds":@"{{0, 0}, {427, 240}}",
      @"dashboardRelativeFrame":@"{{0, 0}, {427, 240}}"};
    NSMutableArray *bars=[NSMutableArray arrayWithObject:bar];
    if(twoBars)[bars addObject:bar];
    NSDictionary *s1=@{@"sceneRole":@"UIWindowSceneSessionRoleCarPlay",
      @"screenPointer":@"0x1234",
      @"sceneIdentifier":@"statusbar-Car[2-3]",@"windows":bars};
    NSDictionary *s2=@{@"sceneRole":@"UIWindowSceneSessionRoleCarPlay",
      @"screenPointer":@"0x1234",
      @"sceneIdentifier":@"DBDashboard-Car[2-3]",@"windows":@[root]};
    (void)right;
    return @[s1,s2];
}
int main(void) {
 @autoreleasepool {
    NSDictionary *layout=@{@"Version":@2,@"Ratio":@.5,@"Swapped":@NO};
    CGRect r=CGRectNull;
    check(DFCPReadMeasuredRect(@"{{0, 0}, {427, 240}}",&r) &&
          fabs(r.size.width-427)<0.1,@"real iOS UIKit rect string");
    check(!DFCPReadMeasuredRect(@"nil",&r),@"nil rect rejected");
    check(!DFCPReadMeasuredRect(@"{{0, 0}, {NaN, 240}}",&r),@"nan rejected");
    check(!DFCPReadMeasuredRect(@"{{0, 0}, {427, -240}}",&r),@"negative rejected");
    check(!DFCPReadMeasuredRect(@"{{0, 0}, {427, 240}}junk",&r),@"trailing bytes rejected");
    NSDictionary *a=DFCarPlayNativeMapViewportPlan(
       inventory(@"{{0, 0}, {45, 240}}",NO,NO,YES),layout);
    check([a[@"status"] isEqual:@"measured-carplay-content-split-plan"],@"true native dock measured");
    check([a[@"dockEdge"] isEqual:@"left"],@"left placement proven");
    check([a[@"usableRect"][@"x"] isEqual:@45] &&
          [a[@"usableRect"][@"width"] isEqual:@382],@"427 minus real 45 equals 382");
    check([a[@"visualSlot0"][@"width"] isEqual:@191] &&
          [a[@"visualSlot1"][@"x"] isEqual:@236],@"two pane frames in genuine visible content");
    check([a[@"canAttachPane"] isEqual:@NO] &&
          [a[@"mapSceneSizedForPane"] isEqual:@NO] &&
          [a[@"nativeMapSlotAssigned"] isEqual:@NO],@"planning not actual map rendering");
    NSDictionary *right=DFCarPlayNativeMapViewportPlan(
       inventory(@"{{382, 0}, {45, 240}}",YES,NO,YES),layout);
    check([right[@"dockEdge"] isEqual:@"right"] &&
          [right[@"usableRect"][@"x"] isEqual:@0],@"no hard-coded Dock-left");
    NSDictionary *noFrames=DFCarPlayNativeMapViewportPlan(
       inventory(nil,NO,NO,YES),layout);
    check([noFrames[@"status"] isEqual:@"native-dock-position-not-observed"] &&
          [noFrames[@"canAttachPane"] isEqual:@NO],@"old V7 log cannot infer edge from bar size");
    NSDictionary *two=DFCarPlayNativeMapViewportPlan(
       inventory(@"{{0, 0}, {45, 240}}",NO,YES,YES),layout);
    check([two[@"status"] isEqual:@"ambiguous-native-dock"] &&
          [two[@"canAttachPane"] isEqual:@NO],@"two dock candidates rejected");
    NSDictionary *missing=DFCarPlayNativeMapViewportPlan(
       inventory(@"{{0, 0}, {45, 240}}",NO,NO,NO),layout);
    check([missing[@"status"] isEqual:@"unresolved"],@"Dashboard owner absent");
    NSDictionary *bad=[layout mutableCopy];
    NSMutableDictionary *m=[layout mutableCopy];m[@"Ratio"]=@.2;
    check([DFCarPlayNativeMapViewportPlan(inventory(@"{{0, 0}, {45, 240}}",NO,NO,YES),m)
           [@"status"] isEqual:@"unresolved"],@"unsupported ratio rejected");
    (void)bad;
    NSLog(@"DUOFACE_NATIVE_MAPS_MEASURED_DOCK_AND_SPLIT_VIEWPORT_PASS_NO_SCENE_MUTATION");
 }
 return 0;
}
