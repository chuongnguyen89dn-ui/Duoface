#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <notify.h>
#import <mach-o/loader.h>
#import <dispatch/dispatch.h>

// Trình đo chỉ đọc cho bộ máy độc lập, mặc định TẮT.
// Đặt tệp kích hoạt thủ công trong Preferences trước khi khởi động tiến trình.
// Không tạo cửa sổ, không mở ứng dụng, không thay đổi các scene đang hoạt động.
static NSString * const DFIEnabledFile = @"/var/mobile/Library/Preferences/com.duoface.independent.probe.enabled";
static const char * const DFISnapshotEvent = "com.duoface.independent.probe.snapshot";
static BOOL DFIActive = NO;
static BOOL DFIWorkspaceHookInstalled = NO;
static int DFINotificationToken = 0;
static __weak id DFIDashboardWorkspace = nil;
static id (*DFIOriginalWorkspaceInit)(id, SEL, id) = NULL;

typedef void (*DFIHookMessageEx)(Class, SEL, IMP, IMP *);

static BOOL DFIIsTargetProcess(void) {
    NSString *name = NSProcessInfo.processInfo.processName;
    return [@[@"SpringBoard", @"CarPlay", @"CarPlayApp", @"Dashboard"]
            containsObject:name];
}

static void DFILogClass(NSString *name, NSArray<NSString *> *methods) {
    Class cls = NSClassFromString(name);
    if (!cls) {
        NSLog(@"[DuoFaceIndependent] class=%@ present=0", name);
        return;
    }
    NSMutableArray<NSString *> *seen = [NSMutableArray array];
    for (NSString *method in methods) {
        SEL selector = NSSelectorFromString(method);
        if (class_getInstanceMethod(cls, selector)) [seen addObject:method];
    }
    NSLog(@"[DuoFaceIndependent] class=%@ present=1 methods=%@",
          name, [seen componentsJoinedByString:@","]);
}

static void DFISnapshot(void) {
    if (!DFIActive) return;
    NSString *process = NSProcessInfo.processInfo.processName;
    NSLog(@"[DuoFaceIndependent] snapshot process=%@ workspaceCaptured=%d workspaceHook=%d",
          process, DFIDashboardWorkspace != nil, DFIWorkspaceHookInstalled);
    DFILogClass(@"DBWorkspace", @[@"initWithOwner:", @"requestStateChange:", @"state"]);
    DFILogClass(@"DBDashboardWorkspaceOwner", @[]);
    DFILogClass(@"DBApplicationController", @[@"applicationWithBundleIdentifier:"]);
    DFILogClass(@"DBMutableWorkspaceStateChangeRequest", @[@"activateApplication:"]);
    DFILogClass(@"FBSceneManager", @[@"scenes", @"scenesIncludingInternal:"]);
    DFILogClass(@"SBApplicationController", @[@"applicationWithBundleIdentifier:"]);
    DFILogClass(@"SBMainDisplaySceneManager", @[@"scenes"]);
    DFILogClass(@"FBSScene", @[@"identifier", @"settings"]);
    DFILogClass(@"FBSceneHostView", @[@"initWithScene:"]);
    DFILogClass(@"DBDockWindow", @[]);
    DFILogClass(@"DBStatusBarWindow", @[]);
    DFILogClass(@"CARStatusBarWindow", @[]);

    // Dữ liệu kích thước màn hình ngoài; không đọc nội dung ứng dụng hay dữ liệu cá nhân.
    for (UIScreen *screen in [UIScreen screens]) {
        CGRect b = screen.bounds;
        NSLog(@"[DuoFaceIndependent] display bounds=(%.0f,%.0f,%.0f,%.0f) scale=%.2f",
              b.origin.x, b.origin.y, b.size.width, b.size.height, screen.scale);
    }
}

static id DFIWorkspaceInitWithOwner(id self, SEL cmd, id owner) {
    id workspace = DFIOriginalWorkspaceInit(self, cmd, owner);
    Class ownerClass = NSClassFromString(@"DBDashboardWorkspaceOwner");
    if (ownerClass && [owner isKindOfClass:ownerClass]) {
        DFIDashboardWorkspace = workspace;
        NSLog(@"[DuoFaceIndependent] dashboard workspace observed; owner=%@",
              NSStringFromClass(object_getClass(owner)));
    }
    return workspace;
}

static void DFIInstallWorkspaceObservation(void) {
    if (!DFIActive || DFIWorkspaceHookInstalled ||
        ![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"]) return;
    Class workspace = NSClassFromString(@"DBWorkspace");
    SEL sel = @selector(initWithOwner:);
    Method method = workspace ? class_getInstanceMethod(workspace, sel) : NULL;
    if (!method || method_getNumberOfArguments(method) != 3) return;
    DFIHookMessageEx installer = (DFIHookMessageEx)dlsym(RTLD_DEFAULT, "MSHookMessageEx");
    if (!installer) {
        NSLog(@"[DuoFaceIndependent] hook engine unavailable; continuing read-only");
        return;
    }
    installer(workspace, sel, (IMP)DFIWorkspaceInitWithOwner,
              (IMP *)&DFIOriginalWorkspaceInit);
    DFIWorkspaceHookInstalled = (DFIOriginalWorkspaceInit != NULL);
    NSLog(@"[DuoFaceIndependent] observation installed=%d", DFIWorkspaceHookInstalled);
}

static void DFIImageLoaded(const struct mach_header *header) {
    (void)header;
    if (!DFIActive) return;
    // Cài quan sát ngay khi class xuất hiện; không gọi phương thức tạo cửa sổ.
    DFIInstallWorkspaceObservation();
}

__attribute__((constructor)) static void DFIInitializeProbe(void) {
    @autoreleasepool {
        if (!DFIIsTargetProcess()) return;
        if (![[NSFileManager defaultManager] fileExistsAtPath:DFIEnabledFile]) return;
        DFIActive = YES;
        DFIInstallWorkspaceObservation();
        objc_addLoadImageFunc(DFIImageLoaded);
        int result = notify_register_dispatch(DFISnapshotEvent, &DFINotificationToken,
                                              dispatch_get_main_queue(), ^(int token) {
            (void)token;
            DFIInstallWorkspaceObservation();
            DFISnapshot();
        });
        if (result != NOTIFY_STATUS_OK) {
            NSLog(@"[DuoFaceIndependent] notification registration failed=%d", result);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ DFISnapshot(); });
    }
}
