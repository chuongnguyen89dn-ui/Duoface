#import <Foundation/Foundation.h>

// The probe returns the presentation-owned FBScene, or nil when that lease
// expires. It gates foreground/under-lock policy, NOT manual callback ownership.
// Registration separately owns the manual controller's current-handle callback
// until Unregister; call Unregister before mode0/invalidate during teardown.
// It must not retain the owner/controller. All registration is main-thread only.
BOOL DFSceneLifecycleInstall(void);
void DFSceneLifecycleRegister(id controller, id (^currentOwnedScene)(void));
void DFSceneLifecycleUnregister(id controller);
