// MTAppPickerViewController — màn chọn app (hiện trên chính màn CarPlay).
// Liệt kê app người dùng đã cài (qua MTAppLibrary), chạm để chọn.

#import <UIKit/UIKit.h>

@class MTAppPickerViewController;

@protocol MTAppPickerDelegate <NSObject>
- (void)appPicker:(MTAppPickerViewController *)picker
    didSelectBundleID:(NSString *)bundleID
          displayName:(NSString *)name;
- (void)appPickerDidCancel:(MTAppPickerViewController *)picker;
@end

@interface MTAppPickerViewController : UIViewController

@property (nonatomic, weak, nullable) id<MTAppPickerDelegate> delegate;

@end
