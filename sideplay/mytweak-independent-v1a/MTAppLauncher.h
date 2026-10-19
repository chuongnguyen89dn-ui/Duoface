// MTAppLauncher — mở một app vào "session" để gắn vào slot.
// MTAppSession giữ bundleID + tên + view đã host (nếu host được).

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTAppSession : NSObject
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *displayName;
// View chứa giao diện của app, do MTSceneHost tạo. nil = chưa host được.
@property (nonatomic, strong, nullable) UIView *hostedView;
@end

@interface MTAppLauncher : NSObject

+ (instancetype)sharedLauncher;

// Mở app theo bundleID. Trả về session nếu thành công, nil + error nếu không.
- (nullable MTAppSession *)launchAppWithBundleID:(NSString *)bundleID
                                           error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
