// DuoFace opt-in iPhone voice assistant. Never opens microphone without tap.
// Local speech recognition with iOS permissions; no remote media/window mutations.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface DFVoiceAssistant : NSObject
@property(nonatomic,readonly,getter=isListening) BOOL listening;
- (void)toggleFromController:(UIViewController *)controller
                  completed:(void (^)(NSString *message))completion;
- (void)stop;
@end
NS_ASSUME_NONNULL_END
