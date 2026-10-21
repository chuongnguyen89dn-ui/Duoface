// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
#import "DFAppPickerVC.h"
#import "DFAppLibrary.h"

@interface DFAppPickerVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<DFAppInfo *> *apps;
@end

@implementation DFAppPickerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    _toolbar = [[UIToolbar alloc] init];
    _toolbar.barStyle = UIBarStyleBlack;
    UIBarButtonItem *title = [[UIBarButtonItem alloc]
        initWithTitle:@"Chọn app"
                style:UIBarButtonItemStylePlain
               target:nil action:nil];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                             target:nil action:nil];
    UIBarButtonItem *close = [[UIBarButtonItem alloc]
        initWithTitle:@"Đóng"
                style:UIBarButtonItemStyleDone
               target:self
               action:@selector(closeTapped)];
    _toolbar.items = @[title, spacer, close];
    [self.view addSubview:_toolbar];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                              style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor blackColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];

    // Đọc danh sách app trên background để không khựng UI.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray<DFAppInfo *> *apps = [DFAppLibrary installedUserApps];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.apps = apps;
            [self.tableView reloadData];
            NSLog(@"[DuoFace] App picker loaded %lu apps",
                  (unsigned long)apps.count);
        });
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    self.toolbar.frame = CGRectMake(0, 0, w, 64);
    self.tableView.frame = CGRectMake(0, 64, w, h - 64);
}

- (void)closeTapped {
    [self.delegate appPickerDidCancel:self];
}

#pragma mark - UITableViewDataSource / Delegate

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.apps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"AppCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:@"AppCell"];
        cell.backgroundColor = [UIColor blackColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    DFAppInfo *info = self.apps[indexPath.row];
    cell.textLabel.text = info.displayName;
    cell.detailTextLabel.text = info.bundleID;
    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DFAppInfo *info = self.apps[indexPath.row];
    [self.delegate appPicker:self
           didSelectBundleID:info.bundleID
                 displayName:info.displayName];
}

@end
