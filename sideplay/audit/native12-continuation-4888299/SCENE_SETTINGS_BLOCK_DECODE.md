> **ĐÍNH CHÍNH SAU KHI ĐỌC BYTE SELREF THẬT** (CI [39738620890](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39738620890) SUCCESS): selref **0x37db28** của cả `af0f8` và `af1a0` là cùng con trỏ raw `d03c2f0000000000` → VM `0x2f3cd0` → selector **`removeFromSuperview`**. Chứng cứ `sideplay/audit/native12-continuation-4888299/dismiss-selref/ORIGINAL_DISMISS_SHARED_SELECTOR.json`, SHA original Dashboard `9e02a4...`. Do đó chú thích llvm `af1a4 invalidate` là SAI, còn `af0fc` cũng không phải `view`. Callsite thật: `af0fc` gỡ view của appController; `af1a4` gỡ subview thứ hai của bridge. `af170..af180` mới là đường `invalidate` của controller con. **Không được tự gọi scene.invalidate như đã suy diễn ở các báo cáo cũ**. Identity/ivar type của subview thứ hai chưa được chứng minh bằng selref này.
>
# Native12 ORIGINAL scene settings block: giải nghĩa lời gọi bằng ARM64, không phỏng đoán (2026-10-22)

## Nguồn thật và phạm vi

- Original Native12 DEB pinned commit `1286a3ef868cf7e29804bcddf7e20b2eae707ce1`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; `DuoFaceDashboard.dylib` SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`. Không dùng DuoNavi/SidePlay làm bản gốc; không chép Mach-O vendor vào app mới.
- [GitHub Actions 39737949588](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39737949588) **SUCCESS**; bản lưu thật `sideplay/audit/native12-continuation-4888299/scene-block-invoke/SCENE_SETTINGS_BLOCK_INVOKE_ARM64.json`, đúng **118 instruction**, range `0xadc74..0xade4c`, byte nguồn/hash và metadata đều kiểm tra. Lần thử đầu 39737765754 FAIL do `llvm-objdump` không có PATH trong *cùng* step, không phải lỗi nhị phân; sửa `ebe747e2`, lần 39737949588 PASS.
- Caller `CBBridgedUIAppView.updateSceneSettingsFrame` IMP `0xad5bc`: `adaa8 adr x8,#460` tính invoke PC = `0xadc74`; `adab8 stp x8,x9,[sp,#0x20]` ghi invoke+descriptor vào block, `adabc stp d8,d9,[sp,#0x30]` capture native width,height, `adac0 add x2,sp,#0x10`, `adac4 x0=x25(scene)`, `adac8 x1=x26(updateSettingsWithBlock:)`, `adacc objc_msgSend`. Đây là đường gọi block **của scene**, không phải tín hiệu Zoom hay AVAudioSession.

## Đúng thứ tự lệnh trong block invoke `0xadc74`

Chú thích `objc message` trên lệnh `bl` dễ sai vì không theo lại x1; tra selector vừa nạp vào x1.

| PC gốc | Đối tượng / điều kiện | Lệnh đã chứng minh |
|---|---|---|
| `adc84..adc90` | x21 block, x19 scene **settings object** (argument thứ 2 của block) | giữ settings để sửa trong block |
| `adc98..adcb0` | `respondsToSelector:setFrame:` trên settings | nếu có, tại `adcb4..adcc8` gọi `setFrame:` với origin zero và width/height từ block captures `[x21,#0x20]` |
| `adcd0..adcfc` | `class_getInstanceVariable("_frame")` | nếu ivar tồn tại, lấy offset và set origin (0,0) + native width,height vào `_frame`, dù setter có hay không |
| `add04..add30` | `respondsToSelector:setForeground:` | truyền YES (w2=1) |
| `add38..add64` | `respondsToSelector:setOccluded:` | truyền NO (w2=0) |
| `add6c..add98` | `respondsToSelector:setUnderLock:` | truyền NO |
| `adda0..addcc` | `respondsToSelector:setCanShowWhileLocked:` | truyền YES |
| `addd4..ade00` | `respondsToSelector:setDeactivationReasons:` | truyền 0 |
| `ade08..ade34` | `respondsToSelector:setIdleModeEnabled:` | truyền NO |
| `ade38..ade48` | cleanup release | return |

