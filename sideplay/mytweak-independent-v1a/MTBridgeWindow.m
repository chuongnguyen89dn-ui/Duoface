#import "MTBridgeWindow.h"

@implementation MTBridgeWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"[MyTweak] Bridge window created: %@", NSStringFromCGRect(frame));
    }
    return self;
}

@end
