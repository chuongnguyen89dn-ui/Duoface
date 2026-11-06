# Phản biện tài liệu QUYET_DINH_KHAC_PHUC_20261106 — DuoFace

**Ngày đánh giá:** 2026-11-06 (Asia/Ho_Chi_Minh). **Trạng thái:** đánh giá kỹ thuật, CHƯA phê duyệt hướng B, CHƯA sửa source, chưa build/chạy job/test xe/phát hành. Tài liệu đầu vào do Nguyen đính kèm trong chat, 113 dòng, tiêu đề "QUYẾT ĐỊNH KHẮC PHỤC DUOFACE — LOGO + BẢN ĐỒ (06/11/2026)". Phân biệt rõ nội dung tài liệu với đối chiếu source/log.

## 1. Repo / dữ liệu đã kiểm tra

- Repo: `chuongnguyen89dn-ui/Duoface`, nhánh phân tích/tiếp nối `fix/qa180-owned-wake-map-replace-20261106`; repo default `spec-main`. Không chuyển nhánh/đụng source. Mã đã ký QA176 từ commit `3d0fafcc2e17bca9739cf900d0bac5668ebc1aef`, phát hành 0.0.176~appwake1, DEB hash `6d7cf1eff02e4c238ff0b36c93de851a834f99ef54ba2e38e19d99b50d8a0c14`.
- Đọc trực tiếp `sideplay/duoface-native-scene-host/DFAppTouch177.h` (blob `153315cc74b8883284efb3cb4175cc4b4b937ba4`), `DFAppWakeGate176.h` (blob `863fed53784ef8a7a04769216f12818dff23769f`), `DFNative12Chrome.m` (blob `fcdaf7d690986f04fe43b192d731760fefd11f6c`). Ở source đã ký QA176, DFAppTouch177.h có cùng SHA với nhánh hiện tại.
- Đọc hồ sơ QA176 hậu phát hành `sideplay/audit/qa176-appwake1-20261106/POST_RELEASE_LOG_CODE_REVIEW_20261106.md`, commit đính chính `1046bde63f062d5f9ff4c33a624de9a1abbb5e9a`. Nguồn log thiết bị mới nhất: `main:sideplay/log/DuoFaceAudit 5.txt`, commit `ed358e8fc9d2c409fc31f3d256421b8bf489894a`, blob `5eedbc8aadea7558329ea2e1ce4e49054fe24ede`; bản đối chiếu này dùng hồ sơ phân tích LOG5 đã xác minh trước, **không tự nhận đã tự phân tích lại toàn bộ 5.46MB raw LOG5 trong phiên này**. Không nhầm LOG4 là mới nhất.
- Tài liệu tải lên dẫn các đường dẫn local `~/workspace/deb-ho-so/`, `~/workspace/duoface-audit/OMNICAR_CO_CHE_APP.md`, `OMNICAR_APP_BAN_DO.md`. Bản raw/code OmniCar/DuoNavi tại các đường dẫn local **chưa được đọc lại trong phiên này**; các đặc tả bảy hook là **tuyên bố của tài liệu**, chưa được xác minh độc lập qua binary hoặc live ABI.

## 2. A — Logo: đồng ý tầng app-relay, bác bỏ việc làm lại cùng một giải pháp

**Được chứng minh/đã có:** `DFAppTouch177.h` hiện đã hook `UIApplication sendEvent:`; gọi `DF176ConsumeWakeEvent(event,DF177TouchBundle)` **trước** original. `DFAppWakeGate176.h` đọc wake-state plist `/var/mobile/Library/Preferences/com.duoface.nativehost.wake-state.v1.plist` và owner pulse; xác minh version, eligible, session, bundle, PID, deadline/freshness; duy trì captured/forwarded UITouch tới Ended/Cancelled; phát `DF177AppTouchNoteBegan` khi giành chạm. `DFNative12Chrome.m` viết snapshot định kỳ 250ms; handle app touch qua DF156 mailbox; cập nhật `controlsUntil` và alpha mà không gọi layout ngay. Vì vậy đề nghị "mở rộng H1 để chặn chạm đầu" **về cơ bản đã được thực hiện trong QA176**. Không quay về nền QA172 bằng cách hồi quy các sửa sau.

