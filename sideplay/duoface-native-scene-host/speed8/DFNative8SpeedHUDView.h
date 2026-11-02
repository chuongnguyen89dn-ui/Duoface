#pragma once
#import <UIKit/UIKit.h>
// OWN historical Speed8 HUD view only; portable data and UI without old
// proprietary bridge manager. NOT mounted until safe real live owner validated.
FOUNDATION_EXPORT UILabel *DF169MakeBubbleDismissSymbol(void);
@interface DFNative8SpeedHUDView : UIView
@property(nonatomic,weak) UIWindow *ownerWindow;
// Small 44pt noninteractive X window supplied by the existing external owner.
@property(nonatomic,weak) UIWindow *dismissWindow;
// Opt-in small independent external floating UIWindow. Drag is constrained to
// the verified DuoFace content rectangle, not the current split-app pane.
// The actual window remains bubble-sized to preserve taps in other apps.
@property(nonatomic,assign) CGRect floatingDragBounds;
@property(nonatomic,assign) BOOL floatingWindowMode;
- (void)restoreSavedPosition;
- (void)stop;
@end
