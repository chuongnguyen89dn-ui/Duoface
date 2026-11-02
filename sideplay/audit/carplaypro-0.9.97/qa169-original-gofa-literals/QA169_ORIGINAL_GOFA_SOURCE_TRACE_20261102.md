# QA169 — Đường nguồn GOFA thật từ DEB CarPlayPro Speed 0.9.97

**Ngày:** 2026-11-02. **Nguyên tắc:** đây là kết quả phân tích mã máy gốc; không phải source Swift nguyên bản, không cần/được sao chép bản quyền, không khai thác giấy phép. Sự tồn tại tên khóa trong binary không tự chứng minh GOFA ở thiết bị cung cấp đối tượng đúng kiểu.

## Nguồn kiểm chứng

- DEB gốc: `sideplay/audit/com.carplaypro.speed_0.9.97_iphoneos-arm64.deb`, SHA256 `e5b0918b3bc1948420f37a8a9e21365756da46fba44d582a3f2893aee9b4102f`.
- Dylib trích từ DEB gốc: `main:sideplay/audit/carplaypro-0.9.97/unpacked/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SpeedAlerts.dylib`, Git blob `f2b7d46e7ace8dfb533e9e9a843eae9616523486`.
- Recovered original disassembly 60,552 arm64 instructions `qa166-gofa-dataflow/FULL_ORIGINAL_ARM64_DISASSEMBLY.txt.gz`. Script QA169 `sideplay/tools/forensic_carplaypro_gofa_swift_literals.py`, [CI run 41370313357](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41370313357) SUCCESS; exact output `GOFA_SWIFT_LITERAL_REGISTER_TRACE.json`, `GOFA_SWIFT_LITERAL_REGISTER_TRACE.md`, `SHA256SUMS.txt` in this directory. CI checked actual original dylib Git blob before parsing independent, archived results into the **DuoFace repository**, no DEB/Sileo release.

## Bằng chứng tuyến dataflow *gốc*, không suy đoán

1. Original initializer `0x3ce1c` registers `NSNotificationCenter addObserverForName:object:queue:usingBlock:` for exact `notificationNextBoard`, `notificationOtherBoard` and `notificationSpeedBoard` (original ObjC CFString/NSArray and ARM64 verified in QA166). Callback blocks resolve to **0x3cfb4 for alert**, **0x3d468 for speed**.
2. Actual alert callback `0x3cfb4` invokes original `_SAGofaAlertPayload` at `0x3e93c`, entering Swift function `0x3e940`. Original speed callback `0x3d468` invokes original `_SAGofaSpeedPayload` at `0x3e38c`, entering Swift function `0x3e390`.
3. **New exact original code-level literal proof, reconstructed from MOV/MOVK pairs in specific GOFA Swift functions:**
   - Speed Swift `0x3e390`: `pushSpeedBoard` from machine addresses `0x3e494 + 0x3e4a4`, plus literal `limit` at `0x3e678`, `speed` at `0x3e740/0x3e780`, and `userSpee` substring at `0x3e6ec` (candidate `userSpeed`).
   - Alert Swift `0x3e940`: `pushNextBoard` from `0x3e98c + 0x3e97c`; exact `traffic_sign_id` appears twice from `0x3f230 + 0x3f244` and `0x3f25c + 0x3f26c`. Separate immediate literals: `identity` `0x3f5fc`, `sign` `0x3f614`, `latitude` `0x3f638`, `longitud` (8-character prefix of longitude) `0x3f654`, `group` `0x3f824`, `points` `0x3f848`. Actual cast via imported Swift runtime in this helper had been verified in QA166.
4. Navigation original is a **different** subsystem: original hook table points at class `CPNavigationSession`, `_MSHookMessageEx` calls `0x2fae4` and `0x2fb00` (exact selectors here NOT established); proven selectors `cancelTrip` at `0x2fb20`, `finishTrip` at `0x2fb40`, and `pauseTripForReason:description:` at `0x2fb60`. Do **not** infer that GOFA notification's object is Apple `CPManeuver`; QA168's fallback is only a conditional independent implementation, **not** the CarPlayPro-derived GOFA field reader.

## Source gap and correction

**What is now actually known:** confirmed original notification names, callback/Swift-extraction addresses, exact original model-related text tokens `traffic_sign_id`, `latitude`, `limit`, `speed`, `pushSpeedBoard`, `pushNextBoard`. These are the only safe building blocks for a first-party GOFA adapter.

**What is NOT known:** original Swift `GOFA.DatapointModel` ABI and whether original helper returns Swift object/dictionary or other type, exact key-value mapping inside callbacks, traffic-sign code taxonomy, actual posted runtime notification shape, route/direction provider object and user-facing camera/limit distance validity. A machine-code token is not a live traffic event. **Do not show made-up alerts or copy vendor code/licensing.**

**User correction:** previous QA165 source `CoreLocation` alone and QA168 `CPManeuver` conditional path were not a faithful original GOFA data route. **QA168 is not a completed feature and must NOT be published as 'real camera/turn warnings'.** Retain it only as a separate experimental fallback; focus next edits on original GOFA board/Swift model schema.

**Exact next static step:** trace machine code in `0x3e390` and `0x3e940` around above literal creation and Swift `dynamicCast` to determine object shape and access strategy, plus original `CPNavigationSession` hook selector values in `0x2fae4/0x2fb00`; save addresses and raw instructions. Implement only fields supported by this evidence and runtime samples, gate freshness/source/validity, test isolated protocol and build via existing DuoFace CI. No new public Sileo package in this forensic run.
