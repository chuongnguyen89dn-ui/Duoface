> **ĐÍNH CHÍNH PHẠM VI — 2026-10-27, yêu cầu trực tiếp của người dùng:** Câu hỏi "Bản nào từng thành công? Ko crash?" là về **chỉ các phiên bản DuoFace độc lập đang phát triển**. Trả lời trước đã chuyển trọng tâm sang QA OmniCar và gọi đó là baseline DuoFace; **SAI PHẠM VI**. Không được lấy QA5/QA7/QA16/QA19/QA20 của OmniCar làm kết quả QA, bản chạy được hoặc rollback của DuoFace. Các ghi chép OmniCar bên dưới chỉ là lịch sử đối chiếu, không tham gia quyết định chọn phiên bản DuoFace. Không tự ý chuyển repo, phát hành gói OmniCar hay dùng OmniCar để thay DuoFace.
>
> **TRẢ LỜI ĐÚNG — CHỈ DUOFACE:** `0.0.37~native12dockzoom1` là bản DuoFace độc lập duy nhất trong dữ liệu QA vừa kiểm tra mà **người dùng đã báo YouTube từng phát được video**, nhưng **xoay sai**; chưa được xác nhận **không crash ổn định** trên nhiều phiên, bản nominal rollback từng vẫn bị bó. DEB SHA256 `2b6f274e684e5a6f1008dac960c87ff51744fddb5342ce42fcd74e5c61314beb`, nguồn nativehost đúng `7cd4004d422a79d9df85f23f16ff8f6f38af1125`, gồm bốn UIWindow độc lập. `0.0.9~gesturerelay1` chỉ từng xác nhận cảm ứng/UI CarPlay, **không xác nhận media**. Các bản .74/.77/.80 có sự cố SpringBoard, .81 user báo crash ngay khi mở YouTube. **Chưa có bản DuoFace nào được xác nhận đầy đủ không crash + đúng orientation + phát video + split.** Báo cáo chính `V37_NOT_FULLY_RESTORED_ROOT_DIFF_20261026.md`; việc phục hồi v37 ở .69/.70 chưa đúng kiến trúc cửa sổ. Những DEB gốc của OmniCar/DuoDash chỉ là nghiên cứu đối chiếu **nếu người dùng yêu cầu**, không phải kết quả QA DuoFace.
>
> **NEXT:** Trong `chuongnguyen89dn-ui/Duoface`, đọc đúng nativehost source/deb 0.1.47 đã ghim và so byte/source theo phiên với .81, khôi phục đủ owner/attach/pane-window/layout/close contract nếu chứng minh được; không phát hành .82 bằng suy đoán. Không có thay đổi runtime, build, Sileo hoặc test thiết bị ở checkpoint đính chính.

---

# 2026-10-27 — Kết quả truy tìm QA từng chạy được, và giới hạn “không crash”

**Phân biệt nguồn:** (a) lời người dùng xác nhận thiết bị thật trong lịch sử GitHub, (b) source/DEB/CI checksum, (c) kết luận **không có bằng chứng**. **Không** suy luận “không crash” lâu dài từ một lần mở app hay một workflow CI thành công.

## DuoFace độc lập — video

**Tốt nhất cho mục tiêu YouTube playback trong lịch sử dự án: `0.0.37~native12dockzoom1`, nhưng CHỈ PASS từng phát video; FAIL xoay đúng và không đạt chứng nhận SpringBoard ổn định.**

- Signed .37 immutable: `sideplay/jb-embedded-appbridge/evidence/runs/39748923126/com.duoface.jb.embedded_0.0.37~native12dockzoom1_iphoneos-arm64.deb`, SHA256 `2b6f274e684e5a6f1008dac960c87ff51744fddb5342ce42fcd74e5c61314beb`. Packaging commit `a8cdec6252b0e772faa726e92b84ee66246590ed` imports pinned nativehost 0.1.47 DEB SHA `82b296d4076458ce7259c5987450a48d2ab2b37cf4857fdac8c0eb9d0d989941`, nativehost actual source commit `7cd4004d422a79d9df85f23f16ff8f6f38af1125`. Verified provenance and source differences at `sideplay/audit/native12-039-regressions-20261023/V37_NOT_FULLY_RESTORED_ROOT_DIFF_20261026.md`. User device report: YouTube video played, but rotated incorrectly. Later nominal rollback .37 still boxed UI; **not proven stable/reproducible no-crash**.
- .69/.70 did not restore full .37 four-UIWindow per-pane ownership; switched shared external window from .48, so **do not** describe .69/.70 as a proven rollback or pass. `V37_NOT_FULLY_RESTORED_ROOT_DIFF_20261026.md` has literal source crosswalk.
- .74/.77/.80 had matched SpringBoard SIGABRT scene callback (historical .77 fatal `NSInternalInconsistencyException` Live vs foreground BSSettingFlagNo); .81 public signed/published but USER confirms crash immediately **at YouTube open**, and no new .81-matched IPS. .81 signed package SHA `e03d5b268c6f91ffc40192f45541f8c3e236d98cd731c1e5ed633b8d663604b1`, public Sileo run `40513870384`. **No DuoFace 0.0.x QA validated as persistent YouTube+Maps+video no-crash and correct orientation**.
- Other partials: DuoFace first-party `0.0.9~gesturerelay1` user verified on-device control/touch, not video host stability. `0.1.0~native12+speed8compact` audit intervals without observed abort not proof player works or no crash forever. Original Native12 HUD8 is the user-designated reference; not an independently verified first-party bridge no-crash release.

## OmniCar — real user device QA, strongest working evidence

