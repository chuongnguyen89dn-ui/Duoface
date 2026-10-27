# Kiểm toán lịch sử DuoFace cũ: có bản nào phát video không crash? — 2026-10-27

## Phạm vi và kết luận chặt chẽ

Yêu cầu mới nhất của người dùng: "Kiểm tra lại lịch sử các QA cũ xem có cái nào thành công ko crash ko". **Không chỉnh sửa mã, UI, DEB, Sileo hoặc repo khác trong lượt này**. GitHub repo `chuongnguyen89dn-ui/Duoface`, nhánh `feature/duoface-jb-embedded-appbridge-20261020`; đối chiếu **bản DuoFace integrated `com.duoface.jb.embedded` với addon SidePlay QA6/7/8 là các gói KHÁC KIẾN TRÚC, không nhập nhằng**.

**Không phát hiện phiên bản DuoFace tích hợp độc lập nào đã có phép đo thiết bị chứng minh phát YouTube/Facebook/TikTok ổn định, không SpringBoard SIGABRT lâu dài.** Nhưng **.37 là mốc duy nhất có phản hồi người dùng trước đây rằng YouTube phát được và không ExitSafeMode trong lần dùng đó**, dù **hình xoay sai**, chưa có video/seek session timestamp/IPS âm tính đủ chứng minh toàn bộ phiên .37 không crash. Mọi CI SUCCESS chỉ chứng minh build/packaging, không chứng minh playback. Không nói ".37 ổn định, không bao giờ crash".

## Bảng phân biệt device và artifact

