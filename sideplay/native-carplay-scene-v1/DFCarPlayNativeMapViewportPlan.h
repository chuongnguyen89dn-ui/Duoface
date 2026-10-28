// First-party native Maps split geometry: derive from REAL CarPlay Dock
// UIWindow position, not an arbitrary zoom factor or a guessed 45pt crop.
// This is READ-ONLY planning. Geometry is not authority to attach a foreign
// scene, change CPWindow, resize navigation or render map tiles.
#ifndef DF_CARPLAY_NATIVE_MAP_VIEWPORT_PLAN_H
#define DF_CARPLAY_NATIVE_MAP_VIEWPORT_PLAN_H
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>

static inline BOOL DFCPReadMeasuredRect(id text,CGRect *out) {
    if(![text isKindOfClass:NSString.class] || [text length]>180 ||
       ![(NSString *)text hasPrefix:@"{{"] ||
       ![(NSString *)text hasSuffix:@"}}"])return NO;
    NSScanner *scan=[NSScanner scannerWithString:text];
    scan.charactersToBeSkipped=[NSCharacterSet characterSetWithCharactersInString:@" {},\t\r\n"];
    double v[4]={0};
    for(NSUInteger i=0;i<4;i++) {
        if(![scan scanDouble:&v[i]] || !isfinite(v[i]) || fabs(v[i])>100000)return NO;
    }
    if(!scan.isAtEnd || v[2]<=0 || v[3]<=0)return NO;
    if(out)*out=CGRectMake(v[0],v[1],v[2],v[3]);
    return YES;
}
static inline NSDictionary *DFCPRectRecord(CGRect r) {
    return @{@"x":@(r.origin.x),@"y":@(r.origin.y),
             @"width":@(r.size.width),@"height":@(r.size.height)};
}
static inline NSDictionary *DFCarPlayNativeMapViewportPlan(
    NSArray *scenes, NSDictionary *layout) {
    NSDictionary *fail=@{@"schema":@1,@"status":@"unresolved",
                         @"dockMeasured":@NO,@"nativeMapSlotAssigned":@NO,
                         @"mapSceneSizedForPane":@NO,@"canAttachPane":@NO};
    if(![scenes isKindOfClass:NSArray.class] ||
       ![layout isKindOfClass:NSDictionary.class])return fail;
    id ratioObj=layout[@"Ratio"];
    if(![layout[@"Version"] isEqual:@2] ||
       ![ratioObj isKindOfClass:NSNumber.class] ||
       ![layout[@"Swapped"] isKindOfClass:NSNumber.class])return fail;
    double ratio=[ratioObj doubleValue];
    if(!isfinite(ratio) || ratio<1.0/3.0 || ratio>2.0/3.0)return fail;
    // Gather Dashboard owner and its exact screen. StatusBar/Dock may live
    // in a SEPARATE connected UIWindowScene on the same vehicle UIScreen.
    CGRect dashboard=CGRectNull;
    NSString *screen=nil;
    NSUInteger roots=0;
    for(id s in scenes) {
        if(![s isKindOfClass:NSDictionary.class])continue;
        if(![s[@"sceneRole"] isEqual:@"UIWindowSceneSessionRoleCarPlay"])continue;
        NSString *screenID=s[@"screenPointer"];
        if(![screenID isKindOfClass:NSString.class] ||
           ![screenID hasPrefix:@"0x"])continue;
        for(id win in s[@"windows"]) {
            if(![win isKindOfClass:NSDictionary.class] ||
               ![win[@"rootController"] isEqual:@"DBDashboardRootViewController"] ||
               ![win[@"hidden"] isEqual:@NO])continue;
            CGRect candidate;
            if(!DFCPReadMeasuredRect(win[@"bounds"],&candidate))continue;
            roots++;dashboard=candidate;screen=screenID;
        }
    }
    if(roots!=1 || !screen || CGRectGetWidth(dashboard)<260 ||
       CGRectGetHeight(dashboard)<140)return fail;
    CGRect dock=CGRectNull;
    NSUInteger docks=0;
    for(id s in scenes) {
        if(![s isKindOfClass:NSDictionary.class] ||
           ![s[@"screenPointer"] isEqual:screen] ||
           ![s[@"sceneRole"] isEqual:@"UIWindowSceneSessionRoleCarPlay"])
            continue;
        for(id win in s[@"windows"]) {
            if(![win isKindOfClass:NSDictionary.class] ||
               ![win[@"hidden"] isEqual:@NO] ||
               ![@[@"DBStatusBarWindow",@"DBDockWindow",@"CARStatusBarWindow"]
                     containsObject:win[@"windowClass"]])continue;
            CGRect candidate;
            // Requires an actual converted coordinate from UIKit's SAME
            // external UIScreen. Merely 45×240 bounds does not identify
            // whether the bar is left or right.
            if(!DFCPReadMeasuredRect(win[@"dashboardRelativeFrame"],&candidate))
                continue;
            CGFloat h=CGRectGetHeight(dashboard),w=CGRectGetWidth(dashboard);
            if(CGRectGetHeight(candidate)<h*.65 ||
               CGRectGetWidth(candidate)>w*.30)continue;
            BOOL left=fabs(CGRectGetMinX(candidate)-CGRectGetMinX(dashboard))<1;
            BOOL right=fabs(CGRectGetMaxX(candidate)-CGRectGetMaxX(dashboard))<1;
            if(left==right)continue;
            dock=candidate;docks++;
        }
    }
    if(docks!=1)return @{
        @"schema":@1,@"status":docks>1?@"ambiguous-native-dock":
                                                 @"native-dock-position-not-observed",
        @"dashboardRect":DFCPRectRecord(dashboard),
        @"dockMeasured":@NO,@"nativeMapSlotAssigned":@NO,
        @"mapSceneSizedForPane":@NO,@"canAttachPane":@NO};
    CGFloat width=CGRectGetWidth(dashboard),dwidth=CGRectGetWidth(dock);
    BOOL dockLeft=fabs(CGRectGetMinX(dock)-CGRectGetMinX(dashboard))<1;
    if(dwidth<10 || dwidth>=width*.3)return fail;
    CGRect usable=CGRectMake(dockLeft?CGRectGetMaxX(dock):dashboard.origin.x,
                            dashboard.origin.y,width-dwidth,dashboard.size.height);
    if(CGRectGetWidth(usable)<200 || CGRectGetHeight(usable)<140 ||
       !CGRectContainsRect(dashboard,usable))return fail;
    CGFloat leftWidth=round(usable.size.width*ratio);
    CGRect left=CGRectMake(usable.origin.x,usable.origin.y,leftWidth,usable.size.height);
    CGRect right=CGRectMake(CGRectGetMaxX(left),usable.origin.y,
                            usable.size.width-leftWidth,usable.size.height);
    if(left.size.width<90 || right.size.width<90)return fail;
    return @{@"schema":@1,@"status":@"measured-carplay-content-split-plan",
         @"dockMeasured":@YES,@"dockEdge":dockLeft?@"left":@"right",
         @"dashboardRect":DFCPRectRecord(dashboard),@"dockRect":DFCPRectRecord(dock),
         @"usableRect":DFCPRectRecord(usable),
         @"visualSlot0":DFCPRectRecord(left),@"visualSlot1":DFCPRectRecord(right),
         @"swapped":layout[@"Swapped"],
         @"nativeMapSlotAssigned":@NO,@"mapSceneSizedForPane":@NO,
         @"canAttachPane":@NO};
}
#endif
