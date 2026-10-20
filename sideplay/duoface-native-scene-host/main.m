#import <UIKit/UIKit.h>
@interface DFNativeHostAppDelegate : UIResponder <UIApplicationDelegate>
@end
int main(int argc,char **argv) { @autoreleasepool {
    return UIApplicationMain(argc,argv,nil,NSStringFromClass([DFNativeHostAppDelegate class]));
}}
