# 17/10/2026 — Speed6zProbe1: log thật xác nhận KHÔNG CÓ CBWindow owner trong tiến trình CarPlay

**Nguồn:** upload người dùng `DuoFaceSpeed6-CarPlayApp.jsonl` 33,190 bytes SHA256 `77de3a71aeda05ddcd5857230b08be5f63619b7f804f3d8ce169ed67bb909754`, 67 dòng JSONL đều hợp lệ. File bao gồm lịch sử **23 dòng cũ** (PID 53824), **44 dòng mới** (PID 54313); tuyệt đối không tính chúng thành 67 sự kiện mới.

## Kết quả phân tích bằng lệnh thật

`python - <<'PY'` (cwd default sandbox, reading `/mnt/data/DuoFaceSpeed6-CarPlayApp.jsonl`): parse từng JSONL với `json.loads`, `collections.Counter` đếm stage, lọc `stage=="PROBE_NATIVE_HOST"`, in `diagnostics` cho tất cả 29 probe, nhóm theo `(host_probe_reason,raw_active_window_class,dashboard_activated,hook_event_window_class)`. 67 valid, 0 parse error. Tổng stage cả cũ+mới: `PROBE_NATIVE_HOST` 29; `WAIT: CBBridgeManagerDashboard.activated=NO` 15; `UNMOUNTED: Dashboard bridgeDidDeactivate` 13; `WAIT: no visible activeCarPlayWindow/content/controller host` 6; `LOADED` 2; `HOOKED` 2.

**CHỈ lượt mới PID 54313**:
- 44 sự kiện mới, 29 `PROBE_NATIVE_HOST` trong thời gian UNIX `1792206458.2872` tới `1792206567.288492` (~109s). Constructor và lifecycle hook đã nạp thành công theo 1 `LOADED` + 1 `HOOKED` tương ứng.
- Mọi `PROBE_NATIVE_HOST` đều `class_cb_present=true`, `class_dashboard_present=true`, nhưng `raw_active_window_class="nil"`, `raw_is_CBWindow=false`, `hook_event_window_class="nil"`, `chosen_owner_class="nil"`, `host_probe_reason="owner_nil_or_raw_not_CBWindow"`, `owner_visible=false`, root/controller/content đều nil.
- `hooks.show=0`, `hooks.resize=0`, `hooks.hide=0`, `hooks.destroy=0` suốt toàn bộ lượt ghi; nghĩa là **không có instance CBWindow nào gọi bốn hook đó trong process CarPlay**. Tại cuối `hooks.dashboard_activate=6`, `hooks.dashboard_deactivate=17`, nên activation callback vẫn hoạt động.
- `dashboard_activated` chuyển **false → true**; ở 1792206493.937058 `dashboard_activated=true`, `raw_active_window_class=nil`, `hook_event_window_class=nil`; 1792206509, 1792206524, 1792206552, 1792206567 vẫn active true với **không owner**. **QUYẾT ĐỊNH**: vấn đề không chỉ vì Dashboard chưa active. Đã active vẫn không có CBWindow trong CarPlay, không thể mount bằng `S6VerifiedHost`.
- Tất cả 67 dòng `mounted=false`; 0 `MOUNTED`. Không có `WAIT: original GOFAHUD CarPlay card enabled` hoặc `WAIT: GOFA foreground`; thiếu GOFAHUD KHÔNG phải nguyên nhân.
- **Giới hạn**: log chỉ quan sát **tiến trình CarPlay PID 54313**. Chứng minh owner class method trả nil và show/resize không gọi **trong process đó**, KHÔNG chứng minh CBWindow không bao giờ được tạo ở **SpringBoard/CarPlayApp hoặc tiến trình khác**. Không đưa ra kết luận process chủ sở hữu khi chưa có runtime proof.

## Nguyên nhân lỗi ở mã Speed6 đã được khoanh vùng

`feature:runtime/speedbubble/DFSpeedNativeSplitHost.mm` đặt `S6CurrentOwner` nhận `+[CBWindow activeCarPlayWindow]` trong `CarPlay` và ép là `CBWindow`; fallback `s6EventOwner` chỉ có nếu hook `show` hoặc `resizeWindows` được gọi. Cả hai nguồn đều **nil / 0 sự kiện thực tế**. Cho nên `S6VerifiedHost` trả nil, không bao giờ `[host addSubview:s6HUD]`. Đây là **nguyên nhân trực tiếp đã xác minh ở đúng process**. Không cần GOFAHUD/tự gọi show/đánh thức GOFA để giải quyết điều kiện này.

**Static pinned Native12 source** `audit/speedbubble/NATIVE12_GOFAHUD_SPLIT_SCENE_OWNER_READONLY.json` kiểm class Native12 ở nhiều process; `CBBridgeManager` SpringBoard có `.window`, `CBWindow` tạo rootWindow, Dashboard hoạt hóa có thể nằm trong process khác, nhưng process owner **chưa được runtime đo**. `+[CBWindow activeCarPlayWindow]` ABI trả object không bảo đảm class; probe xác nhận **nil**, không phải UIWindow.

## Hướng tiếp theo phù hợp và tiêu chí dừng

1. **Không xây Speed7 bằng cách bỏ `activated`/tắt class check/tạo UIWindow global trên CarPlay**: Speed2 đã chứng minh từ 3 bóng trên Home, còn không đúng split.
2. Tập trung truy **đúng tiến trình tạo native CBWindow**, ưu tiên audit static của `CBBridgeManager.sharedInstance.window`, `CBWindow.show` callsites và Native12 per-process initializer, sau đó **read-only runtime owner probe ở đúng process** (SpringBoard và/hoặc process khác có chứng cứ) chỉ ghi class/activation/screen metadata, không thêm HUD vào Home. Nếu native bridge chỉ cấp dữ liệu từ SpringBoard thì giữ split-active token/lease và vẽ HUD duy nhất ở process đang sở hữu actual split UI, không dùng GOFAHUD global renderer.
3. Khi có owner snapshot thật, sửa mount condition và build thử; device acceptance: CarPlay Home=0, DuoFace split đúng 1 `—/—`, rời split=0, Waze ổn định. Chưa nối tốc độ.
4. Không tự sửa current live Sileo chỉ dựa vào log mới. Hiện bản công khai vẫn `0.1.0~native12+speed6zprobe1`; user đã gửi log của phiên bản probe. Chưa build/test trên máy bản sửa trong lượt này.

**Trạng thái: phân tích log thật → nguyên nhân trực tiếp confirmed → owner process unresolved.**
