// QA143: SpringBoard-only category; reuse DuoFace's existing REAL scene host.
// This does not fabricate UI pickers, CP scene delegates, or background sessions.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "DFHomeSceneBridge143.h"
#import "DFAppPickerVC.h"
#import "DFEnabledAppsPolicy.h"
#import "DFHome140Consent.h"

@interface DFNative12Chrome (DFHome143Private)
- (DFAppPickerVC *)appPickerController;
- (UIWindow *)appPickerWindow;
- (void)setSelectedSlot:(NSInteger)slot;
- (void)appPicker:(DFAppPickerVC *)picker
 didSelectBundleID:(NSString *)bundleID displayName:(NSString *)displayName;
@end

@implementation DFNative12Chrome (DFHome143)
- (BOOL)openSelectedHomeBundleID143:(NSString *)bundleID {
 if(!NSThread.isMainThread || !DFHome140Enabled() ||
    !DFPickerAllowsApp(bundleID,DFConfiguredEnabledAppIDs()))return NO;
 DFAppPickerVC *picker=[self appPickerController];
 if(!picker || ![self appPickerWindow])return NO;
 // The selected external Home app enters the first existing physical pane;
 // other saved scenes remain untouched, selected/ready scene lifecycle stays
 // solely owned by DFNative12Chrome's existing appPicker:didSelect... path.
 [self setSelectedSlot:0];
 [self appPicker:picker didSelectBundleID:bundleID displayName:bundleID];
 // Return indicates accepted dispatch, NOT successful app scene readiness.
 return YES;
}
@end
