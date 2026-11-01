#pragma once
#import <UIKit/UIKit.h>
// OWN historical Speed8 HUD view only; portable data and UI without old
// proprietary bridge manager. NOT mounted until safe real live owner validated.
@interface DFNative8SpeedHUDView : UIView
@property(nonatomic,weak) UIWindow *ownerWindow;
// Opt-in small independent external floating UIWindow. Drag is constrained to
// the verified DuoFace content rectangle, not the current split-app pane.
// The actual window remains bubble-sized to preserve taps in other apps.
@property(nonatomic,assign) CGRect floatingDragBounds;
@property(nonatomic,assign) BOOL floatingWindowMode;
- (void)restoreSavedPosition;
- (void)stop;
@end