**Lỗ hổng cụ thể trong source đã đọc:**
1. Gate không kiểm tra `UITouch.window`, `windowScene`, `UIScreen` hoặc quan hệ cửa sổ/surface của đúng ô CarPlay. Điều kiện bundle/PID/session là cần, không đủ; có nguy cơ chặn chạm ở scene iPhone cùng process. Đây là **static risk**, không phải lỗi thiết bị đã chứng minh.
2. `df176PublishWakeState` không dùng `kbVisible177`/`kbStateKnown177` trong eligibility, và gate cũng không kiểm tra. Có nguy cơ nuốt chạm bàn phím hoặc làm hỏng thứ tự input; fail-open khi xác minh không được scene/keyboard.
3. Tests QA176 dùng plist giả lập / UIKit stub và text-presence integration; không chứng minh sandbox app đọc được path SpringBoard ghi, không chứng minh first touch về đúng relay trên hardware. Cần marker có thể kiểm tra `state-read` (kết quả/generation, không lộ bí mật), `reserve`, `consume`, `wake-sent`, `host-received`, `host-visible`, và marker touch bình thường, phân biệt mọi đường fail-open. Quan sát trong exporter không lấy NSLog app làm transport chính.
4. H1 QA177 log có thể chứng minh nhận touch và visual recall, KHÔNG chứng minh đã chặn gesture đầu; QA176 LOG5 không có các marker app-touch/recalI ở build 176, nhưng mã hiện tại thiếu log consume => chưa thể xác nhận PASS/FAIL first touch từ LOG5.
5. `DFAppTouch177.h` comment "Original first / never cancels" đã lỗi thời sau QA176 hook; cần cập nhật **khi sửa code**, không tự sửa chỉ vì review.

**Quyết định đề xuất A:** không tạo `sendEvent:` hook mới; khảo sát receive/transport/readability trước; sửa *chính* gate hiện hành theo provenance màn/scene và loại trừ keyboard, cùng log nguyên nhân fail-open, giữ key-state/owner và original dispatch khi không chắc. Test 3+ hide/wake, first only (no app action, no divider drag/SWAP), second passes, Maps và YouTube relay riêng; kiểm phone negative controls/keyboard/multitouch. Chỉ kết luận device PASS qua log token + mắt xe.

## 3. B — Maps/Waze: ACK false-positive là chính xác, 7 hook OmniCar CHƯA là lời giải đã chứng minh

**Log5 thực tế (theo hồ sơ hậu phát hành đã hiệu chỉnh):**
- Google Maps: `07:32:00.771259Z qa180-map-replace-finish ... applied=1 restore=0 reason=native-attach-ack`; kế tiếp `07:32:01.196769Z qa124-scene-resign-retained-await-background`, `07:32:01.695602Z native-owner-state active=0 visible-candidates=0`, `07:32:02.148482Z native12-chrome-stop`. Waze lặp chuỗi ACK→resign→owner inactive→chrome-stop hai lần ở 07:32:41–42Z và 07:33:10–11Z.
- Footer native ACK mang `map-tiles-not-verified`, owner bundle `unverified`. Mối liên hệ thời gian chắc; cơ chế takeover chưa chứng minh dứt điểm, nhưng app rendering trong hai ô không được chấp nhận. Không được kết luận scene/pixel PASS bằng ACK.

