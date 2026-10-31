// Standalone exporter/marker; no background upload, license, or app-scene control.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <fcntl.h>
#import <unistd.h>
static NSString *const dnFolder=@"/var/mobile/Library/Logs";
static NSString *const dnMarkers=@"/var/mobile/Library/Logs/DuoNaviObserver-markers.jsonl";
@interface DNView : UIViewController
@property(nonatomic,strong)UILabel *status;
@end
@implementation DNView
- (void)viewDidLoad {
 [super viewDidLoad];
 self.title=@"Observer 0.0.2 · Dock ABI";self.view.backgroundColor=UIColor.systemGroupedBackgroundColor;
 UIStackView *stack=[UIStackView new];stack.axis=UILayoutConstraintAxisVertical;
 stack.spacing=13;stack.translatesAutoresizingMaskIntoConstraints=NO;
 UILabel *info=[UILabel new];info.font=[UIFont systemFontOfSize:15];info.numberOfLines=0;
 info.text=@"Bộ ghi log Dock/Home chỉ đọc. Sau khi kết nối CarPlay, thử mở app và Home trong 60 giây đầu. Sau đó chọn Xuất log.";
 self.status=info;[stack addArrangedSubview:info];
 NSArray *names=@[@"1. Play YouTube khi màn sáng",@"2. Chuẩn bị khóa iPhone",
    @"3. Sau khi mở khóa",@"4. Chuẩn bị về Home CarPlay",
    @"5. Chuẩn bị rút dây",@"6. Xuất log"];
 for(NSUInteger i=0;i<names.count;i++){
   UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];button.tag=i;
   [button setTitle:names[i] forState:UIControlStateNormal];
   button.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
   [button addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
   [stack addArrangedSubview:button];
 }
 [self.view addSubview:stack];
 [NSLayoutConstraint activateConstraints:@[
  [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:22],
  [stack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
  [stack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20]
 ]];
}
- (void)alert:(NSString *)title detail:(NSString *)message{
 UIAlertController *a=[UIAlertController alertControllerWithTitle:title message:message
   preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
 [self presentViewController:a animated:YES completion:nil];
}
- (void)action:(UIButton *)button{
 if(button.tag==5){[self exportNow:button];return;}
 NSArray *stages=@[@"VIDEO_AWAKE",@"BEFORE_PHONE_LOCK",@"AFTER_PHONE_UNLOCK",
   @"BEFORE_CARPLAY_HOME",@"BEFORE_UNPLUG"];
 NSData *data=[NSJSONSerialization dataWithJSONObject:
  @{@"event":@"manual_mark",@"stage":stages[button.tag],
    @"utc":@(NSDate.date.timeIntervalSince1970)}
  options:0 error:nil];
 if(!data)return;
 int fd=open(dnMarkers.fileSystemRepresentation,O_CREAT|O_WRONLY|O_APPEND,0644);
 if(fd<0){[self alert:@"Không ghi log" detail:@"Không đủ quyền ghi marker"];return;}
 ssize_t n=write(fd,data.bytes,data.length);(void)write(fd,"\n",1);close(fd);
 if(n!=(ssize_t)data.length){[self alert:@"Lỗi ghi" detail:@"Marker chưa đủ"];return;}
 self.status.text=[NSString stringWithFormat:@"Đã đánh dấu %@. Bây giờ thử trên xe khi đang đỗ.",stages[button.tag]];
}
- (void)exportNow:(UIButton *)sender{
 NSMutableString *report=[NSMutableString stringWithFormat:
   @"DuoNavi Observer PASSIVE export\nTime: %@\niOS: %@\n",NSDate.date.description,UIDevice.currentDevice.systemVersion];
 NSArray *names=@[@"DuoNaviObserver-SpringBoard.jsonl",
  @"DuoNaviObserver-SpringBoard.jsonl.previous",
  @"DuoNaviObserver-CarPlay.jsonl",@"DuoNaviObserver-CarPlay.jsonl.previous",
  @"DuoNaviObserver-CarPlayApp.jsonl",@"DuoNaviObserver-CarPlayApp.jsonl.previous",
  @"DuoNaviObserver-markers.jsonl"];
 NSUInteger count=0;
 for(NSString *name in names) {
  NSString *path=[dnFolder stringByAppendingPathComponent:name];
  NSDictionary *attrs=[NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
  unsigned long long size=[attrs[NSFileSize] unsignedLongLongValue];
  if(![attrs[NSFileType] isEqualToString:NSFileTypeRegular]||!size||size>3145728)continue;
  NSData *data=[NSData dataWithContentsOfFile:path options:0 error:nil];
  NSString *contents=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if(!contents)continue;
  [report appendFormat:@"\n=== %@ (%llu bytes) ===\n%@\n",name,size,contents];
  count++;
 }
 if(!count){[self alert:@"Chưa có log" detail:@"Cài qua Sileo, Respring rồi mở DuoNavi gốc để thử."];return;}
 NSString *dst=[NSTemporaryDirectory() stringByAppendingPathComponent:
   [NSString stringWithFormat:@"DuoNaviObserver-%@.txt",NSUUID.UUID.UUIDString]];
 if(![report writeToFile:dst atomically:YES encoding:NSUTF8StringEncoding error:nil]){
   [self alert:@"Lỗi xuất" detail:@"Không ghi được tệp"];return;
 }
 UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:
   @[[NSURL fileURLWithPath:dst]] applicationActivities:nil];
 share.popoverPresentationController.sourceView=sender;
 [self presentViewController:share animated:YES completion:nil];
}
@end
@interface DNApp : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong)UIWindow *window;
@end
@implementation DNApp
- (BOOL)application:(UIApplication *)a didFinishLaunchingWithOptions:(NSDictionary *)o{
 (void)a;(void)o;
 self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[[UINavigationController alloc] initWithRootViewController:[DNView new]];
 [self.window makeKeyAndVisible];return YES;
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(DNApp.class));}}