| Phiên bản/bản chất | Thiết bị/người dùng đã xác nhận | Kết luận riêng về SpringBoard crash |
| --- | --- | --- |
| SidePlay-dependent QA6 `com.duoface.sideplaydisplay 0.1.4~native12root6` | 18/10: ảnh thật có UI SidePlay cũ/thiếu thanh CarPlay, **FAIL giao diện**; không có bài phát YouTube được xác minh | **Không có chứng cứ chống crash** |
| CarPlay native bridge QA6 `com.duoface.carplay.nativebridgeqa 0.0.6~dockcrop1` (KHÁC SidePlay QA6) | 20/10: user xác nhận Dock có xuất hiện nhưng đôi lúc chuyển fullscreen và mất Dock; quan sát về Dock, không phải nghiệm thu video. | **Không có phép đo YouTube no-crash** |
| SidePlay-dependent QA7 `0.1.5~native12visual7` | 18/10: người dùng đánh giá đồng bộ *khá ổn*, đang sử dụng thực; thanh CarPlay không xuất hiện, chưa đạt Native12. Các lần SidePlay 2 ô không tương đương embedded AppBridge. | **Chỉ khá ổn về UI/split**, không có phép thử YouTube/Facebook no-crash |
| SidePlay-dependent QA8 `0.1.6~native12bootstrap8` | Source, Theos, artifact SHA/CI PASS; tại mốc 18/10 **chưa lên Sileo và chưa test thiết bị** | **Chưa xác minh**. Không gán QA8 OmniCar của repo khác thành QA8 DuoFace |
| Integrated .23–.36 | Nhiều package từng build/publish, có lịch sử UI, logo, picker, Dock chưa đạt các mục chức năng; chưa thấy proof user stress test video no-crash | **Không được tự nâng thành crash-free** |
| **Integrated .37 `0.0.37~native12dockzoom1`** | 22/10 15:58 ảnh YouTube xoay sai; người dùng nhớ rõ **video phát được, không ExitSafeMode khi đó**. Ghi chú 23–26/10 xác nhận phát được nhưng sai orientation. Sau này hồi phục tên ".37" gặp cả crash/bó; có khác biệt source/package đang chạy, không phải thử nghiệm tái lập xác nhận `.37` nguyên hash | **Mốc playback tốt nhất, KHÔNG có xác nhận ổn định lâu dài** |
| .38, .39, .40 | 23/10: SpringBoard IPS crash ~06:57, 07:22, 09:16 sau các lần phát hành .38/.39/.40. **Chưa có installed DEB version được chứng thực cho riêng từng crash đó**, nên không nói đã chứng minh .38 trực tiếp tạo crash. | **Giai đoạn phát sinh crash thực**, bản cụ thể của IPS chưa xác định |
| .41–.47 | 23/10 user xác nhận YouTube ExitSafeMode vẫn lỗi; .44 sửa source dựa .37 vẫn chưa được device PASS; .47 ảnh CarPlay và crash còn vấn đề | **Có thất bại người dùng, không thấy phiên bản PASS ổn định** |
| .48–.73 | .48 là source/window-ownership rewrite; rất nhiều bản chỉ CI/Sileo PASS; .68 screenshot vẫn phone-boxed; .73 user báo crash sau cài. .69/.70 khôi phục một phần .37 chứ chưa trả 4-window architecture; .71 khác rồi vẫn lỗi viewport | **Không có bản nào được xác nhận video + no crash** |
| .74 `media37host1` | 27/10: UI video không còn bị bó theo người dùng; **ba IPS SpringBoard SIGABRT 09:13/09:20 với DeepTrace build `.74`** | **CRASH được chứng thực bằng PID + thời gian + build** |
| .75 `framegate1` | Người dùng: lại bó + vẫn crash; chưa có IPS đặc thù .75 | **FAIL theo người dùng** |
| .76 `reason1` | Người dùng báo YouTube/Facebook lúc play video crash nhanh; chưa có IPS pin đúng bản ở mốc báo cáo | **FAIL theo người dùng**, không gán old .74 stack mặc định |
| .77 `mode2frame1` | Hai IPS độc lập YouTube và Facebook + fatal exception `foreground=BSSettingFlagNo` khi `SBAppViewController` Live | **CRASH đã chứng thực trực tiếp** |
| .78 `scenegeneration1` | Log và IPS YouTube/TikTok xác nhận cùng foreground assertion | **CRASH đã chứng thực trực tiếp** |
| .79 `nativeocclusion1` | YouTube/TikTok/Facebook ba IPS ngày 27/10 + DuoFaceAudit 4 chứng thực SIGABRT | **CRASH đã chứng thực trực tiếp** |
| .80 `lifecycleorder1` | Ký/build công bố Sileo ngày 27/10; chưa có thử thiết bị video mới | **Chưa có kết quả** |

## Bản .37 nguyên vẹn để dùng làm **chuẩn so sánh mã**, không tự động cài lại

- **DEB thật immutable:** `sideplay/jb-embedded-appbridge/evidence/runs/39748923126/com.duoface.jb.embedded_0.0.37~native12dockzoom1_iphoneos-arm64.deb`; SHA256 **`2b6f274e684e5a6f1008dac960c87ff51744fddb5342ce42fcd74e5c61314beb`**, xác nhận từ `SHA256SUMS.txt` và `PACKAGING_PROVENANCE.json` (GitHub blob `4a9cc52eeded82b8569772c26638906d694623dc`), 30 payload, package builder source commit `a8cdec6252b0e772faa726e92b84ee66246590ed`, build run `39748923126`. NativeHost riêng trong gói `0.1.47~realdock1`; phải pin binary thực chứ không suy diễn từ source revision.
- **Khác biệt cấu trúc đã được chứng minh:** .37 `DFNative12Chrome.m` 4 per-slot physical `UIWindow`; .48–.70 dùng 1 `sharedAppWindow` + 4 subviews; .71 khôi phục 4 physical windows nhưng **không** chứng minh playback sửa. Source .37 `DFSceneHost.m` vẫn có `scene.updateSettingsWithBlock:` với `setFrame:`, không đúng khi nói `setFrame` mới xuất hiện ở .40.
- **Delta .37 → .38 đáng cô lập (KHÔNG phải root cause proven):** `DFSceneHost.m` +37/-3, thêm tính toán geometry helper/uniform scale, **synchronous `setNeedsLayout/layoutIfNeeded` sau remote private `updateSettingsWithBlock:`**, async touch observer có thể relayout khi video chạy; `DFNative12Chrome.m` +247/-85 về window/control UI. .38→.39 KHÔNG có sửa `DFSceneHost.m` qua 15 commits; .40 thêm reentrancy guards. Không suy ra .38 gây foreground=NO từ publish time.
- **Vết assertion chắc nhất từ .77–.79:** SpringBoard `-[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]+440`; .77 reason: `NSInternalInconsistencyException` host Live nhưng foreground scene bị update `BSSettingFlagNo`. **Không biết writer**. .74 có cùng stack nhưng không có reason; không quy nạp thành cùng writer.

