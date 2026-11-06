// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
// DFAppLibrary — liệt kê app người dùng đã cài.
// Dùng LSApplicationWorkspace (private API) qua runtime lookup (NSClassFromString)
// nên compile được mà không cần private header; nếu API không tồn tại thì
// trả về danh sách rỗng một cách an toàn.

#import <Foundation/Foundation.h>

@interface DFAppInfo : NSObject
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *displayName;
// Per-picker independent route. Only real CarPlay native map catalog proves ready.
@property (nonatomic, assign) NSInteger carPlayRoute178;
@end

@interface DFAppLibrary : NSObject

// Trả về app do người dùng cài (bỏ app hệ thống com.apple.*), xếp theo tên.
+ (NSArray<DFAppInfo *> *)installedUserApps;
// A selected app missing from the bulk LS inventory can still have an exact
// live installed proxy; fail closed on a mismatched/hidden/placeholder bundle.
+ (NSArray<DFAppInfo *> *)selectedAppFallbackForBundleIDs:(NSArray<NSString *> *)selected;

@end
