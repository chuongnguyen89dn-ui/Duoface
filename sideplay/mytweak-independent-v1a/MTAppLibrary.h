// MTAppLibrary — liệt kê app người dùng đã cài.
// Dùng LSApplicationWorkspace (private API) qua runtime lookup (NSClassFromString)
// nên compile được mà không cần private header; nếu API không tồn tại thì
// trả về danh sách rỗng một cách an toàn.

#import <Foundation/Foundation.h>

@interface MTAppInfo : NSObject
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *displayName;
@end

@interface MTAppLibrary : NSObject

// Trả về app do người dùng cài (bỏ app hệ thống com.apple.*), xếp theo tên.
+ (NSArray<MTAppInfo *> *)installedUserApps;

@end