## Quyết định thực hiện tiếp dựa trên chứng cứ, không đoán

1. **Giữ nguyên bản .80 hiện có, UI đang tốt và mã nguồn** trong phạm vi yêu cầu đọc lịch sử. Không tự downgrade .37 hay tạo tiếp một build tràn lan.
2. Sử dụng .37 chỉ làm **reference hash + source/binary source-of-truth** để so scene lifecycle/scene owner/teardown; so `.37 → .38` và `.37 → .80` những thay đổi lifecycle (touch-induced reentry, geometry callback, window ownership, stop) theo data.
3. Chưa được gọi `.37` là bản **đã chứng minh không crash** khi chưa có tập video stress/foreground timeline; không tự chuyển lại .37 vì người dùng nói hiện UI bình thường và chỉ yêu cầu sửa crash.
4. Tiêu chí thành công thật: cùng thiết bị, đúng gói installed pinned hash/phiên bản, chơi YouTube/Facebook/TikTok + seek/split/focus/close/reopen liên tục, không SpringBoard SIGABRT; giữ Dock/UI nguyên trạng. Nếu .80 crash, thu chính xác fatal reason và `scene-foreground-observed-only` từ audit mới, đối chiếu .37 start/stop trước chọn code fix; không tự thử chung chung, không bật app-side viewport relay.

## Nguồn đã đọc lại

- `sideplay/tiep tuc du an.md` nhánh feature, Git blob `2d046ae01f596b88ee4ae44d164fdeeb302d298c` (1.15 MB); older history main blob `916f3e241485def808a01737bf59236a8f6be298`; older canonical main `ban giao du an duoface moi.md` blob `1553b5523f5663bfc05f6fc406301249d3be7ad7`. Dữ liệu dùng trong báo cáo được trích/summarize và không sao chép bí mật.
- `sideplay/audit/native12-039-regressions-20261023/MEDIA_VIDEO_CRASH_CROSSWALK_20261023.md`, blob `1975c72ec5f390c7c0ab184af26ba6f7199b14f8` (bảng release .37–.40 và installed-version caveat).
- `sideplay/audit/native12-039-regressions-20261023/V37_NOT_FULLY_RESTORED_ROOT_DIFF_20261026.md` (original .37 SHA/owner difference).
- `sideplay/audit/native12-039-regressions-20261023/CRASH_074_SPRINGBOARD_SCENE_DIFF_20261027.md` (3 IPS + DeepTrace).
- `sideplay/audit/native12-039-regressions-20261023/CRASH_077_REAL_FOREGROUND_NO_ASSERT_20261027.md` (.77 fatal reason).
- `sideplay/README.md` (.78, .79 runtime log/IPS and .80 build/Pages).
- `sideplay/jb-embedded-appbridge/evidence/runs/39748923126/BUILD_SOURCE.txt` / `SHA256SUMS.txt` / `PACKAGING_PROVENANCE.json`.
- `sideplay/native12-display/QA6_CARPLAY_DEVICE_VALIDATION.md` and early QA6–QA8 checkpoint in `sideplay/tiep tuc du an.md` main; SidePlay addon distinct from independent AppBridge.
