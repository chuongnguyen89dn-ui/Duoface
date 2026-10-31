# QA147 bị người dùng bác bỏ: luồng scene/ACK chưa hoàn tất, không phải chỉ thiếu lệnh Dock

## Yêu cầu và kết quả thiết bị

Người dùng xác nhận: Home phải trở lại trang chọn app thông thường, hiện lại về CarPlay Home; mở app chậm; đôi lúc thành giao diện mobile/sai chiều; Dock không nhận app đang mở. Đây là **QA147 chưa đạt**, thay thế trạng thái “chờ test thiết bị” ở checkpoint trước. Không coi bản build xanh/DEB ký/Sileo tải đúng SHA là phần mềm đã hoạt động đúng.

Log mới: main `a067fbc931ce9ddf98f918bdfbd3a222eb662bb3`, `sideplay/log/DuoFaceAudit 23.txt`, 6,998,737 bytes, blob `18f4a8432d124b1acb96df2b49d7b826a1951b89`. Export 2026-10-31 11:28:39 UTC, iOS16.7.16. Script khóa blob/size và chỉ phân tích sau marker QA147 consumer lúc1793445863.881 để không trộn Log22/phiên cũ. Exporter/deeptrace vẫn in nhãn0.0.90 hằng số; không dùng nhãn đó để kết luận cài nhầm phiên bản. CarPlay có marker consumer147 thật; không có kiểm kê đầy đủ version mọi dylib/process từ TXT.

## Kết quả định lượng

| Đo được trong phiên mới | Số lượng |
|---|---:|
| Yêu cầu mở app từ Home | 26 |
| Host scene được quan sát ready, render chưa xác minh | 16 |
| ACK standalone `scene-hosted-render-and-touch-unverified` | 0 |
| `qa147-native-dock-active` | 0 |
| `qa147-native-dock-abi-refused` | 0 |
| Attach thất bại `Scene attach exception: bogus reference size` | 8 |
| Sau lỗi vẫn ghi pending-scene với bundle/request null | 8 |
| Lần stop có khoảng sống9.5–11.5s từ request | 8 |

18 request có pending cùng UUID; median request→pending0.1335s, min0.074s, max0.266s. Đó chỉ là IPC/đặt window-surface, không phải phản hồi nội dung/first frame/first touch. Không được dùng con số này để phủ nhận báo chậm của người dùng hoặc kết luận file/notify transport gây chậm.

Ví dụ YouTube request `10F497AC-BA87-4219-9B15-02C18D8661C8`: request1793445903.630, pending5903.896, scene-handle observed5904.246736 (~0.617s sau request), nhưng không ACK standalone và không cập nhật Dock; stopped5914.129 (~10.499s). Đây là bằng chứng đường scene-observed→standalone-ready→Dock bị đứt, không phải cần đoán lại tên API Dock.

## Đối chiếu source đang phát hành

- `DFSceneHost.m pollScene:` đã log16 lần `scene-handle-observed-render-unverified` và source có post `DFSceneHostDidBecomeReadyNotification` với object=self. Đó chưa phải process/media ACK.
- `DFHomeStandalone144.m sceneReady:` có các cổng object surface/window, live host, bundle, `verifiedPIDForHostedView:` rồi mới phát ACK. Không có log phân biệt từng cổng trả về; **chưa xác định chính xác cổng nào đã từ chối**. PID getter hoặc timing một lần là ứng viên kiểm chứng, không phải nguyên nhân đã đo. Hàm callback không có retry/rehydrate ACK sau khi live/PID thay đổi; không được sửa bằng fake PID hay bỏ kiểm tra ownership.
- `DFNativeDockSync147.h` chỉ vào activate sau đúng ACK/PID. Trong phiên này consumer được cài, nhưng không có ACK nên cả nhánh setter/ABI-refusal đều không chạy. Do đó không thể nhận xét hiệu lực setter native từ Log23; chỗ thiếu nằm trước tầng Dock.
- Watch của QA147 có pending-timeout10s và gửi cùng notify stop như Home; SpringBoard ghi chung `native-Home-exit`.8 khoảng sống gần10s phù hợp nhánh này, nhưng log không phân biệt stop do người bấm Home hay timeout. **Không quy tất cả cho thao tác Home của người dùng**. Việc tự thu hồi host vì thiếu ACK trong khi scene đã được thấy là rủi ro thật của thiết kế QA147; chưa được chấp nhận.
- `DFSceneSurface.start` có thể phát failed đồng bộ trong containment/appearance/mode setup. `DF144Solo sceneFailed:` stop và xóa bundle/request/window. `begin:` vẫn tiếp tục sau `[root.view addSubview:v]` và gọi pending:8 dòng null sau8 lỗi cho thấy continuation sau teardown. Cần chống reentrancy/generation ở ranh giới begin/attach; không tiếp tục thành công hoặc gọi pending trên owner đã chết.
- Home ở `DFCarPlayOwnerObserver.h` hiện phát stop rồi gọi original `homeButtonUp:`. Không có hợp đồng khôi phục trang chọn app/context gốc. Thêm enum hiển thị Home/Dock không thay thế navigation state; yêu cầu người dùng vẫn chưa được thực hiện.

