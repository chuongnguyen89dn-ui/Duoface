#import <Foundation/Foundation.h>

// The probe returns the currently owned FBScene, or nil when ownership expires.
// It must not retain the owner/controller. All registration is main-thread only.
BOOL DFSceneLifecycleInstall(void);
void DFSceneLifecycleRegister(id controller, id (^currentOwnedScene)(void));
void DFSceneLifecycleUnregister(id controller);