| QA | Actually user tested | Exact acceptance | Missing/negative | Integrity |
|---|---|---|---|---|
| **QA5** `1.0.3-omnicar5` | YES 2026-10-20 | User explicitly confirmed **YouTube+Map split no longer disconnects**, Map+Map divider/menu returned, Zoom/Swap had previously worked. This is the best device-confirmed *short-session host/split stability* record. | YouTube 3-dot and central circular launcher don't auto-hide at 4s; Solo controls incomplete. NOT a burn-in/indefinite no-crash proof. | DEB SHA256 `7198bce289bd0f7913c4a10c018ab4412207a478ce8a525d8b4674c903665249`, archived `Omnicar/dist/candidates/omnicar-unified-1.0.3-omnicar5/`, CI `39381627621` success, public independent verifier `39381964894` success |
| **QA7** `1.0.3-omnicar7` | YES 2026-10-20 | Exact **QA5 code recovery**, user confirmed OmniCar opens, Map+Map divider returned, native handles hide; other app handles hide. | YouTube-specific 3-dot does not auto-hide; waking hidden map controls sometimes difficult. Not validated all video / fullscreen cases. | DEB SHA256 `fad7e4923f576d248c16ac2b6153b14680ac60116d3316642043edacb8cbdfee`, archive `Omnicar/dist/candidates/omnicar-unified-1.0.3-omnicar7/`, source commit `4eb62400e44951dd380f0aa8125c0525f60f8d17`, CI `39387020866` success, independent public checksum run `39387500822` success |
| **QA16** `1.0.3-omnicar16-youtube-handle-idle` | YES 2026-10-24 | User confirmed YouTube hosted 3-dot **auto-hides** after 4 seconds. Original OmniCar YouTube player retained. | Tap to REVEAL still difficult. Report is not explicit sustained video-playback no-crash PASS. | DEB SHA256 `1500f43c7a9ee6fe0f513569c804abdec8e6647321ddaf89e655ed9787fe9145`, archive `Omnicar/dist/candidates/omnicar-qa16-youtube-handle-idle/`, CI `40051662592` success |
| **QA19** `1.0.3-omnicar19-app-process-wake` | YES 2026-10-27 | User says controls easier to call back, both small 3-dot controls fade. | Center divider knob did not fade; still no exhaustive media no-crash claim. | DEB SHA256 `af6585d750504c1194a756f6b7b3ea8244d53271d115a046380f63c607bde16b`, CI `40446205341`, Sileo checksum passed |
| **QA20** `1.0.3-omnicar20-divider-knob-idle` | YES 2026-10-27 | Center circle fades with **two non-YouTube apps**. | Center circle does NOT fade with YouTube. User-reported regression linked temporally to QA19 input-recall change, exact writer not measured. | SHA256 `405faaafad91948796cf2578b5d8238a1466cd6f4fe3a5c3888a500ca8c6eb19`; audit `Omnicar/audit/OmniCar_QA20_YouTube_only_center_knob_differential_20261027.md` |

**Confirmed failed device outcomes**: OmniCar **QA4** YouTube split crash/disconnect and missing map split menu; **QA6** launch crash/exits and no divider with two maps; **QA8** Solo 3-dot tap crashes; **QA9** general user-reported FAIL; **QA13–15** YouTube orientation regression (QA13 upside-down 180°, QA15 user still wrong). QA17/QA18 wake from video surface device FAIL. None of these count as usable no-crash baselines.

Source verification for QA5/7/16/19/20 device words: `chuongnguyen89dn-ui/Omnicar/tiep tuc du an.md` (GitHub main) entries 2026-10-20 QA5 VERIFIED STABLE / QA7 USER DEVICE PASS / 2026-10-24 QA16 USER DEVICE RESULT / 2026-10-27 QA19 and QA20 device reports, plus the targeted audits:
- `Omnicar/audit/OmniCar_YouTube_AppBridge_UI_owner_QA7_20261020.md`;
- `Omnicar/audit/OmniCar_QA20_YouTube_only_center_knob_differential_20261027.md`;
- `Omnicar/audit/OmniCar_QA20_Regression_After_QA19_Recall_Relay_History_20261027.md`.

## DuoDash and original OmniCar

- **DuoDash vendor**: the analyzed 1.1.3 Fullscreen427 DEB is a **REPACK**, not original stock, and its static ARM64 CI `40445716116` confirms selected method ABI, **not real physical no-crash QA** on target iPhone. First-party `carplaydsp/independent-split/runtime/CPSRuntime.m` is an independent CarPlay Split implementation, **not vendor source and no proven safe video runtime**.
- **OmniCar vendor 1.0.3**: pristine DEB SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd` is a byte-stable design/reference base used in QA5/7 and later; NOT direct 24h no-crash test proof in this review.

## Decision (NO-GO to call any full PASS)

- **Best first-party DuoFace video regression reference = exact .37 immutable DEB**, only video *once* played and orientation failed; source ownership is FOUR independently positioned per-pane windows vs current shared layout after .48. Must not conflate a successful play attempt with complete stable no-crash.
- **Best user-verified OmniCar host + split functional baseline = QA5 and byte-equivalent-source QA7**, with known UI shortcomings, not no-crash long-term guarantee. **Best YouTube 4s fade partial QA = QA16**; **QA19/QA20** trade better recall for center-knob regression. Neither proves complete reliability.
- **No matching device/IPS/SpringBoard PID evidence supports a fully crash-free DuoFace build**. Do not copy vendor license/core, rewrite release pins, or publish speculative .82. No runtime source change, no build, no install, no Sileo update in this read-only QA inventory.
