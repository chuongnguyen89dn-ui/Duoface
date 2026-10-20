#import <UIKit/UIKit.h>
@interface DFQAAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
int main(int argc,char **argv) { @autoreleasepool {
  return UIApplicationMain(argc,argv,nil,NSStringFromClass([DFQAAppDelegate class]));
}}
