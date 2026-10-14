#import <Foundation/Foundation.h>

// All entry points and callbacks are main-thread only.
// Result acknowledges host geometry, not Dashboard chrome or device validation.
FOUNDATION_EXPORT BOOL DFStartFullscreenTransport(BOOL springBoard,
    void (^stateChanged)(NSDictionary *state));
FOUNDATION_EXPORT void DFRequestHostFullscreen(BOOL expanded,
    void (^completion)(BOOL applied, NSString *reason));
FOUNDATION_EXPORT void DFQueryFullscreenHost(void);
