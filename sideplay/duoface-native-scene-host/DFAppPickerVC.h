// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
// DFAppPickerVC — màn chọn app (hiện trên chính màn CarPlay).
// Liệt kê app người dùng đã cài (qua DFAppLibrary), chạm để chọn.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DFAppPickerVC;

@protocol DFAppPickerDelegate <NSObject>
- (void)appPicker:(DFAppPickerVC *)picker
    didSelectBundleID:(NSString *)bundleID
          displayName:(NSString *)name;
- (void)appPickerDidCancel:(DFAppPickerVC *)picker;
// Original setupCardContent has THREE modes: Apps, Layout, Recent.
// Each request is routed to the EXISTING independent real scene owner.
- (void)appPickerDidRequestLayout:(DFAppPickerVC *)picker;
- (void)appPickerDidRequestRunningApps:(DFAppPickerVC *)picker;
- (void)appPickerDidRequestZoom:(DFAppPickerVC *)picker;
// Original CBMultitaskingOverlayView.showRecentAppsInParentView:
// native controls operate on verified live bundle identifiers, never
// installed-app guesses, stored Recent history, or an invented demo list.
- (void)appPicker:(DFAppPickerVC *)picker closeRunningBundleID:(NSString *)bundleID;
- (void)appPicker:(DFAppPickerVC *)picker restartRunningBundleID:(NSString *)bundleID;
- (void)appPickerCloseAllRunning:(DFAppPickerVC *)picker;
- (void)appPicker:(DFAppPickerVC *)picker rotateRunningClockwise:(BOOL)clockwise;
@end

@interface DFAppPickerVC : UIViewController

@property (nonatomic, weak, nullable) id<DFAppPickerDelegate> delegate;
// Reload the real installed-app inventory every time the CarPlay picker opens.
- (void)refreshInstalledApps;
// Switch existing App picker between original App and live-running Close mode.
// Only real DFSceneHost-owned, scene-ready bundle IDs may be supplied.
// Only verified live SceneHost slot identity, never guessed installed-app state.
@property (nonatomic, copy, nullable) NSString *currentSlotBundleID;
// A requested app that has not produced a live scene is NOT selected/running.
@property (nonatomic, copy, nullable) NSString *pendingSlotBundleID;
// Scene-ready IDs in the OTHER visible slots, never an installed-app guess.
@property (nonatomic, copy) NSArray<NSString *> *otherSlotBundleIDs;
@property (nonatomic, assign) BOOL hostExpanded;
@property (nonatomic, assign) NSInteger runningRotateCapacity;
// Keyed by verified live hosted bundle ID. PID omitted when not actually verified.
@property (nonatomic, copy) NSDictionary<NSString *,NSDictionary *> *runningAppDetails;
- (void)presentInstalledApps;
- (void)presentRunningApps:(NSArray<NSString *> *)verifiedBundleIDs;

@end

NS_ASSUME_NONNULL_END

