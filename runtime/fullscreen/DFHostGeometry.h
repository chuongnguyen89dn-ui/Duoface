#import <UIKit/UIKit.h>

// SpringBoard half of the v12 adapter. All calls must run on the main thread.
// Staged implementation: not linked into the host4 build yet.
FOUNDATION_EXPORT BOOL DFInstallHostGeometryHooks(void);
FOUNDATION_EXPORT BOOL DFHostCanExpand(void);
FOUNDATION_EXPORT BOOL DFHostIsExpanded(void);
FOUNDATION_EXPORT BOOL DFHostSetExpanded(BOOL expanded, NSString **reason);
FOUNDATION_EXPORT void DFHostRestore(void);
FOUNDATION_EXPORT void DFHostSetLifecycleCallback(void (^callback)(void));
