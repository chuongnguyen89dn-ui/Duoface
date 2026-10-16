// DuoFace CarPlay direct Add App — source fix after native15 device QA.
// Keep the native Add App tile, but NEVER call the old stop-car/iPhone-only
// modal. Open a CarPlay picker for valid choices or show a scoped in-car
// explanation when native storage/providers cannot yet be validated.
// This change never patches the native12 Dashboard/activation implementation.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface NSObject (DFInstalledAppInfo)
+ (id)defaultWorkspace;
- (NSArray *)allInstalledApplications;
- (NSString *)applicationIdentifier;
- (NSString *)localizedName;
- (NSString *)applicationType;
@end

@interface CBDashboardSettings : NSObject
+ (instancetype)sharedInstance;
- (NSArray<NSString *> *)bridgedApps;
- (void)reload;
@end

@interface CBBridgeManager : NSObject
+ (instancetype)sharedInstanceIfExists;
- (void)handleSettingsChanged;
@end

@interface CBMultitaskingOverlayView : UIView
- (void)switchToAppPickerMode;
@end

static const NSInteger kDFInCarModalTag=0x0DFA0023;
static NSString *const kDFBridgedAppsKey=@"bridgedApps";
static NSString *const kDFPrefsDirectory=@"/var/mobile/Library/Preferences";
static BOOL DFPickerValidBundle(NSString *bid) {
    if (![bid isKindOfClass:NSString.class] || bid.length<3 || bid.length>255 ||
        ![bid containsString:@"."] || [bid containsString:@".."]) return NO;
    NSCharacterSet *allow=[NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_"];
    return [bid rangeOfCharacterFromSet:allow.invertedSet].location==NSNotFound;
}
static NSArray<NSString *> *DFValidStringApps(id value) {
    if (![value isKindOfClass:NSArray.class]) return nil;
    NSMutableArray<NSString *> *result=[NSMutableArray array];
    NSMutableSet<NSString *> *seen=[NSMutableSet set];
    for (id item in value) {
        if (!DFPickerValidBundle(item)) return nil;
        if ([seen containsObject:item]) return nil;
        [seen addObject:item]; [result addObject:item];
    }
    return [result copy];
}
static BOOL DFListEqual(NSArray *a,NSArray *b) {
    // Original preference array order is meaningful: never sort or replace it.
    return a && b && [a isEqualToArray:b];
}
static NSString *DFExistingSettingsFileForList(NSArray<NSString *> *current) {
    // Discover, DO NOT GUESS, the existing Preferences backing file. Never
    // create a second app list. Reject ambiguous files and mismatch versions.
    if (!DFValidStringApps(current)) return nil;
    NSArray<NSString *> *names=[[NSFileManager defaultManager]
                 contentsOfDirectoryAtPath:kDFPrefsDirectory error:nil];
    if (!names || names.count>2000) return nil;
    NSString *match=nil;
    for (NSString *name in names) {
        // Native12 Dashboard.reloadAppPrefs reads BOTH appSettings and
        // bridgedApps from the same original preferences NSDictionary
        // (direct disassembly at 0x375c0 and 0x3764c). Its preference filename
        // is a lazy runtime value; do not guess a small list of domain names.
        // Inspect existing PLISTs read-only, reject non-native schema and
        // ambiguous matching domains. Never create a second preference file.
        if (![name hasSuffix:@".plist"]) continue;
        NSString *path=[kDFPrefsDirectory stringByAppendingPathComponent:name];
        NSDictionary *dict=[NSDictionary dictionaryWithContentsOfFile:path];
        if (![dict isKindOfClass:NSDictionary.class] ||
            ![dict[@"appSettings"] isKindOfClass:NSDictionary.class] ||
            !dict[kDFBridgedAppsKey]) continue;
        NSArray *saved=DFValidStringApps(dict[kDFBridgedAppsKey]);
        if (!DFListEqual(saved,current)) continue;
        if (match) return nil; // ambiguity: user must not risk writing wrong.
        match=path;
    }
    return match;
}
static NSArray<NSDictionary *> *DFEligibleApps(NSArray<NSString *> *already) {
    Class cls=NSClassFromString(@"LSApplicationWorkspace");
    if (!cls || ![cls respondsToSelector:@selector(defaultWorkspace)]) return nil;
    id work=[cls defaultWorkspace];
    if (!work || ![work respondsToSelector:@selector(allInstalledApplications)])
        return nil;
    NSArray *installed=[work allInstalledApplications];
    if (![installed isKindOfClass:NSArray.class]) return nil;
    NSSet *selected=[NSSet setWithArray:already];
    NSMutableDictionary<NSString *,NSDictionary *> *unique=[NSMutableDictionary dictionary];
    for (id proxy in installed) {
        if (![proxy respondsToSelector:@selector(applicationIdentifier)] ||
            ![proxy respondsToSelector:@selector(localizedName)]) continue;
        NSString *bid=[proxy applicationIdentifier];
        NSString *name=[proxy localizedName];
        if (!DFPickerValidBundle(bid) || [selected containsObject:bid] ||
            ![name isKindOfClass:NSString.class] || !name.length ||
            [bid hasPrefix:@"com.apple."] || [bid hasPrefix:@"com.duoface."] ||
            [bid hasPrefix:@"com.duonavi."]) continue;
        if ([proxy respondsToSelector:@selector(applicationType)]) {
            id kind=[proxy applicationType];
            if ([kind isKindOfClass:NSString.class] && ![kind isEqualToString:@"User"])
                continue;
        }
        unique[bid]=@{@"bundle":bid,@"title":name};
    }
    return [[unique allValues] sortedArrayUsingComparator:
        ^NSComparisonResult(NSDictionary *a,NSDictionary *b) {
            NSComparisonResult x=[a[@"title"] localizedCaseInsensitiveCompare:b[@"title"]];
            return x==NSOrderedSame ? [a[@"bundle"] compare:b[@"bundle"]] : x;
        }];
}
static BOOL DFSaveToNativePreferences(NSString *file,NSArray *expected,
                                     NSString *bundle,NSString **failure) {
    if (!file.length || !DFPickerValidBundle(bundle)) {
        if (failure) *failure=@"Không tìm thấy cấu hình ứng dụng gốc.";
        return NO;
    }
    NSDictionary *before=[NSDictionary dictionaryWithContentsOfFile:file];
    NSArray *live=DFValidStringApps(before[kDFBridgedAppsKey]);
    if (!DFListEqual(live,expected)) {
        if (failure) *failure=@"Danh sách vừa thay đổi, vui lòng mở lại.";
        return NO;
    }
    if ([live containsObject:bundle]) return YES; // idempotent
    NSMutableDictionary *changed=[before mutableCopy];
    NSMutableArray *next=[live mutableCopy];
    [next addObject:bundle];
    changed[kDFBridgedAppsKey]=[next copy];
    if (![changed writeToFile:file atomically:YES]) {
        if (failure) *failure=@"Không thể lưu cấu hình trên iPhone.";
        return NO;
    }
    CBDashboardSettings *settings=[NSClassFromString(@"CBDashboardSettings") sharedInstance];
    if (![settings respondsToSelector:@selector(reload)]) {
        [before writeToFile:file atomically:YES];
        if (failure) *failure=@"Không tìm thấy bộ quản lý DuoFace.";
        return NO;
    }
    [settings reload];
    NSArray *updated=DFValidStringApps([settings bridgedApps]);
    if (!DFListEqual(updated,next)) {
        [before writeToFile:file atomically:YES];
        [settings reload]; // rollback persistent+in-memory state together
        if (failure) *failure=@"DuoFace không nhận danh sách mới; đã hoàn tác.";
        return NO;
    }
    CBBridgeManager *manager=[NSClassFromString(@"CBBridgeManager") sharedInstanceIfExists];
    if ([manager respondsToSelector:@selector(handleSettingsChanged)])
        [manager handleSettingsChanged];
    return YES;
}
@interface DFInCarAppPicker : UIView <UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,weak) CBMultitaskingOverlayView *host;
@property(nonatomic,copy) NSString *prefsFile;
@property(nonatomic,copy) NSArray<NSString *> *snapshot;
@property(nonatomic,copy) NSArray<NSDictionary *> *choices;
@property(nonatomic,strong) UITableView *table;
@property(nonatomic,strong) UILabel *status;
- (instancetype)initWithHost:(CBMultitaskingOverlayView *)host
                       file:(NSString *)file current:(NSArray *)current
                    choices:(NSArray *)choices diagnostic:(NSString *)diagnostic;