**Phản biện theo thứ tự tài liệu:**
1. **Roster/picker KHÔNG cần làm lại từ đầu.** QA175 log đã có 8 request UUID tiến tới `qa180-map-replace-finish`, QA176 có `picker-request` và `map-replace-prepared`; các bước chọn có tín hiệu. Có thể còn lỗi Home icon và trường hợp danh mục, nhưng không đủ bằng chứng để dỡ roster/picker rồi ghép lại. Cần snapshot đối chiếu thực tế thay vì tuyên bố "QA174 gãy" là hiện trạng QA176.
2. **Không được suy từ `_launchAppWithInfo:` + `sceneFrameForAppInfo:` sang native map trong một ô.** Điểm nghẽn thực tế là quyền foreground/active scene của CarPlay. Đổi kích thước không chứng minh scene được compositor/slot đúng chỗ; giữ origin gốc có thể không trùng origin ô, không chứng minh hit-testing, clipping, z-order. Cần chứng minh *sau launch* DuoFace vẫn visible cùng scene native, một pane không chiếm toàn dashboard, hai pane hoạt động. Kiểm tra selector và ABI trên đúng iOS 16.7.16; dữ liệu DuoNavi/OmniCar local chỉ mới là tuyên bố hồ sơ.
3. **Hai app-native đồng thời chưa chứng minh.** Dashboard CarPlay có thể có giới hạn foreground/scene đa ứng dụng. Bản 7 hook chưa chứng minh Maps+Waze đồng thời hoặc map+YouTube không chuyển owner. Gating readback scene id/bundle/process và UI owner hậu launch trước khi thiết kế ngược.
4. **`_loadFromProxy:` chế `CRCarPlayAppDeclaration` không tạo entitlement/native lifecycle thật.** Dễ sai nếu app không có CarPlay capability hay scene delegate; không nên coi đây là bằng chứng có icon Home hoặc app native. App đã declaration thật phải giữ nguyên. Xác minh Home icon riêng.
5. **Hình học "một chủ ghi" tốt ở nguyên tắc, không phải khóa chung cho cả hai loại scene.** Cần một owner mỗi scene và đường chuyển kích thước kiểm chứng: target/readback tại thời điểm launch, sau 0.3s/2s, layout origin/insets, chạm ở nhiều điểm; app bridge hiện có thể phụ thuộc logical size x2/scale, đổi chung dễ hỏng keyboard/touch. Không phá bỏ lease/resize cũ trước khi chứng minh thay thế.
6. **Hook keep-alive global/under-lock là quá sớm.** Chỉ mở rộng nếu có bằng chứng scene chết do lock/background trong khi vẫn có ô chủ, phải hạn scope session/app và cleanup; không được áp chung hệ thống trước khi chứng minh native presentation.
7. **Điểm xung đột liên phần:** nếu B chuyển Maps/Waze từ phone main-display hosted scene sang native CarPlay dashboard scene, đường touch dispatch có thể khác H1 của A. Không được mặc nhiên dùng QA177 relay-touch PASS cũ để chứng minh first-contact wake trong native scene. Cần tái nghiệm thu A trên scene-type mới.
8. **Tiêu chí "first frame do app render"** nên thu cả scene identity thực và test visual/interaction (zoom/pan, app-specific labels, thumbnail/pixel inspection trên xe); `frame acquired`/scene object tồn tại vẫn chưa chứng minh tile. Không biến `map-tiles-not-verified` thành token PASS bằng sửa log.
9. **Phạm vi/publishing:** "một bản một cơ chế" hợp lý cho A, nhưng B là thay đổi cross-process bảy hook + roster/picker/geometry/lifecycle; một bản duy nhất gộp tất cả mâu thuẫn nguyên tắc giảm rủi ro. Kiểm từng invariant, negative controls, commit/tag nguồn, version mới; giữ 174–176 rollback. Không phát hành Sileo khi static-only.

**Đề nghị B thay vì triển khai nguyên 5 mắt:** stage B0 chỉ-đọc/đo thật native ownership, dashboard scene/foreground, available selectors, constraints, picker records đã có; B1 proof-of-concept native map **một ô**, không đụng roster/keyboard/Home, chứng minh sau launch DuoFace còn foreground + app scene thực vẽ map + touch đúng, và close/reopen ổn; B2 mới triển khai nhiều app và độ bền scene nếu B1 PASS. Nếu B0 cho thấy Dashboard không giữ hai owner, phải đổi giả thuyết kiến trúc, không vá tiếp frame/lifecycle.

## 4. Verdict, ranh giới và bước tiếp nối

- **A:** nhận hướng app-relay nhưng QA176 đã triển khai cốt lõi. Ưu tiên xác minh đường signal + fix boundary app scene/keyboard và gate fail-open trước khi đề xuất DEB mới.
- **B:** nhận chẩn đoán "ACK false-positive", **chưa chấp thuận copy toàn bộ 7 hook OmniCar**; native ownership/foreground là first gate, chưa có bằng chứng. Bỏ bớt việc tái tạo roster/picker vốn có dấu mốc ở QA175/176.
- **Tuyên bố về DuoNavi/OmniCar trong MD nguồn:** tham khảo kiến trúc độc lập, KHÔNG suy thành bằng chứng runtime code, KHÔNG sao chép code hay license.
- **Tiêu chí nghiệm thu:** A=3 chu kỳ, first consume/visual recall, second forwarded, app-origin đúng, không ảnh hưởng phone/keyboard; B=đúng app scene identity+owner tiếp tục active+live tiles/touch trong từng ô, native/UI Home là kiểm tra riêng; giữ GOFA/YouTube, keyboard, return/resize/resize/touch.
- **Tác động phiên review này:** ghi nhận phân tích vào GitHub **chỉ tài liệu**. Không sửa mã, không build, không chạy CI, không publish/đẩy bản Sileo, không xác nhận DEVICE_TESTED mới.

