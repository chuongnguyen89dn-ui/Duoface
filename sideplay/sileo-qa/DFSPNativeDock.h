#import <UIKit/UIKit.h>
// CarPlay's own dock/status strip, not a DuoFace imitation view.
// Main-thread caller SpringBoard; receiver CarPlayApp/CarPlay/Dashboard.
FOUNDATION_EXPORT void DFSPDockRequest(BOOL active, BOOL zoom, NSUInteger generation);

// Native12-style usable CarPlay content rect in WINDOW-LOCAL coordinates;
// preserves the system's 64pt driver-side Dock strip in Normal mode.
FOUNDATION_EXPORT CGRect DFSPNativeDockUsableBounds(UIWindow *window);
