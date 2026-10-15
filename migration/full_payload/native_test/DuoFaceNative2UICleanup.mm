// DuoFace Mới native2: remove obsolete date/activation UI from original
// app SETTINGS only. Preserve original Dashboard, CarPlay picker/split/Zoom
// and every visual asset untouched. Removable/rollback test module.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <string.h>

static NSInteger (*DFIOriginalSettingsRows)(id,SEL,UITableView *,NSInteger)=NULL;
static UITableViewCell *(*DFIOriginalSettingsCell)(id,SEL,UITableView *,NSIndexPath *)=NULL;
static void (*DFIOriginalSettingsSelect)(id,SEL,UITableView *,NSIndexPath *)=NULL;
static NSMutableSet<NSString *> *DFIHiddenLicenseRowKeys;
static BOOL DFIUIFilterInstalled=NO;
static BOOL DFIUIFiltering=NO;

static void DFIUIInfo(NSString *message) {
    NSLog(@"[DuoFaceNative2UI] %@",message);
}
static void DFINoExpiredDialog(id self,SEL cmd) { (void)self;(void)cmd; }
static void DFINoSubscriptionNavigation(id self,SEL cmd) { (void)self;(void)cmd; }

static BOOL DFISettingsIsLicenseText(NSString *source) {
    if(![source isKindOfClass:NSString.class] || !source.length)return NO;
    NSString *s=source.lowercaseString;
    // Exact subscription/expiration terms; do not suppress normal CarPlay
    // status, DuoFace Team, language, springboard, or other setting rows.
    NSArray<NSString *> *terms=@[
        @"duoface pro", @"subscription", @"license", @"licence",
        @"giấy phép", @"thời hạn", @"ngày sử dụng", @"hạn dùng",
        @"suscripción", @"licencia", @"abonnement", @"licentie",
        @"licencja", @"lizen", @"einddatum"
    ];
    for(NSString *term in terms)
        if([s containsString:term])return YES;
    return NO;
}
static BOOL DFISettingsCellIsLicense(UITableViewCell *cell) {
    if(![cell isKindOfClass:UITableViewCell.class])return NO;
    if(DFISettingsIsLicenseText(cell.textLabel.text) ||
       DFISettingsIsLicenseText(cell.detailTextLabel.text))return YES;
    NSString *className=NSStringFromClass(cell.class).lowercaseString;
    if([className containsString:@"subscription"] ||
       [className containsString:@"license"])return YES;
    return NO;
}
static NSArray<NSNumber *> *DFISettingsOriginalVisibleRows(id owner,UITableView *table,NSInteger section) {
    NSInteger total=DFIOriginalSettingsRows(owner,@selector(tableView:numberOfRowsInSection:),table,section);
    if(total<=0 || total>60 || !DFIOriginalSettingsCell || DFIUIFiltering) {
        NSMutableArray *all=[NSMutableArray array];
        for(NSInteger i=0;i<MAX(0,MIN(total,60));i++)[all addObject:@(i)];
        return all;
    }
    DFIUIFiltering=YES;
    NSMutableArray<NSNumber *> *visible=[NSMutableArray array];
    for(NSInteger i=0;i<total;i++) {
        NSIndexPath *originalPath=[NSIndexPath indexPathForRow:i inSection:section];
        UITableViewCell *cell=nil;
        @try {
            cell=DFIOriginalSettingsCell(owner,@selector(tableView:cellForRowAtIndexPath:),
                                         table,originalPath);
        } @catch(NSException *exception) {
            DFIUIInfo([NSString stringWithFormat:@"original cell inspect failed; preserve section=%ld, row=%ld (%@)",
                       (long)section,(long)i,exception.name]);
            [visible removeAllObjects];
            for(NSInteger x=0;x<total;x++)[visible addObject:@(x)];
            break;
        }
        if(DFISettingsCellIsLicense(cell)) {
            NSString *key=[NSString stringWithFormat:@"%ld:%ld",(long)section,(long)i];
            if(![DFIHiddenLicenseRowKeys containsObject:key]) {
                [DFIHiddenLicenseRowKeys addObject:key];
                DFIUIInfo([NSString stringWithFormat:@"HIDE obsolete subscription row %@",key]);
            }
            continue;
        }
        [visible addObject:@(i)];
    }
    DFIUIFiltering=NO;
    return visible;
}
static NSInteger DFISettingsRows(id self,SEL cmd,UITableView *table,NSInteger section) {
    if(!DFIOriginalSettingsRows)return 0;
    if(![NSThread isMainThread] || DFIUIFiltering)
        return DFIOriginalSettingsRows(self,cmd,table,section);
    return DFISettingsOriginalVisibleRows(self,table,section).count;
}
static NSIndexPath *DFIMappedPath(id self,UITableView *table,NSIndexPath *visiblePath) {
    if(!visiblePath || visiblePath.section<0 || visiblePath.row<0)return visiblePath;
    NSArray<NSNumber *> *indices=DFISettingsOriginalVisibleRows(self,table,visiblePath.section);
    if(visiblePath.row>=indices.count)return nil;
    return [NSIndexPath indexPathForRow:indices[visiblePath.row].integerValue
                             inSection:visiblePath.section];
}
static UITableViewCell *DFISettingsCell(id self,SEL cmd,UITableView *table,NSIndexPath *indexPath) {
    NSIndexPath *original=DFIMappedPath(self,table,indexPath);
    if(!original) {
        DFIUIInfo(@"Out-of-bounds filtered row; safe empty cell");
        return [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    return DFIOriginalSettingsCell(self,cmd,table,original);
}
static void DFISettingsSelect(id self,SEL cmd,UITableView *table,NSIndexPath *indexPath) {
    NSIndexPath *original=DFIMappedPath(self,table,indexPath);
    if(original && DFIOriginalSettingsSelect)
        DFIOriginalSettingsSelect(self,cmd,table,original);
}
static BOOL DFIInstallSimpleNoOp(Class cls,SEL sel,IMP replacement) {
    if(!cls)return NO;
    Method method=class_getInstanceMethod(cls,sel);
    if(!method)return NO;
    NSMethodSignature *sig=[NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    if(!sig || sig.numberOfArguments!=2 || sig.methodReturnType[0]!='v')return NO;
    method_setImplementation(method,replacement);
    DFIUIInfo([NSString stringWithFormat:@"disabled obsolete UI action %@[%@ %@]",
               @"-",NSStringFromClass(cls),NSStringFromSelector(sel)]);
    return YES;
}
static void DFIInstallNative2UI(void) {
    if(DFIUIFilterInstalled)return;
    Class settings=NSClassFromString(@"CBGeneralSettingsViewController");
    Class root=NSClassFromString(@"XXRootViewController");
    if(!settings || !root)return;
    const SEL rows=@selector(tableView:numberOfRowsInSection:);
    const SEL cells=@selector(tableView:cellForRowAtIndexPath:);
    const SEL select=@selector(tableView:didSelectRowAtIndexPath:);
    Method mRows=class_getInstanceMethod(settings,rows);
    Method mCells=class_getInstanceMethod(settings,cells);
    Method mSelect=class_getInstanceMethod(settings,select);
    if(!mRows || !mCells || !mSelect)return;
    NSMethodSignature *rs=[NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(mRows)];
    NSMethodSignature *cs=[NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(mCells)];
    NSMethodSignature *ss=[NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(mSelect)];
    if(!rs || !cs || !ss || rs.numberOfArguments!=4 ||
       cs.numberOfArguments!=4 || ss.numberOfArguments!=4 ||
       !strchr("qi",rs.methodReturnType[0]) ||
       cs.methodReturnType[0]!='@' || ss.methodReturnType[0]!='v') {
        DFIUIInfo(@"Original settings ABI mismatch; preserve unmodified behavior");
        return;
    }
    DFIHiddenLicenseRowKeys=[NSMutableSet new];
    DFIOriginalSettingsRows=(decltype(DFIOriginalSettingsRows))method_getImplementation(mRows);
    DFIOriginalSettingsCell=(decltype(DFIOriginalSettingsCell))method_getImplementation(mCells);
    DFIOriginalSettingsSelect=(decltype(DFIOriginalSettingsSelect))method_getImplementation(mSelect);
    method_setImplementation(mRows,(IMP)DFISettingsRows);
    method_setImplementation(mCells,(IMP)DFISettingsCell);
    method_setImplementation(mSelect,(IMP)DFISettingsSelect);
    DFIInstallSimpleNoOp(settings,@selector(openSubscriptionScreen),(IMP)DFINoSubscriptionNavigation);
    DFIInstallSimpleNoOp(root,@selector(checkAndPresentLicenseModalIfNeeded),(IMP)DFINoExpiredDialog);
    DFIUIFilterInstalled=YES;
    DFIUIInfo(@"native2 settings-only cleanup installed; CarPlay native rendering untouched");
}
__attribute__((constructor)) static void DFIStartNative2SettingsCleanup(void) {
    @autoreleasepool {
        NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
        // Never touch SpringBoard/CarPlay/Dashboard or another iPhone app.
        if(![bundle isEqualToString:@"com.duoface.duofaceui"])return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DFIInstallNative2UI();
            [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer) {
                if(DFIUIFilterInstalled){[timer invalidate];return;}
                static NSUInteger attempts=0;
                if(++attempts>=100){[timer invalidate];DFIUIInfo(@"Settings class unavailable, no changes applied");return;}
                DFIInstallNative2UI();
            }];
        });
    }
}