## Liên kết kiểm chứng

- Handoff: https://github.com/chuongnguyen89dn-ui/Duoface/blob/fix/qa180-owned-wake-map-replace-20261106/sideplay/tiep%20tuc%20du%20an.md
- Source đã phát hành: https://github.com/chuongnguyen89dn-ui/Duoface/tree/3d0fafcc2e17bca9739cf900d0bac5668ebc1aef/sideplay/duoface-native-scene-host
- Review LOG5 đã hiệu chỉnh: https://github.com/chuongnguyen89dn-ui/Duoface/blob/1046bde63f062d5f9ff4c33a624de9a1abbb5e9a/sideplay/audit/qa176-appwake1-20261106/POST_RELEASE_LOG_CODE_REVIEW_20261106.md
- LOG5 nguồn: https://github.com/chuongnguyen89dn-ui/Duoface/blob/ed358e8fc9d2c409fc31f3d256421b8bf489894a/sideplay/log/DuoFaceAudit%205.txt


## 5. Phát hiện bổ sung tại biên consume/wake

- Phân tích source `DFAppWakeGate176.h`: khi điều kiện hidden khớp, gate đặt `consume=YES` và gọi `DF177AppTouchNoteBegan(bundle)`, sau đó trả `YES` để bỏ original app dispatch. Nhưng `DF177AppTouchNoteBegan` trong `DFAppTouch177.h` hiện trả `void`, có các đường `return` trước, `DF156Write` có thể thất bại, `notify_post` có thể thất bại, và `@catch` nuốt exception. **Không có kết quả transport hay ACK từ host được trả lại cho quyết định consume.** Như vậy có một đường source-level: event bị nuốt nhưng wake chưa được chứng minh đã gửi/nhận. Đây là **lỗ hổng logic xác nhận**, không phải kết luận thiết bị đã gặp đúng đường này.
- Phương án cải tiến: trước khi commit nuốt gesture, cần chứng minh transport send được kích hoạt theo chính trạng thái session, tối thiểu trả kết quả write/notify, log kết quả fail-open và không lấy `recalledUntil` làm bằng chứng host đã wake. ACK host và visual state phải được ghi nhận độc lập; các ràng buộc latency/input safety cần được test trên thiết bị. Không tự khẳng định chỉ việc đảo thứ tự hoặc trả boolean sẽ bảo đảm host hiện logo.


## 6. Phản hồi đối chiếu và quyết định hiệu chỉnh 06/11/2026

**Tình trạng:** Người dùng chuyển phản hồi chấp thuận phần lớn phân tích, điều chỉnh ba điểm hẹp và thêm cổng bắt buộc ở B1. Đây là yêu cầu cập nhật kế hoạch, không phải phê duyệt sửa mã/phát hành. Trong lần này đã đọc **toàn bộ blob** `main:sideplay/log/DuoFaceAudit 5.txt` (SHA `5eedbc8aadea7558329ea2e1ce4e49054fe24ede`), 43.358 dòng/5.462.784 ký tự; lọc đúng 486 bản ghi timestamp `build=0.0.176~appwake1`. Phân tích log trực tiếp mới thay thế giới hạn đọc qua báo cáo log trong lần trước.

### Những điểm được chấp nhận

1. **Roster/picker:** giữ nguyên mã hiện tại, không đập đi làm lại. QA175 có 8 UUID thay ô và QA176 có map-picker request/ACK, song bằng chứng chỉ giới hạn theo từng phiên; QA174 từng mở picker không ghi được lựa chọn. Vẫn bắt buộc nghiệm thu trên xe: mở lưới thấy Maps/Waze và app đã chọn dù không bật ở CarPlay Settings gốc, chọn đúng ứng dụng vào từng slot và có giao dịch chọn ghi nhận. App icon trên Home cần nghiệm thu riêng.
2. **Keep-alive:** lùi hoàn toàn xuống *sau B1*, chỉ can thiệp nếu chứng minh native scene mất vì lock/background. B0 phải giải quyết foreground/scene owner và teardown. LOG5 có marker QA176 `touchowner-stop reason=scene-background-or-external-window-lost`, `dock-reply reason=no-fresh-foreground-session`, không chỉ là giả thuyết process sống/chết.
3. **OmniCar declaration:** `_loadFromProxy:` + `CRCarPlayAppDeclaration` theo tài liệu OmniCar chỉ dành cho app **bridge thiếu declaration**; Maps/Waze đã có declaration thật thì không áp dụng mắt 7 và giữ nguyên. Declaration không tạo entitlement/CarPlay native lifecycle hay bằng chứng Home icon.
4. **Cổng giao A/B:** sau khi B1 thay đường trình bày Maps bằng *native CarPlay dashboard scene*, bắt buộc **test lại idle-hide → chạm đầu chỉ wake → chạm sau vào Maps** ngay trên scene native, không SWAP, không thao tác Maps ở chạm đầu. H1 PASS trên scene hosted không tự động được mang sang native. A1/A2 vẫn làm trước cho YouTube/GOFA hiện đang hosted.
5. **A1 hiện tại:** "giữ hook QA176" chỉ có nghĩa lấy làm nền truy vết, không phải giữ hành vi lỗi. Giữ một hook app-side scoped; đo then sửa đúng delivery/capture, không lặp lại cài mới hay rollback cơ học QA172. Ngoài ra phải đo cả **direct-logo/host touch**; app-side `UIApplication sendEvent:` không tự sửa đường chạm nút logo của SpringBoard.

