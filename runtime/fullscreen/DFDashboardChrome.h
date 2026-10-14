#import <UIKit/UIKit.h>

// Dashboard half, matched to Airaw's DB/CARStatusBarWindow chrome receiver.
FOUNDATION_EXPORT BOOL DFInstallDashboardChromeHooks(void);
FOUNDATION_EXPORT BOOL DFDashboardSetChromeHidden(BOOL hidden, NSString **reason);
FOUNDATION_EXPORT void DFDashboardRestoreChrome(void);
