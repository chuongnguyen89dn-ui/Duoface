#import <Foundation/Foundation.h>
// SpringBoard-only, independent, optional physical-disconnect lifecycle.
FOUNDATION_EXPORT void DFDisconnectCloseCapture(NSArray<NSDictionary *> *candidates, NSString *session);
FOUNDATION_EXPORT void DFDisconnectClosePhysicalObserved(BOOL connected);
FOUNDATION_EXPORT BOOL DFDisconnectCloseNeedsMonitoring(void);
FOUNDATION_EXPORT void DFDisconnectCloseNewActiveSession(void);
FOUNDATION_EXPORT void DFDisconnectClosePolicyChanged(void);
FOUNDATION_EXPORT void DFDisconnectCloseSetConnectionProbe(BOOL (^probe)(void));
