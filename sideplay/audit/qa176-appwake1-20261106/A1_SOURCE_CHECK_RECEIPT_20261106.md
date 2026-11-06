# A1 logo wake — kiểm tra tĩnh nguồn sau sửa (06/11/2026)

**Repo/nhánh:** `chuongnguyen89dn-ui/Duoface` / `fix/qa180-owned-wake-map-replace-20261106`

**Phạm vi:** Sửa mã nguồn A1 cho direct-logo/divider, relay app-scene, keyboard và nhận tín hiệu. Không phát hành `0.0.176~appwake1` dưới cùng số phiên bản. Mốc này ghi nhận kết quả **kiểm tra cấu trúc nguồn (static source guards)** bằng công cụ GitHub kết hợp JavaScript kiểm tra các file fetch trực tiếp; không phải thực thi Python unittest, Objective-C model hoặc iOS compile.

## Mã đã ghi và đọc lại

| Thành phần | Blob GitHub đã đọc từ nhánh |
|---|---|
| `sideplay/duoface-native-scene-host/DFNative12Chrome.m` | `4e07ba3df0716ce41b1ca66cb144d3e7f1f6407f` |
| `DFAppWakeGate176.h` | `84f20cc09b2669c009d337ab83727bde74f79b04` |
| `DFAppTouch177.h` | `732f39c751134c4012f9f4cbf31d40c3a1503c62` |
| `DFSceneHost.m` | `769b397d0feaf731da401bc61fa792f382ca0bba` |
| `DFSceneHost.h` | `a9661c782317e4e0eddb40770a6ff2f3d51dd679` |
| `tests/app_wake_176_runtime.m` | `00d5defbd255e309bd4e1489c2c814fbccfa3ca3` |
| `tests/test_qa176_a1_wake_source.py` | `9542642892e59cf3274447ead3b1650908f18e3f` |
| `tests/test_qa172w2_wakefix2.py` | `9ae77871ab511615a9ac30c3eed87fde0f5946b8` |
| `tests/qa180_uikit_stub/UIKit/UIKit.h` | `ef904e0f51dec4dca428a75183cf5377eec3b757` |
| `.github/workflows/duoface-176-owned-base-regression.yml` | `ac41d1852cb7ddf4fe582b85aeab51da4dcd41ae` |

**Trình tự đã làm:** dùng GitHub connector `fetch_file` cho 11 file, kiểm 26 liên kết nguồn và guard (wake-only trước drag, movement suppression, first release no swap, nhận hidden touch ngay shouldReceiveTouch trước pan slop, sender chỉ commit khi notify thành công, scene provenance, keyboard known/visible, reserved/mixed-scene path, host visual instrumentation, synthetic model 3 cycles), kiểm cân bằng delimiter {}/[]/() trong 8 mã Objective-C/headers, tổng **34/34 kiểm tra cấu trúc PASS**. Kết quả này không chứng minh compiled code hoạt động trên iOS.

**Thực thi CI thực tế:** chưa xác minh. Workflow `.github/workflows/duoface-176-owned-base-regression.yml` có `push` branch scope và các bước: negative control gate QA176, Python source test, compile/chạy Foundation/CoreGraphics ObjC synthetic gate, iOS arm64 syntax. Nhưng `fetch_commit_workflow_runs` GitHub connector chỉ trả PR-triggered runs, không trả push; `get_commit_combined_status` trả danh sách rỗng; truy cập github.com/API từ container không phân giải DNS; môi trường hiện tại không có `xcrun` hay iOS/macOS SDK. **Không có run ID/job log PASS cho sửa mới.** Không báo `CI_PASS`.

**Nghi vấn còn mở quan trọng:** Equality giữa `FBScene.identifier` (SpringBoard source) và `UISceneSession.persistentIdentifier` (app UIKit) chưa kiểm chứng trên iOS16.7.16. Gate fail-open khi không match; logo có thể chưa wake, nhưng không làm mất chạm iPhone. Record `qa176-a1-relay-scene-diagnostic match` + `wakeStateReadable` mới kiểm được trên xe. Log `qa176-a1-host-wake-received` và `qa176-a1-host-wake-visual-state` phải xuất hiện cùng session/gesture trước khi A2 PASS. Host direct-logo cần `qa176-a1-direct-logo-hidden-contact-reserved`, `qa176-a1-direct-logo-wake-ended-no-swap`.

**A2 nghiệm thu trên xe (chưa chạy):** tối thiểu 3 lần hide→first wake-only→second app receives; cả hosted YouTube/GOFA, direct-logo và divider, app iPhone screen, bàn phím, contact multitouch, không SWAP/pan ở cú đầu; kiểm logo vẫn tự ẩn ~4s và không ảnh hưởng keyboard. 
**B0 native maps:** xem `sideplay/audit/qa176-appwake1-20261106/QA176_B0_NATIVE_MAP_FOREGROUND_20261106.md` (readback SHA `b54ce811e3d123788d1ea3221d9babb7e10d0dbd`). `B0` mới là nguồn/LOG5 phân tích, `B1` native-map live scene/foreground + B1-wake trên scene native chưa thực hiện.

**Kết quả:** `CODE_WRITTEN=YES`, `SOURCE_CHECKS=34/34_PASS`, `CI_RUN_VERIFIED=NO`, `SIGNED_DEB=NO`, `SILEO_PUBLISHED_NEW_VERSION=NO`, `DEVICE_TESTED_NEW_CODE=NO`, `MAPS_B1_FIXED=NO`. Không đổi các DEB rollback QA174–176, GOFA/media/keyboard source gốc ngoài phạm vi app touch và các guard cần thiết.
