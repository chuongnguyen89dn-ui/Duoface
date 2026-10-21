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
- (BOOL)start;
- (void)stop;
@end
