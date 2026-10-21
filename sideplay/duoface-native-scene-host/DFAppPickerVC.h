// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
// DFAppPickerVC — màn chọn app (hiện trên chính màn CarPlay).
// Liệt kê app người dùng đã cài (qua DFAppLibrary), chạm để chọn.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DFAppPickerVC;

@protocol DFAppPickerDelegate <NSObject>
- (void)appPicker:(DFAppPickerVC *)picker
    didSelectBundleID:(NSString *)bundleID
          displayName:(NSString *)name;
- (void)appPickerDidCancel:(DFAppPickerVC *)picker;
@end

@interface DFAppPickerVC : UIViewController

@property (nonatomic, weak, nullable) id<DFAppPickerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
