#import <Foundation/Foundation.h>
@class DFNative12Chrome;
// Real two-process Dock ACK followed by source-owned geometry. NEVER guess.
typedef void (^DFDockZoomCompletion)(BOOL applied, BOOL expanded,
                                      NSDictionary<NSString *,id> *receipt);
void DFDockZoomToggle(DFNative12Chrome *chrome, NSString *session,
                      DFDockZoomCompletion completion);
void DFDockZoomDetach(DFNative12Chrome *chrome, NSString *session);
