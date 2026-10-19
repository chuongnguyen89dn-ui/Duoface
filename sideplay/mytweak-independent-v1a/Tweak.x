// MyTweak — CarPlay bridge viết lại từ đầu (code gốc 100%, không copy từ tweak nào).
// Entry point: hook SpringBoard, khởi tạo MTBridgeCoordinator khi SpringBoard
// khởi động xong. Không có bất kỳ code kiểm tra giấy phép nào trong project này.

#import <UIKit/UIKit.h>
#import "MTBridgeCoordinator.h"
#import "MTPreflight.h"
#define MT_V1A_PREFLIGHT_ONLY 1

// = 1: hiện alert trên màn iPhone khi tweak load (để kiểm tra inject thành công).
// Đặt = 0 khi đã ổn định, không muốn bị làm phiền mỗi lần respring.
#define MT_SHOW_LOAD_ALERT 0

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        #if MT_V1A_PREFLIGHT_ONLY
        [MTPreflight startReadOnlyDiagnostics];
#else
        [[MTBridgeCoordinator sharedCoordinator] start];
#endif

#if MT_SHOW_LOAD_ALERT
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"MyTweak"
            message:@"Bridge coordinator đã chạy. Kết nối CarPlay để hiện cửa sổ."
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault handler:nil]];
        UIViewController *root =
            [UIApplication sharedApplication].keyWindow.rootViewController;
        [root presentViewController:alert animated:YES completion:nil];
#endif
    });
}

%end
