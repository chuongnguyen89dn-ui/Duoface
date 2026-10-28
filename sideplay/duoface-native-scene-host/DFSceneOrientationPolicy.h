// DuoFace independent owner-scoped portrait/render-size policy for hosted scenes.
// Public API intentionally does not expose a global orientation override.
// Installed only in SpringBoard, registered by the current live DFSceneSurface.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
BOOL DFSceneOrientationPolicyInstall(void);
// currentLogicalSize returns CGSizeZero if pane/scene/generation/window is no longer owned.
// The block must not retain its surface or call UIKit off the main thread.
void DFSceneOrientationPolicyRegister(id handle, id deviceController,
                                      NSString *bundleID,
                                      CGSize (^currentLogicalSize)(void));
void DFSceneOrientationPolicyUnregister(id handle, id deviceController);
