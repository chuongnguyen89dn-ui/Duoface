// Adapter Zoom cho lõi riêng. Bản cũ dùng CBWindow -> KHÔNG mang dependency đó qua.
// Chỉ ẩn chrome CarPlay đã quan sát, giữ nguyên trạng thái gốc để khôi phục khi thoát.
// Phải kiểm tra trên iPhone thật trước khi tuyên bố Zoom tương đương bản cũ.
static NSMapTable<UIWindow *, NSNumber *> *DFIChromeBefore;
static BOOL DFIChromeWasZoomed = NO;
static BOOL DFIChromeInstalled = NO;
static int DFIChromePreferenceToken = 0;

static BOOL DFIChromeZoomRequested(void) {
    return [DFIPreference(@"zoomEnabled") boolValue];
}
static void DFIChromeSetZoom(BOOL enabled) {
    DFIWritePreference(@"zoomEnabled", @(enabled));
    notify_post(DFIChanged);
}
static BOOL DFIChromeTargetWindow(UIWindow *window) {
    if(![window isKindOfClass:UIWindow.class])return NO;
    NSString *name=NSStringFromClass(object_getClass(window));
    // Đừng động vào UI của app riêng; chỉ điều khiển statusbar/dock CarPlay.
    return [@[@"DBStatusBarWindow",@"CARStatusBarWindow",@"DBDockWindow"]
            containsObject:name];
}
static void DFIChromeRestore(void) {
    if(!DFIChromeBefore)return;
    for(UIWindow *window in DFIChromeBefore.keyEnumerator){
        NSNumber *wasHidden=[DFIChromeBefore objectForKey:window];
        if(wasHidden)window.hidden=wasHidden.boolValue;
    }
    [DFIChromeBefore removeAllObjects];
}
static void DFIChromeApply(void) {
    if(![NSThread isMainThread])return;
    BOOL wanted=DFIChromeZoomRequested();
    if(!wanted){
        if(DFIChromeWasZoomed)DFIChromeRestore();
        DFIChromeWasZoomed=NO;
        return;
    }
    if(!DFIChromeBefore)DFIChromeBefore=[NSMapTable weakToStrongObjectsMapTable];
    NSUInteger found=0;
    for(UIWindow *window in UIApplication.sharedApplication.windows){
        if(!DFIChromeTargetWindow(window))continue;
        found++;
        if(![DFIChromeBefore objectForKey:window])
            [DFIChromeBefore setObject:@(window.hidden) forKey:window];
        window.hidden=YES;
    }
    if(!DFIChromeWasZoomed)
        DFILog([NSString stringWithFormat:@"DuoFace zoom requested; native CarPlay chrome windows=%lu",
                (unsigned long)found]);
    DFIChromeWasZoomed=YES;
}
static void DFIChromeInstall(void) {
    if(DFIChromeInstalled)return;
    DFIChromeInstalled=YES;
    notify_register_dispatch(DFIChanged,&DFIChromePreferenceToken,
                             dispatch_get_main_queue(),^(int token){DFIChromeApply();});
    // CarPlay thay thế cửa sổ status/dock động; phát hiện và phục hồi đúng trạng thái.
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES
            block:^(NSTimer *timer){DFIChromeApply();}];
    DFIChromeApply();
}