## Giao diện mobile/sai chiều và khác biệt với reference

Log có15 `scene-frame-readback`: ví dụ actual375x812 trong khi target1190x663. Đây là đọc **trước** settings commit; không chứng minh frame sau commit giữ nguyên. Có7 YouTube app-handshake ACK, nhưng signed package chỉ có app-side helpers riêng YouTube/GOFA, chưa có hợp đồng app-side cho Facebook/TikTok/ChatGPT/Gemini. Không đổi mã orientation thành landscape chỉ từ aspect ratio; Native12 đã dùng portrait reference contract ở một số tầng. Phải phân biệt renderer transform, host reference, FBScene settings và UIWindow/UIApp geometry.

Reference đã giải mã cho thấy DuoNavi có prepareHome/closeOfficialTopApp/native workspace request/deactivate, handleStateDict→bridgeDidActivate/Deactivate→Dock/Home; DuoDash REPACK có host-state và app-side scene/geometry contracts riêng. QA147 mới nối một consumer Dock vào host SOLO hiện có; **chưa ghép đầy đủ native workspace/application lifecycle và app-side contract**. Điểm khác này có căn cứ. Chỉ vì dùng remote UIView/UIWindow riêng không tự chứng minh sai (reference cũng host scene); lỗi là chuỗi ownership/navigation/state chưa hoàn tất. Không tiếp tục coi việc hiện được pixels là tương đương bản gốc.

## Các báo cáo bổ sung không được gán sai cho QA147

Hai CarPlay IPS mới upload mang thời điểm10:18+0700 và có blob y hệt file cũ (`e0a464…`, `60e206…`), trước khi147 phát hành18:22+0700. Không phải bằng chứng crash mới của147.

SpringBoard `diskwrites_resource` bug_type145 là cảnh báo ghi1073.75MB/25528s (~42.06KB/s), `Action taken:none`, không phải crash/kill. Khoảng đo10:46–17:51+0700 kết thúc trước147. Stack không gọi tên module DuoFace trong report, nên không quy hết I/O cho147 hoặc khẳng định đó là nguyên nhân chậm. Cần kiểm tra/giảm ghi poll/telemetry trong một thay đổi có đo riêng, tránh thêm instrumentation dày không giới hạn.

## Quyết định và bước kế tiếp

1. QA147 là bản thiết bị không đạt; không có bản148 hay Sileo update trong lượt kiểm log này.
2. Truy chính xác callback/verified process-owner tại ready boundary và original host-state success contract; ghi ít, có giới hạn, phân biệt các cổng từ chối. Không phát ACK giả hoặc rút timeout để che lỗi.
3. Sửa continuation sau attach failure và phân biệt stop reason/generation trong thiết kế. Khôi phục đúng ngữ nghĩa trang chọn app/navigation của reference, không redirect vào split và không luôn forward Home Apple.
4. Đối chiếu requestStateChange/deactivate/foreground app, host app-side scene settings/geometry trước khi tiếp tục sửa biểu tượng Dock. Consumer147 không đủ giải quyết các phần còn thiếu đó.
5. Mọi ứng viên tiếp theo phải có kiểm chứng begin→actual host/process→ACK→native state/Dock→app switch/Home→teardown và kiểm thử lỗi attach, PID đến muộn, đổi app nhanh. Hiệu quả thực tế còn cần test thiết bị, không thay bằng contract tests hoặc tên selector.

## Tái hiện

Từ repo source, lấy raw file bằng `git show 'a067fbc931ce9ddf98f918bdfbd3a222eb662bb3:sideplay/log/DuoFaceAudit 23.txt' > /tmp/duoface-audit23.txt` rồi chạy:

```bash
python3 sideplay/audit/qa147-user-log23-failure-20261031/analyze_log23.py --log /tmp/duoface-audit23.txt --out sideplay/audit/qa147-user-log23-failure-20261031/LOG23_FAILURE_FINDINGS.json
```

Kết quả thực tế lưu trong ANALYSIS_RESULT.txt và JSON; raw log/IPS giữ nguyên ở main. Report này không tuyên bố đã sửa hoặc test phiên bản mới.