**Không được thay thế tất cả bằng một `setFrame` trên UIView**: block chỉnh *FBS scene settings* và cờ foreground/occlusion/lock, không chỉ điều chỉnh layer của app. `DFSceneHost.layoutScene` hiện chỉ transform UIKit + commit child2,child3,parent2 ở `commitSceneGeometry:`; chưa có tương đương scene settings mutation. Đây là GAP **đã chứng minh bằng instruction gốc**. Parent/child setters và KVC fallback đã nối trong `0.1.42`, nhưng không đủ để gọi media parity.

## Ranh giới an toàn để triển khai tiếp

- Cần xác thực scene settings receiver thuộc scene đang hosting app thật; `DFSceneHost.pollScene` đã có `sceneHandle`, `sceneIfExists`, `isHostingAnApp`, `viewAttached` gate nhưng đó chỉ là readiness, không chứng minh `updateSettingsWithBlock:` khả dụng trên iPhone X.
- Trước khi thêm block mutation, phải kiểm trace của bản Native12 `dismiss` IMP `0xaf01c` và `DFSceneHost.stop` để hiểu cờ `setForeground`, `setOccluded`, `_frame` sẽ được phục hồi/hủy lúc Home/ExitSafeMode. Không tự bật foreground hay `setCanShowWhileLocked:` khi chưa giải teardown; đây là thay đổi trạng thái hệ thống.
- Cần test thực sau khi có implementation theo ABI: hai video/apps, seek/play/audio, resize, Home/Close/respring, device iOS16. Đồng thời giữ `UIInterfaceOrientationPortrait=1` theo bản original. Không đồng nhất build/test tĩnh với kết quả thiết bị.
- Original blocker `0xadc74` đã **giải mã được invoke body**; nội dung block bây giờ có bằng chứng thực. Chưa có mã mới thực thi các setters trên scene, chưa tuyên bố fix video hoặc ExitSafeMode.


## Kiểm tra teardown thật trước khi can thiệp block

Đọc lại **111 instructions nguyên văn** của `CBBridgedUIAppView.dismiss` IMP `0xaf01c` tại `gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`, cùng source `DFSceneHost.stop`. Không lấy nhầm DuoNavi 1.0.4 dismiss `0xaedf8`.

- `af03c`: trên **CBBridgedUIAppView x19**, setter `setInvalidated:YES`; `af054` setter `setHosting:NO`. Hai setter này trên bridge view **không phải** chắc chắn có trên `SBAppViewController` độc lập; không tự gửi selector sang sai receiver.
- `af060` load controller con từ ivar `[x19,x23]`; `af088..af0ac` appearance NO nếu selector có; `af0c4..af0d8` yêu cầu mode=0 nếu có; `af118..af130` willMove parent nil; `af148..af158` remove parent nếu có; `af170..af180` invalidate controller nếu có; `af184..af18c` nil ivar và release.
- **Cảnh báo sai chú thích thực tế:** `af0f8` và `af1a0` đều nạp **cùng selector ref** `[x22,#0xb28]`; `af0fc` gọi nó trên app view, `af1a4` gọi trên đối tượng thứ hai `[x19,x20]`. `llvm-objdump` annotate `af0fc` là `view`, `af1a4` là `invalidate` nhưng cả hai **cùng địa chỉ selector**; hai tên annotation không thể đồng thời chính xác. PHẢI resolve byte selref trước khi kết luận `af1a4` là `scene.invalidate`. Chưa vá `DFSceneHost.stop` theo chú thích này.
- Độc lập `DFSceneHost.stop` đã idempotent `self.stopped` + invalidate timer + appearance NO + mode0 + detach + invalidate appController. Hiện không sở hữu instance `CBBridgedUIAppView`, nên không có đối tượng hợp lệ để gọi hai setter bridge-view gốc. Chưa có bằng chứng an toàn rollback cờ scene settings khi CarPlay Home/ExitSafeMode.
- **Giới hạn:** việc original block đặt `setForeground:YES`, `setOccluded:NO`, `setCanShowWhileLocked:YES` đã có byte-proof, nhưng chưa được nối live vì phải map đúng scene/settings ownership và teardown. Đây là khác biệt đã định danh, **không phải kết quả đã sửa**. Tiêu chí bổ sung: resolve `[x22,#0xb28]` bằng Mach-O selector refs và tra owner ivar type, sau đó implement nhỏ nhất và device verify.
