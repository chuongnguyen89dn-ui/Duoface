// Source-staged iPhone DuoFaceUI Settings extension; not deployed.
// Extends the original native12 CBGeneralSettingsViewController table by
// ONE section/row. Preserves its old Auto Start switch and all section indexes.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString *const kDFSettingsSuite = @"com.duoface.smartconnection";
static NSString *const kDFDisconnectCloseKey = @"closeOnCarPlayDisconnect";

static NSUInteger DFNativeSectionCount(id controller, UITableView *tableView) {
    // Call the hooked numberOfSections method, subtract our single appended
    // section. No hardcoded index: original sections can change with language.
    NSInteger all = (NSInteger)[controller numberOfSectionsInTableView:tableView];
    return (NSUInteger)(all>0 ? all-1 : 0);
}
static NSUserDefaults *DFConnectionSettingsStore(void) {
    return [[NSUserDefaults alloc] initWithSuiteName:kDFSettingsSuite];
}
%hook CBGeneralSettingsViewController
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger native=%orig;
    return native>=0 ? native+1 : native;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ((NSUInteger)section==DFNativeSectionCount(self,tableView)) return 1;
    return %orig;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ((NSUInteger)section==DFNativeSectionCount(self,tableView))
        return @"KẾT NỐI CARPLAY";
    return %orig;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((NSUInteger)indexPath.section!=DFNativeSectionCount(self,tableView))
        return %orig;
    static NSString *identifier=@"DFCloseOnDisconnectCell";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:identifier];
    cell.textLabel.text=@"Đóng ứng dụng khi ngắt CarPlay";
    cell.detailTextLabel.text=@"Chờ 10 giây; kết nối lại sẽ hủy";
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    UISwitch *toggle=[UISwitch new];
    toggle.on=[DFConnectionSettingsStore() boolForKey:kDFDisconnectCloseKey];
    [toggle addTarget:self action:@selector(dfCloseOnDisconnectChanged:)
     forControlEvents:UIControlEventValueChanged];
    cell.accessoryView=toggle;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((NSUInteger)indexPath.section==DFNativeSectionCount(self,tableView)) return;
    %orig;
}
%new
- (void)dfCloseOnDisconnectChanged:(UISwitch *)sender {
    if (![sender isKindOfClass:UISwitch.class]) return;
    NSUserDefaults *prefs=DFConnectionSettingsStore();
    [prefs setBool:sender.on forKey:kDFDisconnectCloseKey];
    // Other process reads suite value at event time and after the grace
    // period; no command to force close or respring is sent from the UI.
}
%end