- (void)dismiss;
@end
@implementation DFInCarAppPicker
- (instancetype)initWithHost:(CBMultitaskingOverlayView *)host
                       file:(NSString *)file current:(NSArray *)current
                    choices:(NSArray *)choices diagnostic:(NSString *)diagnostic {
    self=[super initWithFrame:host.bounds];
    if (!self) return nil;
    _host=host;_prefsFile=[file copy];_snapshot=[current copy];_choices=[choices copy];
    self.tag=kDFInCarModalTag;
    self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.backgroundColor=[[UIColor blackColor] colorWithAlphaComponent:0.82];
    UIView *panel=[[UIView alloc] initWithFrame:CGRectInset(self.bounds,18,18)];
    panel.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    panel.layer.cornerRadius=14;
    panel.layer.masksToBounds=YES;
    panel.backgroundColor=[UIColor colorWithWhite:0.12 alpha:0.99];
    [self addSubview:panel];
    UIButton *cancel=[UIButton buttonWithType:UIButtonTypeSystem];
    [cancel setTitle:@"Hủy" forState:UIControlStateNormal];
    cancel.frame=CGRectMake(8,4,64,40);
    [cancel addTarget:self action:@selector(dismiss)
      forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:cancel];
    UILabel *title=[[UILabel alloc] initWithFrame:CGRectMake(76,4,
                            MAX(80,panel.bounds.size.width-154),40)];
    title.autoresizingMask=UIViewAutoresizingFlexibleWidth;
    title.textAlignment=NSTextAlignmentCenter;
    title.textColor=UIColor.whiteColor;
    title.font=[UIFont boldSystemFontOfSize:16];
    title.text=@"Thêm ứng dụng";
    [panel addSubview:title];
    UILabel *status=[[UILabel alloc] initWithFrame:CGRectMake(10,
                      panel.bounds.size.height-34,panel.bounds.size.width-20,28)];
    status.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    status.font=[UIFont systemFontOfSize:12];
    status.numberOfLines=2;
    status.adjustsFontSizeToFitWidth=YES;
    status.textColor=UIColor.lightGrayColor;
    status.textAlignment=NSTextAlignmentCenter;
    status.text=diagnostic.length ? diagnostic : @"Chạm để thêm vào DuoFace";
    [panel addSubview:status];_status=status;
    UITableView *table=[[UITableView alloc] initWithFrame:CGRectMake(0,46,
                      panel.bounds.size.width,MAX(55,panel.bounds.size.height-82))
                      style:UITableViewStylePlain];
    table.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    table.dataSource=self;table.delegate=self;table.rowHeight=50;
    table.backgroundColor=UIColor.clearColor;
    [panel addSubview:table];_table=table;
    return self;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;(void)section;return self.choices.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ident=@"DFInCarInstalledApp";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:ident];
    if (!cell) cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                            reuseIdentifier:ident];
    NSDictionary *entry=self.choices[(NSUInteger)indexPath.row];
    cell.textLabel.text=entry[@"title"];
    cell.textLabel.font=[UIFont systemFontOfSize:14];
    cell.textLabel.textColor=UIColor.whiteColor;
    cell.detailTextLabel.text=entry[@"bundle"];
    cell.detailTextLabel.textColor=UIColor.lightGrayColor;
    cell.detailTextLabel.font=[UIFont systemFontOfSize:10];
    cell.backgroundColor=UIColor.clearColor;
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ((NSUInteger)indexPath.row>=self.choices.count) return;
    if (!self.prefsFile.length || !self.snapshot) {
        self.status.text=@"Chưa xác minh được tệp cấu hình gốc; không ghi dữ liệu.";
        NSLog(@"[DuoFaceInCarAddApps] save skipped: original preferences owner unverified");
        return;
    }
    NSString *bundle=self.choices[(NSUInteger)indexPath.row][@"bundle"];
    NSString *error=nil;
    BOOL ok=DFSaveToNativePreferences(self.prefsFile,self.snapshot,bundle,&error);
    if (!ok) {self.status.text=error?:@"Không thể thêm ứng dụng.";return;}
    NSLog(@"[DuoFace] CarPlay Add App saved (bundle-id redacted)");
    [self dismiss];
    // Original native picker owns its app cards, hit areas and split layout.
    // A reload of its original app-picker mode makes the new app selectable.
    [self.host switchToAppPickerMode];
}
- (void)dismiss {
    [self removeFromSuperview];
}
@end

