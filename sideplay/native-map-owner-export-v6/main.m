// Independent mobile-only, user-initiated raw diagnostic JSONL export.
// No CarPlay injection, private scene API, network, or application permission changes.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
static NSString *const DFLog=@"/var/mobile/Library/Logs/DuoFaceCarPlayOwnerSnapshot.log";
@interface DFExporterController : UIViewController
@property(nonatomic,strong) UILabel *info;
@end
@implementation DFExporterController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"DuoFace Maps";
    self.view.backgroundColor=UIColor.systemGroupedBackgroundColor;
    UILabel *l=[UILabel new]; l.translatesAutoresizingMaskIntoConstraints=NO;
    l.numberOfLines=0;l.textAlignment=NSTextAlignmentCenter;
    l.font=[UIFont systemFontOfSize:16];
    l.text=@"Chỉ đọc snapshot thật từ CarPlayApp.\nĐậu xe, để Maps dẫn đường tối thiểu 35 giây; sau đó giữ DuoFace split 35 giây trước khi chia sẻ.";
    [self.view addSubview:l];
    self.info=l;
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints=NO;
    [b setTitle:@"Chia sẻ CarPlay Maps JSONL" forState:UIControlStateNormal];
    [b addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b];
    [NSLayoutConstraint activateConstraints:@[
      [l.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24],
      [l.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24],
      [l.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-60],
      [b.topAnchor constraintEqualToAnchor:l.bottomAnchor constant:28],
      [b.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];
}
- (void)alert:(NSString *)message {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Chưa thể xuất snapshot"
        message:message preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)share:(UIButton *)sender {
    NSFileManager *fm=NSFileManager.defaultManager;
    NSError *error=nil;
    NSDictionary *attrs=[fm attributesOfItemAtPath:DFLog error:&error];
    unsigned long long size=[attrs[NSFileSize] unsignedLongLongValue];
    if(![attrs[NSFileType] isEqualToString:NSFileTypeRegular] || size==0 || size>5*1024*1024) {
        [self alert:error.localizedDescription?:@"Chưa có log hoặc file quá lớn. Chỉ thu khi CarPlayApp đang chạy và Maps đã dẫn đường."];
        return;
    }
    NSString *name=[NSString stringWithFormat:@"DuoFaceCarPlayOwner-%@.jsonl",NSUUID.UUID.UUIDString];
    NSString *temp=[NSTemporaryDirectory() stringByAppendingPathComponent:name];
    if(![fm copyItemAtPath:DFLog toPath:temp error:&error]) {
        [self alert:error.localizedDescription?:@"Không đủ quyền đọc log."];
        return;
    }
    UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:temp]]
                                                                 applicationActivities:nil];
    share.popoverPresentationController.sourceView=sender;
    [self presentViewController:share animated:YES completion:nil];
}
@end
@interface DFExporterApp : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation DFExporterApp
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)application;(void)options;
    self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController=[[UINavigationController alloc] initWithRootViewController:[DFExporterController new]];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
int main(int argc,char **argv){
    @autoreleasepool {return UIApplicationMain(argc,argv,nil,NSStringFromClass(DFExporterApp.class));}
}
