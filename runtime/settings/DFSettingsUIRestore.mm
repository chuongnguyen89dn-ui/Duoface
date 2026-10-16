// DuoFace native17: restore only the settings-row presentation lost when the
// combined native2 NoLease dylib was removed in the known-working native12.
// Intentionally NO license validity hooks, watchdog hooks, or activation changes.
// The host binary remains byte-identical to native12 and native16.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <string.h>

static NSInteger (*DFOrigRows)(id, SEL, UITableView *, NSInteger)=NULL;
static UITableViewCell *(*DFOrigCell)(id, SEL, UITableView *, NSIndexPath *)=NULL;
static void (*DFOrigSelect)(id, SEL, UITableView *, NSIndexPath *)=NULL;
static BOOL DFInstalled=NO;
static BOOL DFInspecting=NO;

static BOOL DFIsObsoleteLicenseRow(UITableViewCell *cell) {
    if (![cell isKindOfClass:UITableViewCell.class]) return NO;
    // The same iPhone-only terms as the user-verified native2 row filter.
    NSArray *terms=@[@"duoface pro", @"subscription", @"license", @"licence",
        @"giấy phép", @"thời hạn", @"ngày sử dụng", @"hạn dùng",
        @"suscripción", @"licencia", @"abonnement", @"licentie",
        @"licencja", @"lizen", @"einddatum"];
    for (id candidate in @[cell.textLabel.text?:@"", cell.detailTextLabel.text?:@""]) {
        if (![candidate isKindOfClass:NSString.class]) continue;
        NSString *s=[candidate lowercaseString];
        for (NSString *term in terms) if ([s containsString:term]) return YES;
    }
    NSString *className=NSStringFromClass(cell.class).lowercaseString;
    return [className containsString:@"subscription"] ||
           [className containsString:@"license"];
}
static NSArray<NSNumber *> *DFVisibleOriginalRows(id owner, UITableView *table,
                                                    NSInteger section) {
    if (!DFOrigRows || !DFOrigCell || DFInspecting || !NSThread.isMainThread)
        return nil; // preserve original behavior when unsure
    NSInteger count=DFOrigRows(owner,@selector(tableView:numberOfRowsInSection:),table,section);
    if (count<0 || count>60) return nil;
    NSMutableArray<NSNumber *> *indices=[NSMutableArray array];
    DFInspecting=YES;
    @try {
        for (NSInteger i=0;i<count;i++) {
            NSIndexPath *p=[NSIndexPath indexPathForRow:i inSection:section];
            UITableViewCell *cell=DFOrigCell(owner,
                @selector(tableView:cellForRowAtIndexPath:),table,p);
            if (!DFIsObsoleteLicenseRow(cell)) [indices addObject:@(i)];
        }
    } @catch (NSException *exception) {
        // No half-filtered tables. Original callbacks stay installed.
        NSLog(@"[DuoFaceSettingsUIRestore] original-cell inspection failed (%@)",
              exception.name);
        return nil;
    } @finally {
        DFInspecting=NO;
    }
    return indices;
}
static NSIndexPath *DFOriginalIndexPath(id owner,UITableView *table,NSIndexPath *visible) {
    if (!visible || visible.section<0 || visible.row<0) return visible;
    NSArray<NSNumber *> *indices=DFVisibleOriginalRows(owner,table,visible.section);
    if (!indices) return visible; // fail open, don't rewrite unknown rows
    if (visible.row>=indices.count) return nil;
    return [NSIndexPath indexPathForRow:indices[(NSUInteger)visible.row].integerValue
                             inSection:visible.section];
}
static NSInteger DFVisibleCount(id self,SEL cmd,UITableView *table,NSInteger section) {
    NSInteger original=DFOrigRows(self,cmd,table,section);
    NSArray *indices=DFVisibleOriginalRows(self,table,section);
    return indices ? (NSInteger)indices.count : original;
}
static UITableViewCell *DFVisibleCell(id self,SEL cmd,UITableView *table,NSIndexPath *path) {
    NSIndexPath *original=DFOriginalIndexPath(self,table,path);
    if (!original) return [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    return DFOrigCell(self,cmd,table,original);
}
static void DFVisibleSelect(id self,SEL cmd,UITableView *table,NSIndexPath *path) {
    NSIndexPath *original=DFOriginalIndexPath(self,table,path);
    if (original && DFOrigSelect) DFOrigSelect(self,cmd,table,original);
}
static BOOL DFMethodABI(Method method,NSUInteger argc,char expected) {
    if (!method) return NO;
    const char *enc=method_getTypeEncoding(method);
    NSMethodSignature *signature=enc?[NSMethodSignature signatureWithObjCTypes:enc]:nil;
    if (!signature || signature.numberOfArguments!=argc) return NO;
    char actual=signature.methodReturnType[0];
    return expected=='q' ? (actual=='q'||actual=='i') : actual==expected;
}
static void DFInstallSettingsUIOnly(void) {
    if (DFInstalled || !NSThread.isMainThread) return;
    Class settings=NSClassFromString(@"CBGeneralSettingsViewController");
    if (!settings) return;
    Method rows=class_getInstanceMethod(settings,@selector(tableView:numberOfRowsInSection:));
    Method cells=class_getInstanceMethod(settings,@selector(tableView:cellForRowAtIndexPath:));
    Method select=class_getInstanceMethod(settings,@selector(tableView:didSelectRowAtIndexPath:));
    if (!DFMethodABI(rows,4,'q') || !DFMethodABI(cells,4,'@') ||
        !DFMethodABI(select,4,'v')) return;

    // Wrapping whatever callback is CURRENTLY registered also preserves the
    // separately injected SmartConnection 10-second section when present.
    DFOrigRows=(decltype(DFOrigRows))method_getImplementation(rows);
    DFOrigCell=(decltype(DFOrigCell))method_getImplementation(cells);
    DFOrigSelect=(decltype(DFOrigSelect))method_getImplementation(select);
    if (!DFOrigRows || !DFOrigCell || !DFOrigSelect) return;
    method_setImplementation(rows,(IMP)DFVisibleCount);
    method_setImplementation(cells,(IMP)DFVisibleCell);
    method_setImplementation(select,(IMP)DFVisibleSelect);
    DFInstalled=YES;
    NSLog(@"[DuoFaceSettingsUIRestore] native2 settings-row filter restored; license behavior untouched");
}
__attribute__((constructor)) static void DFStartSettingsUIOnly(void) {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier.lowercaseString
                isEqualToString:@"com.duoface.duofaceui"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DFInstallSettingsUIOnly();
            if (DFInstalled) return;
            __block NSUInteger attempts=0;
            [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer) {
                DFInstallSettingsUIOnly();
                if (DFInstalled || ++attempts>=120) [timer invalidate];
            }];
        });
    }
}
