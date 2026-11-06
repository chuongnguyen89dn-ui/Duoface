// DuoFace-owned four-second divider Chrome visual policy.
// Geometry, remote-app scenes and keyboard state are intentionally NOT inputs.
#ifndef DF_CHROME_VISUAL_178_H
#define DF_CHROME_VISUAL_178_H
#import <Foundation/Foundation.h>
#import <math.h>

NS_INLINE BOOL DF178ChromeVisible(NSTimeInterval now, NSTimeInterval controlsUntil,
                                   BOOL isDragging, BOOL logoTouchPending) {
    if(isDragging || logoTouchPending)return YES;
    return isfinite(now) && isfinite(controlsUntil) && now<=controlsUntil;
}
// A posted old block must never repaint a new or stopped CarPlay session.
// The live-owner/session proof is supplied by DF177AppTouchSessionMatches.
NS_INLINE BOOL DF178ChromeExpiryGenerationCurrent(NSUInteger captured,
                                                   NSUInteger current) {
    return captured!=0 && captured==current;
}
NS_INLINE NSTimeInterval DF178ChromeDelayUntilExpiry(NSTimeInterval now,
                                                      NSTimeInterval controlsUntil) {
    if(!isfinite(now) || !isfinite(controlsUntil))return 0.05;
    return MAX(0.05,MIN(4.05,controlsUntil-now+0.05));
}
#endif
