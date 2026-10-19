# Nghiên cứu YTHUD 0.1.2: hiển thị video sang các ô khác của CarPlay Dashboard (2026-10-19)

## Phạm vi
- Nghiên cứu, **không sửa/build/deploy** code DuoFace/MyTweak; chỉ đánh giá có thể thay ô bản đồ lớn hoặc ô chỉ đường của Dashboard bằng output của YTHUD hay không.
- Đối tượng: `com.chou.ythud_0.1.2_iphoneos-arm64.deb`; SHA256 `f4a869fd025b8e9e0b47ca5b868df1f6ccd75fd6e2d909d86eb133da4b34ac1e`.
- Checkpoint repo DuoFace lúc tra cứu: main `f877d7d81dad7dfe1857d0495a0333b657304e37` (19/10/2026). Công việc Dock của MyTweak là vấn đề khác; không ngộ nhận YTHUD giải quyết Dock.

## Bằng chứng DEB tại chỗ
- `control`: "YouTube video in the CarPlay Dashboard music tile", iOS >=16, YouTube 21.41.5, live stream không được hỗ trợ.
- `YTHUD.plist`: filter `com.google.ios.youtube`. `YTHUDHost.plist`: filter `com.apple.CarPlayApp` / executable `CarPlay`.
- `YTHUDHost.dylib`: Objective-C identifiers `DBNowPlayingWidgetViewController`, `DBNowPlayingFocusHighlightButton`, `DBDashboard`, `CALayerHost`, `setContextId:`, `connectedScenes`, `windows`, `frame`, `convertRect:toView:`. Không thấy tham chiếu tên riêng tới ô map. Điều này KHÔNG chứng minh tất cả nhánh hook bằng phân tích tĩnh.
- `YTHUD.dylib`: `AVPlayerLayer`, `CAContext`, `remoteContextWithOptions:`, `contextId`, `YTAVEnableStreamVideo`, `YTAVTickDedicatedOutput`.
- Định danh đồng bộ: `com.duodash.youtube.dashboard.context.v1`, `com.duodash.youtube.dashboard.dashboard.v1`, `com.duodash.youtube.dashboard.deadline.v1`.
- Kết luận phạm vi: bản hiện tại nhắm ô Now Playing; không đủ bằng chứng để nói đã hỗ trợ ô bản đồ hoặc ô chỉ đường.

## Đối chiếu API và nguồn mở
- Apple: https://developer.apple.com/documentation/CarPlay/displaying-content-in-carplay — ứng dụng NAV có thể khai báo `CPSupportsDashboardNavigationScene`, `CPTemplateApplicationDashboardScene`, nhận `CPDashboardController` và `UIWindow`, hiển thị map qua root controller. API chính thức yêu cầu chỉ vẽ MAP trong cửa sổ này, không video tùy ý; không phải API cho app YouTube.
- Apple delegate: https://developer.apple.com/documentation/carplay/cptemplateapplicationdashboardscenedelegate/templateapplicationdashboardscene%28_%3Adidconnect%3Ato%3A%29 — map dashboard scene được kết nối riêng.
- CarSurf https://github.com/pavunato/carsurf mô tả app-scene CarPlay, nhưng xác nhận không chỉnh CarPlay template và bỏ qua dashboard widget/instrument scene. Không được lấy thành công host app của CarSurf làm bằng chứng thành công thay map tile.
- DuoDash có dashboard *riêng*, không đồng nghĩa hack ô bản đồ trong Dashboard gốc: https://sensetechlab.com/duodash/ .

## Đánh giá
1. **Ô Now Playing:** DEB có hook đối tượng cụ thể, phù hợp mục đích.
2. **Ô map lớn:** có thể thử trên jailbreak, NHƯNG phải xác định VIEW/WINDOW/SCENE thực tế sở hữu map ở iOS 16.7.x; sau đó gắn layer host context vào container riêng và giữ cách bố trí/clip theo map tile. Có thể dùng overlay được neo vào map tile hoặc thay render trong map scene; cả hai mới là giả thuyết, chưa có runtime proof.
3. **Ô chỉ đường/suggestion:** controller và nội dung thay đổi theo điều hướng; không thấy hook trong DEB; rủi ro xung đột cao.
4. **Full interactive YouTube:** `CALayerHost` cho hình chưa chứng minh truyền đầy đủ touch/keyboard/control ngược về YouTube. Vấn đề khác với app-scene bridge.
5. **Rủi ro cần tránh:** overlay full-window có thể che Apple Dock/thanh bên, tương tự vấn đề MyTweak đang điều tra. Không gắn thêm full-window che màn hình rồi cho rằng đã thay đúng ô.

## Kiểm chứng tối thiểu tiếp theo (chỉ khi có lệnh thực thi)
- Audit read-only **trong tiến trình CarPlay thực**: liệt kê windows, scene roles, cây view-controller/layer của Dashboard, đo frame/hidden/z-order cho NowPlaying, map, guidance, Dock; ghi class tồn tại/không tồn tại, không hardcode class giả.
- Trên iOS 16.7.x, khi đổi Apple Maps/GMaps/Waze, không có route/có route, xoay bố cục hoặc disconnect/reconnect: xác nhận map area thuộc controller/view nào và có thể định vị ổn định không.
- Chỉ sau khi đã chứng minh container có thật, làm candidate *riêng biệt* gắn test layer màu/hình tĩnh chính xác trong ô MAP, KHÔNG đụng NowPlaying và Dock. Sau đó mới thử CALayerHost context và video frame.
- Kiểm tra cảm ứng/âm thanh/điều hướng/hide-show/lifecycle, thao tác khi xe đỗ. Không khẳng định build/Sileo/device test khi chưa làm.

## Trạng thái 2026-10-19
- DEB trực tiếp: đã xem control, plist, Mach-O symbols, selectors/strings.
- Official docs/open-source: đã đối chiếu.
- Skill ZIP central GitHub đã được phát hiện; công cụ GitHub ở phiên này không xuất được ZIP dạng binary để giải nén (UTF-8 decode error). Đã đọc các Markdown entry/fallback `PROJECT_INSTRUCTIONS.md`, `AGENTS.md`, `SKILL_INDEX.md`, `DEB_IPA_SKILL.md` thay thế; không coi ZIP đã đọc.
- Không có probe CarPlay thật cho YTHUD map tile, chưa có DEB sửa, chưa có build/CI/Sileo.