%group DFInCarPicker
%hook CBMultitaskingOverlayView
- (void)addMoreAppsTapped:(id)sender {
    // THE ORIGINAL HANDLER SHOWS THE OBSOLETE "PARK SAFELY / OPEN IPHONE"
    // MODAL. It MUST NOT be invoked here on any success or failure branch.
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addMoreAppsTapped:sender];
        });
        return;
    }
    if ([self viewWithTag:kDFInCarModalTag]) return;

    Class settingsClass=NSClassFromString(@"CBDashboardSettings");
    CBDashboardSettings *settings=nil;
    if (settingsClass && [settingsClass respondsToSelector:@selector(sharedInstance)])
        settings=[settingsClass sharedInstance];
    NSArray *selected=settings ? DFValidStringApps([settings bridgedApps]) : nil;
    NSString *prefs=selected ? DFExistingSettingsFileForList(selected) : nil;
    NSArray *choices=DFEligibleApps(selected?:@[]);
    NSString *diagnostic=nil;
    if (!settings || !selected) {
        diagnostic=@"Chưa đọc được danh sách DuoFace gốc trên CarPlay.";
        NSLog(@"[DuoFaceInCarAddApps] in-car status: settings/current list unavailable");
    } else if (!prefs) {
        diagnostic=@"Chưa xác minh tệp lưu chung với iPhone; chưa thể thêm.";
        NSLog(@"[DuoFaceInCarAddApps] in-car status: shared settings file missing or ambiguous");
    } else if (!choices) {
        diagnostic=@"Chưa lấy được danh sách ứng dụng iPhone.";
        NSLog(@"[DuoFaceInCarAddApps] in-car status: installed apps provider unavailable");
    } else if (choices.count==0) {
        diagnostic=@"Không còn ứng dụng phù hợp để thêm.";
        NSLog(@"[DuoFaceInCarAddApps] in-car status: no eligible unbridged apps");
    }
    DFInCarAppPicker *picker=[[DFInCarAppPicker alloc]
        initWithHost:self file:prefs current:selected
        choices:choices?:@[] diagnostic:diagnostic];
    [self addSubview:picker];
    [self bringSubviewToFront:picker];
    NSLog(@"[DuoFaceInCarAddApps] in-car sheet shown; choices=%lu verified-storage=%@",
          (unsigned long)choices.count, prefs?@"yes":@"no");
}
%end
%end

