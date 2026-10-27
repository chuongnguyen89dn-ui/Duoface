# Native12 có hai tầng xử lý scene mà DuoFace .81 chưa triển khai

Ngày kiểm tra: 27/10/2026 (Asia/Ho_Chi_Minh). Repo DuoFace, nhánh
`feature/duoface-jb-embedded-appbridge-20261020`, đầu vào `3e695f4c5f5b8ecadeaf85426967367e780adea2`.

## Kết quả mới, có kiểm tra trực tiếp byte ARM64

Không quay lại .37. Đã đọc checkpoint .37/.74/.80/.81 và giữ nguyên UI/Dock/Zoom/logo.
Đã tải và giải nén DEB tham chiếu bất biến từ commit
`1286a3ef868cf7e29804bcddf7e20b2eae707ce1`, đường dẫn
`dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`.

- SHA256 DEB: `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- SHA256 Dashboard: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Chỉ đọc/giải mã; không chạy, sửa hoặc cài binary tham chiếu.
- Công cụ mới dùng lại `sideplay/tools/native12_objc_stub_decoder.py` để đọc section Mach-O,
  Capstone 5.0.7 để giải mã; tự kiểm SHA và giải đúng tham số đăng ký hook.
- Bằng chứng đầy đủ: [HOOKS_AND_ARM64.json](HOOKS_AND_ARM64.json).

### 1. Hook tại đầu vào FBScene — không phụ thuộc resize

Initializer `0x2c7c54` đăng ký:

| Receiver / selector | IMP thay thế | Nơi giữ IMP trước |
|---|---|---|
| `FBScene updateSettings:withTransitionContext:completion:` | `0x2c7e08` | `0x382108` |
| `SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:` | `0x2c8ca8` | `0x382150` |
| `SBAppViewController sceneHandle:didDestroyScene:` | `0x2c8ef8` | `0x382158` |

Tổng cộng initializer này có **11** đăng ký, gồm 10 `bl` và 1 tail `b` đến
`MSHookMessageEx`. Báo cáo graph cũ chỉ đếm 10 `bl`; script mới bao gồm tail call.
Không được suy rằng 11 hook này đều là phần cần chép vào DuoFace.

Ở `0x2c7e08`, đường đi có các điều kiện:
`sharedInstanceIfExists` → `isUIAppBridging` → lấy bundle từ helper `0x2c6958`
→ `shouldBridge:`. Phần foreground:

- `0x2c7fc0..0x2c7ff0`: kiểm khả năng đọc và đọc `isForeground`.
- `0x2c800c..0x2c8024`: đăng ký selector `setForeground:`, đặt `w2=1`, gọi setter.
- Có fallback ghi ivar và các chính sách frame/occlusion/lock/idle trong binary gốc;
  **đây chỉ là mô tả, không đề nghị sao chép hoặc áp dụng các fallback này**.
- `0x2c835c..0x2c8374`: gọi IMP trước đó bằng `blr x8`, truyền lại scene, selector,
  settings, transition context và completion.

Do đó, nhận định cũ chỉ xem `updateSceneSettingsFrame` đã bỏ sót một tầng:
gốc xử lý ở **biên cập nhật scene**, ngoài transaction do resize của bridge tạo ra.
DuoFace .81 chỉ gửi foreground/background trong `commitSceneGeometry:` khi frame khác;
không có cơ chế tương ứng tại đầu vào này. Đây là khác biệt mã thực tế, không phải
chứng minh actor nào đã gửi foreground NO trên thiết bị.

### 2. Gốc chặn đường gọi observer đúng tại hàm gây assertion

Đã giải mã trực tiếp `0x2c8ca8..0x2c8ef8` và đối chiếu literal/selector:

- Kiểm associated object `CBDuoFaceHosted` / `CBCarBridgeHosted` trên controller;
  nếu có thì chuyển sang đường cleanup/return **không gọi IMP gốc**.
- Nếu không thấy trên controller, kiểm trên sceneHandle truyền vào, rồi trên
  `controller.sceneHandle`; có marker cũng không gọi IMP gốc.
- Nếu không có marker nhưng receiver hỗ trợ `automatesLifecycle` và trả NO,
  nhánh `0x2c8e7c` cũng đi cleanup/return.
- Chỉ đường còn lại mới gọi original observer tại `0x2c8e9c` qua `0x382150`.
- Có exception catch trong implementation gốc; không xem việc catch/return là
  bằng chứng scene hợp lệ hoặc playback đúng.

Điểm nối cụ thể: original `startInParentViewController:` đã gắn marker lên controller
và controller con (audit `original-host-lifecycle-imp`). **Marker có consumer thực sự**,
không phải nhãn trang trí. DuoFace .81 gọi `setAutomatesLifecycle:NO` nhưng khởi tạo
`SBAppViewController` thông thường và không có consumer/adapter tương ứng cho callback này.
Vì vậy, nếu incoming foreground NO đến host Live, Apple observer vẫn được gọi và có thể
assert, đúng địa điểm trong IPS. Đây là khoảng trống cụ thể hơn so với nhận xét chung
"thiếu lifecycle"; vẫn chưa chứng minh là nguyên nhân duy nhất của .81.

**Không tuyên bố Native12 không bao giờ crash:** nó tránh chạy observer ở một số nhánh;
đó không đồng nghĩa đã xử lý đúng mọi chuyển trạng thái. Không đưa hook bỏ qua callback
toàn cục vào DuoFace để chỉ che lỗi.

## Đối chiếu lại crash thực tế

Đã chạy parser hiện có trên `DuoFaceAudit 5.txt` và hai IPS .80 từ main commit
`05739ff4c85ef95f9de2a07f41dc8b1bd18aeba9`. Xem [REPLAY_080.txt](REPLAY_080.txt).

- YouTube PID65025, capture 19:44:15.8776 +0700: SIGABRT ở scene observer;
  khoảng 9.851 giây sau frame request.
- TikTok PID65079, capture 19:44:56.5429 +0700: SIGABRT cùng observer;
  khoảng 7.279 giây sau frame request.
- **Cả hai IPS .80 không nạp module OmniCar** theo `usedImages`. Không cần giả thuyết
  OmniCar đồng thời chạy để giải thích hai lần này. Đây không phải test loại bỏ mọi tweak khác.
- .80 không có reason riêng trong fatal log; không gán reason .77 cho .80 như sự thật.
- Các log hiện có trên main đến 19:45; chưa có IPS khớp runtime .81.
- `DFTouchOwnerProbe.m` ở source .81 vẫn ghi fatal nhãn `.79` và chuỗi literal `\\n`;
  đây là lỗi provenance/format đã thấy, không phải nguyên nhân crash. Fatal log không có
  PID65025/65079; không thể suy rằng handler còn làm chủ lúc crash chỉ từ dòng armed.

## Hướng sửa được đề xuất từ bằng chứng này

**Đổi điểm sửa từ resize sang hợp đồng vòng đời tại biên scene update và callback.**
Hai phần phải thiết kế cùng nhau, không chỉ chèn thêm `setForeground:YES`:

1. Đăng ký chủ sở hữu first-party bằng identity thực của controller + sceneHandle +
   FBScene + generation, trước khi nhận callback. Không dùng marker của vendor hoặc
   kiểm mỗi bundle ID (có thể nhầm scene đang mở trên iPhone).
2. Tại biên update, phân biệt yêu cầu giữ pane Live với background/close hợp lệ.
   Chỉ áp dụng chính sách cho scene còn thuộc pane đang hoạt động; giữ nguyên context,
   completion và các trường không liên quan. Mọi scene khác đi nguyên đường hệ thống.
   Cần trace trước/sau + caller để phân biệt nguồn NO; chưa được xác minh actor.
3. Callback của host quản lý thủ công cần adapter riêng, có xử lý settings/destroy;
   không chỉ return để che assertion. Không bỏ qua callback của controller không thuộc
   DuoFace. Không bắt rồi nuốt exception của hệ thống.
4. Close/Home/disconnect phải thu hồi ownership trước khi request mode0/invalidate,
   để policy giữ foreground không ngăn hệ thống background hợp lệ. Scene generation cũ
   phải pass-through, không nhận policy của app mới.
5. Tách ACK frame/foreground thực nhận khỏi log dispatch. Sửa nhãn fatal/định dạng và ghi
   đồng bộ ngay trước callback dễ assert, tránh trông chờ polling 350ms.

### Gate trước phát hành

- Kiểm ABI runtime đúng lớp/selector, preserve context/completion exactly once,
  không update đệ quy; test owner/nonowner, stale generation, close, scene destroyed,
  background hợp lệ. Đây là tiêu chí cho bản sửa tiếp theo, **chưa chạy**.
- Build staging bằng pipeline hiện có. Không coi source test hoặc compile PASS là device PASS.
- Trên thiết bị: YouTube OPEN trước, sau đó PLAY/seek; TikTok/Facebook; hai ô;
  Close/Home/reopen/disconnect; UI/Dock/Zoom/logo không hồi quy.
- **Chưa sửa runtime, chưa build DEB, chưa phát hành Sileo, chưa xác nhận hết crash** trong lượt này.
  Không quay lại .37 hoặc thêm bản .82 chỉ vì audit tĩnh PASS.

## Lệnh tái lập và kết quả

Thư mục chạy: root checkout DuoFace. Công cụ Python + capstone 5.0.7 + dpkg-deb.
Đầu vào không chứa bí mật; raw log chỉ tải tạm, không commit lại dữ liệu thiết bị.

```sh
sha256sum /tmp/native12.deb
dpkg-deb -x /tmp/native12.deb /tmp/native12-ref
python sideplay/tools/audit_native12_foreground_hooks_20261027.py \
  --binary /tmp/native12-ref/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib \
  --out sideplay/audit/native12-foreground-hooks-20261027/HOOKS_AND_ARM64.json
python sideplay/tools/duoface_foreground_crash_replay_20261027.py \
  --audit /tmp/duoface-audit5.txt --ips /tmp/df-194420.ips /tmp/df-194502.ips
python -m py_compile sideplay/tools/audit_native12_foreground_hooks_20261027.py
```

Kết quả thực: SHA PASS; 11 registrations và exact replacement PASS; wrong-input SHA rejection
PASS; Python syntax PASS; 2 crash replay thành công. [VALIDATION.txt](VALIDATION.txt).
Các kiểm tra này chỉ xác minh công cụ phân tích/bằng chứng, không kiểm chứng bản sửa iOS.

Nguồn ZIP kỹ năng đã đọc và giải nén từ Gpt-training-: 01-github-continuity,
02-ios-deb-ipa-carplay, 05-research-debug-testing. Không sửa repo kỹ năng hoặc repo khác.
