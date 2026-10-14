#import <UIKit/UIKit.h>
FOUNDATION_EXPORT BOOL DFInstallStatusBarControlHooks(void (^pressed)(void));
FOUNDATION_EXPORT void DFSetStatusBarControlState(BOOL visible, BOOL enabled);
