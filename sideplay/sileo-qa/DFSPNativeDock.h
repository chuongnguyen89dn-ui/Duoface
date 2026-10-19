#import <Foundation/Foundation.h>
// CarPlay's own dock/status strip, not a DuoFace imitation view.
// Main-thread caller SpringBoard; receiver CarPlayApp/CarPlay/Dashboard.
FOUNDATION_EXPORT void DFSPDockRequest(BOOL active, BOOL zoom, NSUInteger generation);