### Sửa sai/định danh chính xác từ raw LOG5

- Trong đúng `build=0.0.176~appwake1`, tìm được **11** `logo-two-axis-drag-begin-no-hold`, **6** `command-dispatched action=SWAP`, **6** `qa179-logo-idle-red-border-hidden-visual-only`, **0** `qa177-app-touch`, **0** `qa177-recall`, **4** `touchowner-stop` và **4** `dock-reply reason=no-fresh-foreground-session`. Vì vậy nói **không có SWAP trong QA176** là sai; nhưng việc SWAP gắn với **cú chạm đầu vào app-pane sau ẩn** chưa có bằng chứng.
- Ví dụ chính xác: UTC `07:33:40.839601` marker `qa179-logo-idle-red-border-hidden-visual-only` (theo source phát khi `!visible`). Sau đó `07:33:42.498635` `logo-control raw-began id=5`, `07:33:42.519804` `logo-two-axis-drag-begin-no-hold`, `07:33:42.589263` `raw-ended id=5`, `07:33:42.611698` `divider-axis-end`; tiếp theo `07:33:44.007072` `logo-control raw-began id=6`, `07:33:44.120611` `command-dispatched action=SWAP seq=4` và `swap-button`. **Không khẳng định id=5 đã SWAP**: log chứng minh direct-logo touch vẫn vào logic kéo sau marker hidden và id=6 sau đó tạo SWAP. Cần thử rõ lộ trình first hidden touch trên app-pane và direct-logo như hai đường độc lập.
- Cổng A mở rộng: khi đang ẩn, chạm vào vùng logo/divider cũng phải **chỉ gọi hiện logo**, không kéo divider/SWAP, cho tới thao tác kế tiếp. Đường host này không được coi là đã sửa chỉ vì app relay có chặn.

### Thứ tự/giới hạn đã cập nhật

**A1:** trên QA176 đo app relay, touch scene/provenance iPhone vs CarPlay, keyboard known/unknown, state plist accessibility, transport result/host ACK và direct-logo path; sửa chỉ bằng bằng chứng. **A2:** ba chu kỳ đầu-chỉ-wake/sau-thao-tác đúng, trên app hosted YouTube/GOFA lẫn direct-logo, không SWAP hoặc phá bàn phím. **B0:** chứng minh Dashboard foreground owner/scene id và contract private API trên iOS16.7.16; đối chiếu hồ sơ DuoNavi/OmniCar có dẫn mục. **B1:** một Maps native trong ô + DuoFace vẫn active/visible + live pixel/touch; picker/roster thực tế; **test lại first-touch wake ngay trên native Maps**. **B2:** app khác, đa ô, resize, return/Home, keep-alive khi cần. Không dùng ACK hay CI làm bằng chứng CarPlay runtime PASS.

Người gửi cho biết họ đã đọc bản cục bộ DuoNavi 10.262 dòng và OmniCar 14.286 dòng, có chỉ mục `OMNICAR_APP_BAN_DO.md` / `OMNICAR_CO_CHE_APP.md`. Đây là **thông tin do người gửi cung cấp**, không được ghi là đã mở/kiểm chứng độc lập trong phiên này.

**Thực thi:** chỉ bổ sung tài liệu/nhật ký GitHub, KHÔNG sửa source/build/CI/DEB/Sileo và KHÔNG có test xe mới. Giữ rollback 174/175/176, keyboard/GOFA/YouTube và các giới hạn hiện có.
