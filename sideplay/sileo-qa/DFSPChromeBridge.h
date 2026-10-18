#import <Foundation/Foundation.h>
// DuoFace QA9: independent CarPlay chrome request/ACK channel.
// Caller: SpringBoard QA7 display. Receiver: CarPlay/Dashboard process only.
// Does not modify SidePlay binaries or Native12/HUD8.
FOUNDATION_EXPORT void DFSPChromeRequest(BOOL active, BOOL normalVisible, NSUInteger generation);
FOUNDATION_EXPORT void DFSPChromeInstallReceiver(void);