static BOOL DFPickerHookInstalled=NO;
static BOOL DFPickerAllowedHost(void) {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    NSString *process=NSProcessInfo.processInfo.processName.lowercaseString;
    NSSet *bundleAllow=[NSSet setWithArray:@[
        @"com.apple.springboard",@"com.apple.carplay",@"com.apple.carplayapp",
        @"com.apple.dashboard"]];
    NSSet *processAllow=[NSSet setWithArray:@[
        @"springboard",@"carplay",@"carplayapp",@"dashboard"]];
    return [bundleAllow containsObject:bundle] || [processAllow containsObject:process];
}
static void DFInstallPickerOnce(void) {
    if (DFPickerHookInstalled || !DFPickerAllowedHost()) return;
    // DuoFaceDashboard may be injected only once CarPlay is activated. A
    // one-time SpringBoard constructor probe silently missed this class.
    if (!NSClassFromString(@"CBMultitaskingOverlayView")) return;
    %init(DFInCarPicker);
    DFPickerHookInstalled=YES;
    NSLog(@"[DuoFaceInCarAddApps] Hook active in CarPlay host.");
}
static void DFInstallPickerEventually(void) {
    if (DFPickerHookInstalled || !DFPickerAllowedHost()) return;
    DFInstallPickerOnce();
    if (!DFPickerHookInstalled) {
        // Only one pending low-frequency probe; harmless if CarPlay attaches
        // much later after device boot. Stop immediately after %init succeeds.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5*NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            DFInstallPickerEventually();
        });
    }
}
__attribute__((constructor)) static void DFInstallDirectAddApp(void) {
    @autoreleasepool {
        if (!DFPickerAllowedHost()) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DFInstallPickerEventually();
        });
    }
}
