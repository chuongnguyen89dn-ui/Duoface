#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
// Independent Native12-inspired control chrome for an external UIKit display.
// Does not host iPhone apps, call vendor classes, or touch CarPlay's system Dock.
typedef void (^DFNative12ChromeCommand)(NSString *action, NSNumber *ratio);
@interface DFNative12Chrome : NSObject
- (instancetype)initWithDisplay:(id)display
                configuration:(Class)configurationClass
                  windowClass:(Class)windowClass
                  contentRect:(CGRect)content
                      command:(DFNative12ChromeCommand)command;
- (NSDictionary *)geometryReadback119;
- (BOOL)start;
// Accepts only selected Home app into the already active SpringBoard scene host.
- (BOOL)openSelectedHomeBundleID143:(NSString *)bundleID;
- (void)skipStartupSplashForHomeReentry;
- (void)hideAllExternalWindowsImmediately;
// Immutable post-action state sampled from the actual SpringBoard UI owner.
// This is the proof of operation relayed to CarPlay; never a second renderer.
- (NSDictionary<NSString *, id> *)stateSnapshot;
// Snapshot current owner verified live process IDs BEFORE host scene teardown.
- (NSArray<NSDictionary *> *)disconnectTerminationCandidates;
- (BOOL)applyLayoutSettingsFromDisk;
// Two-phase Native12 fullscreen: geometry changes ONLY after an actual,
// same-session CarPlay Dashboard owner has confirmed hiding its native Dock.
// The receiver/ack is NOT implemented here; never pass a guessed YES.
- (BOOL)applyHostFullscreenToScreenBoundsAfterDockAck:(CGRect)screenBounds;
- (void)restoreHostFullscreenGeometry;
// Do not hide an active App card until actual Dock+geometry completion.
- (void)completeWholeHostZoomRequest:(BOOL)applied;
- (void)stop;
@end
