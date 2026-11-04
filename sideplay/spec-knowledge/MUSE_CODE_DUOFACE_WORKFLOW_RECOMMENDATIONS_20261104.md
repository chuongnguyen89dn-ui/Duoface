# Nâng hiệu quả Muse Code cho DuoFace — nghiên cứu nhiều nguồn và khuyến nghị áp dụng

- Ngày: 2026-11-04 (ICT)
- Repo khảo sát: `chuongnguyen89dn-ui/Duoface`
- Nhánh khảo sát: `spec-main`
- HEAD trước khi lưu tài liệu: `fd67068d4c6aa333ae1c7da6187d57676e3193f1`
- Phạm vi: quy trình nghiên cứu, lập kế hoạch, kiểm chứng và giao việc cho Muse; **không sửa mã nguồn, không build, không publish Sileo, không cài gói**.
- Giả định tên sản phẩm: “Muse AI” trong tài liệu này là **Meta Muse Code**. Nếu đang nói tới một sản phẩm Muse khác, cần đổi bộ hướng dẫn theo đúng sản phẩm.

## 1. Kết luận điều hành

Muse không trở nên đáng tin chỉ vì tăng reasoning hoặc nạp thêm token. Với DuoFace, bước cải thiện lớn nhất là biến Muse thành một **agent có quy trình kiểm chứng và quyền hạn rõ**, được cung cấp:

1. Một nguồn sự thật gọn cho trạng thái hiện tại, thay vì bắt agent đọc toàn bộ nhật ký dài.
2. Các skill theo đúng loại việc: phân tích ABI/hook, truy vết dữ liệu GOFA, đóng gói DEB/Sileo, đánh giá log thiết bị và nghiệm thu.
3. Cơ chế nhiều agent chỉ dùng cho các nhánh nghiên cứu độc lập, đọc-only; chỉ một agent được quyền sửa trong từng worktree.
4. Work order có tiêu chí đạt, bằng chứng, giả thuyết đối lập, điều kiện dừng và rollback.
5. Cổng duyệt riêng cho thao tác rủi ro: private API/hook, thay đổi scene host, cài/gỡ package, phát hành Sileo và test trên máy thật.
6. Bộ kiểm chứng độc lập. Không chấp nhận “Muse nói đã xong” hoặc “CI xanh” làm bằng chứng thay cho kết quả thiết bị.

Meta mô tả Muse Code/Muse Spark 1.2 hướng tới tác vụ code dài, refactor nhiều file, planning, context compaction và phối hợp nhiều agent/tool call. Đây là năng lực nền; dự án vẫn cần cung cấp quy trình riêng để ngăn agent tự suy luận vượt quá bằng chứng.  
Nguồn: [Meta — Introducing Muse Code and Muse Spark 1.2](https://research.meta.ai/blog/introducing-muse-code-and-muse-spark-1-2).

## 2. Những gì đã thấy khi kiểm tra chính DuoFace

### 2.1 Bối cảnh đang bị phân tán và quá dài

Trên `spec-main`, hồ sơ `sideplay/tiep tuc du an.md` khoảng 491 KB; hồ sơ gốc `tiep tuc du an.md` khoảng 699 KB. Hai file có mục đích và lịch sử khác nhau, không nên nạp nguyên khối vào mỗi phiên Muse. README dự án chỉ rõ hồ sơ SidePlay hiện hành và phân biệt hồ sơ lịch sử.

**Hệ quả:** cần memory dạng chỉ mục + các chủ đề nhỏ. Agent phải mở đúng đoạn hồ sơ, WO, log hoặc file source khi có câu hỏi; không được lấy một trích đoạn cũ làm trạng thái hiện tại.

### 2.2 Repo chưa có bộ cấu hình Muse dành riêng cho dự án

Ở cây `spec-main` được kiểm tra, chưa thấy `AGENTS.md`, `.agents/` hoặc `.muse/` ở cấp repo. Vì vậy chưa có một bộ luật riêng được version-control để Muse luôn nạp khi vào DuoFace.

Meta hỗ trợ chỉ dẫn repo qua `AGENTS.md`/cấu hình dự án; memory Markdown trong `.agents/memory/`; skill trong `.agents/skills/<skill-id>/SKILL.md`; hook trong `.muse/hooks.json`. Cần kiểm tra phiên bản cài thực tế trước khi dựa vào từng tính năng.

### 2.3 Lịch sử Muse đã có bài học về sai dữ kiện

Đã đọc ba tài liệu kiểm chứng Muse cũ trong repo:

- `sideplay/audit/native12-logo-touch-20261024/MUSE_AI_TECHNICAL_REVIEW_20261025.md`
- `.../MUSE_AI_ROUND2_GPT_COUNTER_20261025.md`
- `.../MUSE_AI_ROUND3_GPT_CONSENSUS_20261025.md`

Những phản biện đã ghi lại các lỗi cụ thể: nhầm hướng dịch chuyển 12.33 pt từ song song thành vuông góc; mô tả logo là sibling thay vì subview; đề xuất mốc 0.35 giây có thể phá thao tác kéo Ratio sau khi người dùng chờ; marker log không đủ nhận diện trường hợp ratio latch ngay từ mẫu đầu; và đề xuất thay đổi scene/private setter khi chưa có chứng cứ runtime an toàn.

Đây không phải kết luận rằng Muse luôn sai. Nó chứng minh **phải bắt mọi nhận định có đường dẫn file/hàm/dòng hoặc log, và có người/agent khác phản biện độc lập trước khi sửa**.

### 2.4 Những điểm kỹ thuật hiện tại cần Muse đọc đúng trước khi nhận việc

- **GOFA / Speed8:** hồ sơ hiện tại phân biệt rõ tốc độ CoreLocation/GPS với feed traffic/navigation nội bộ GOFA. QA171 là gói chẩn đoán schema, không đồng nghĩa đã giải mã payload hay kết nối cảnh báo/turn thực. Báo cáo QA166 đã truy ra các tên notification và call path tĩnh từ bản tham chiếu CarPlayPro, nhưng payload Swift và mapping runtime vẫn cần chứng minh. Không được tự đặt tên field, tự tạo alert mẫu hoặc coi GPS là feed GOFA.
- **Keyboard QA180/QA181:** QA180 có số đo thiết bị cho thấy một phần chu kỳ Maps không tìm được cửa sổ phím; tỷ lệ được ghi trong STATUS là 3/6 chu kỳ dựng lại được (50%), thấp hơn ngưỡng 90%. Báo cáo QA181 riêng ghi 9 chu kỳ, 6 applied / 3 exhausted (67%), hook-source 0/18; telemetry còn thiếu installPhase nên chưa phân biệt chắc chắn hook không cài được hay getter không được gọi. Do đó phải đối chiếu commit, WO đã được duyệt, log và báo cáo mới nhất trước khi tiếp tục; không chạy lại một WO cũ chỉ vì nó xuất hiện ở đầu file handoff.
- **Chứng cứ phát hành:** QA180 được ghi là đã publish Sileo; điều đó không tự chứng minh mọi tiêu chí thiết bị đã đạt. QA171 được ghi nhận build/sign/archive thành công nhưng chưa publish và chưa device-test. Giữ riêng các trạng thái source, CI, artifact, Sileo, cài đặt và nghiệm thu máy thật.

Nguồn nội bộ chính: `sideplay/audit/qa180-kbcycle-alive-20261103/STATUS.md`, `sideplay/spec-knowledge/BAO_CAO_QA181_VA_HUONG_TIEP.md`, hồ sơ `sideplay/tiep tuc du an.md`, các báo cáo Muse nêu trên.

## 3. Cấu hình dự án đề xuất

### 3.1 Tạo một AGENTS.md ở root

Nội dung nên ngắn, bắt buộc và có thứ tự ưu tiên:

- Đầu phiên: xác nhận repo, branch, HEAD, working tree; đọc README và handoff đúng mục tiêu; xác định WO hiện hành và trạng thái duyệt.
- Trước khi kết luận: ghi đường dẫn file, symbol/hàm, commit hoặc log marker. Phân loại mọi phát biểu thành `SOURCE-OBSERVED`, `STATIC-BINARY`, `DEVICE-OBSERVED`, `CI-PASS`, `PACKAGE-SIGNED`, `SILEO-PUBLISHED`, `DEVICE-VERIFIED`, `INFERENCE` hoặc `UNKNOWN`.
- Với giả thuyết quan trọng: nêu bằng chứng ủng hộ, bằng chứng chống lại, cách kiểm tra phân biệt và điều kiện bác bỏ.
- Không sửa mã khi nhiệm vụ chỉ yêu cầu audit/đánh giá. Không tự mở rộng phạm vi hoặc tự chuyển branch.
- Không đổi file đang đóng băng, private API, ABI, scene lifecycle hoặc đường dữ liệu liên tiến trình khi chưa có WO được duyệt.
- Không cài/gỡ package, phát hành Sileo, chạy lệnh có tác dụng lên thiết bị hoặc thay đổi trạng thái CarPlay nếu chưa có sự cho phép rõ ràng.
- Sau thay đổi: kiểm tra diff, chạy đúng test, ghi kết quả thực tế; không suy diễn device-pass từ unit test hoặc CI.
- Chỉ cập nhật `sideplay/tiep tuc du an.md` khi có thay đổi thật về quyết định, code, test, build, publish, device verdict hoặc blocker. Không tạo handoff trùng.

### 3.2 Dùng project memory thay cho việc nạp handoff khổng lồ

Cấu trúc đề xuất:

```text
.agents/
  memory/
    MEMORY.md
    current-state.md
    architecture-and-frozen-areas.md
    gofa-data-contract.md
    keyboard-qa.md
    deb-release-and-device-test.md
  skills/
    duoface-work-order/SKILL.md
    duoface-abi-hook-review/SKILL.md
    duoface-gofa-adapter/SKILL.md
    duoface-device-evidence/SKILL.md
    duoface-deb-release/SKILL.md
`.muse/
  hooks.json
AGENTS.md
```

Quy tắc memory:

- `MEMORY.md` chỉ là mục lục ngắn, trỏ tới các chủ đề.
- `current-state.md` phải nêu branch/HEAD, WO đang mở, trạng thái duyệt, bằng chứng mới nhất và hành động kế tiếp.
- Mỗi ghi nhớ phải có phạm vi và nguồn. Đánh dấu nội dung lịch sử/đã supersede; không để nhiều quyết định cũ cùng có vẻ đang hiệu lực.
- Chỉ lưu sự thật bền vững và bài học đã kiểm chứng; không lưu câu trả lời Muse chưa được phản biện.
- Không sao chép log/raw dumps vào memory. Lưu chúng trong audit folder rồi ghi đường dẫn + marker + SHA nếu cần.
- Memory nên được cập nhật sau một checkpoint có ý nghĩa, không phải sau mỗi câu lệnh hội thoại.

### 3.3 Tạo 5 skill chuyên môn

**A. `duoface-work-order`**
- Chuyển yêu cầu thành mục tiêu, phạm vi, file được phép/không được phép sửa, tiền đề, bằng chứng, tiêu chí chấp nhận, regression matrix, rollback và cổng phê duyệt.
- Có bước phản biện kế hoạch trước khi triển khai.
- Nếu WO có xung đột phiên bản hoặc chưa rõ duyệt, dừng ở audit và hỏi/chờ quyết định; không tự chọn một phiên bản.

**B. `duoface-abi-hook-review`**
- Xác định process/bundle đích, class/selector, số đối số, kiểu trả về, calling convention, availability, runtime owner/lifecycle và đường fail-safe.
- Kiểm ABI trước khi hook; mismatch thì không cài hook.
- Phân biệt symbol tồn tại, responds-to-selector, hook installed, method actually invoked và dữ liệu đúng ở runtime — đây là các sự kiện khác nhau.
- Yêu cầu kill switch, log không nhạy cảm, giới hạn tần suất, không crash, rollback; private API phải qua cổng duyệt riêng.

**C. `duoface-gofa-adapter`**
- Truy notification thật và phân tích object/schema trước khi viết adapter.
- Chỉ map field có bằng chứng; chuẩn hóa thành model có source identity, timestamp, freshness/expiry, loại alert, khoảng cách và maneuver khi có dữ liệu thật.
- Cấm synthetic speed-limit, camera, alert hoặc turn. GPS fallback phải được gắn nhãn rõ và không giả làm GOFA feed.
- Kiểm chứng một nguồn dữ liệu duy nhất đi tới shared transport và renderer trên mọi pane/dashboard; đo app/pane lifecycle và dữ liệu hết hạn.

**D. `duoface-device-evidence`**
- Ghép bundle/process, build, session/request/touch/cycle ID và timestamp.
- Phân biệt không có event, event đến nhưng guard fail, listener đăng ký nhưng pipeline im lặng, payload được giải mã, transport thành công và renderer hiển thị.
- Đặt trước số chu kỳ, tỷ lệ đạt, mẫu test, ngưỡng dừng; log cần đủ để phân biệt các giả thuyết.
- Kết quả phải nêu rõ điều đã đo và giới hạn của phiên test.

**E. `duoface-deb-release`**
- Rootless/rootful, kiến trúc ARM64, iOS target, control metadata, dependencies, conflicts/replaces, scripts, payload, entitlements, package version và checksum.
- Truy xuất đúng workflow, source commit, artifact ID, SHA256 và provenance.
- Giữ trạng thái riêng: source commit → CI → signed DEB → archive → Sileo publish → installed package → device test → rollback.
- Không publish/install khi chưa có duyệt và package inventory/rollback plan.

## 4. Mô hình nhiều agent phù hợp với DuoFace

Không nên cho nhiều agent cùng viết vào một working tree. Dùng fan-out cho **đọc và kiểm tra độc lập**, rồi mới có một implementer.

| Vai trò | Quyền | Đầu ra bắt buộc |
|---|---|---|
| Lead / Muse chính | Điều phối, tổng hợp; chưa sửa trong pha audit | Một trạng thái thống nhất, danh sách mâu thuẫn và quyết định cần duyệt |
| Agent A — source/ABI | Read-only | Call graph, ABI evidence, process/lifecycle, unknowns |
| Agent B — data flow | Read-only | Notification/schema/field map, source identity, freshness, producer→transport→renderer |
| Agent C — CI/package | Read-only | Branch/commit/workflow/artifact/SHA/publish/rollback |
| Agent D — device QA | Read-only | Log timeline, test matrix, pass/fail/exhausted, counter-hypotheses |
| Implementer | Một agent, worktree riêng | Chỉ một WO đã duyệt, diff nhỏ, regression tests |
| Verifier độc lập | Read-only, khác implementer | Đối chiếu yêu cầu/diff/test, tìm hồi quy và điều kiện chưa đạt |

Nguyên tắc:

- Mỗi agent chỉ nhận một câu hỏi hẹp, có thể kiểm chứng độc lập.
- Ghi rõ file/commit/line và bằng chứng; không nhận câu trả lời kiểu “tôi đã xem toàn bộ”.
- Các agent không tự hợp nhất kết luận. Lead phải nêu điểm đồng thuận và bất đồng.
- Chỉ một writer được làm việc trên từng phần code; mỗi writer dùng worktree riêng. Read-only reviewers có thể dùng cùng checkout.
- Nếu workflows chưa có trên bản cài, dùng subagent/session độc lập theo cùng hợp đồng đầu ra; không phụ thuộc một tính năng beta chưa được xác minh.

## 5. Quy trình chuẩn cho mỗi WO DuoFace

1. **Baseline:** chốt branch + SHA + trạng thái git + handoff/WO mới nhất.
2. **Evidence pack:** chỉ lấy đúng source, tests, workflow, logs và reference binaries liên quan.
3. **Plan:** Muse viết kế hoạch có đường dẫn cụ thể, giả thuyết đối lập, phạm vi sửa, test và rollback.
4. **Grill/review:** một agent độc lập cố tìm lỗi logic, premise chưa chứng minh, regression và blast radius.
5. **Approval gate:** người phụ trách duyệt WO cuối cùng. Không suy ra đồng ý từ câu trả lời mơ hồ hoặc từ việc duyệt một phiên bản WO cũ.
6. **Implement:** một writer, worktree riêng, thay đổi nhỏ nhất.
7. **Verify:** chạy test xác định trước; reviewer khác đọc diff và test result. Build success không được gọi là device pass.
8. **Release gate:** xác thực package, checksum, version, dependency/conflict, rollback. Publish/install chỉ sau khi được phép.
9. **Device gate:** test máy thật theo ma trận; export log, đối chiếu marker và ghi verdict.
10. **Checkpoint:** cập nhật đúng handoff hiện có và memory index; ghi commit, artifact SHA, tình trạng Sileo/thiết bị, unknowns và bước kế tiếp.

## 6. Cài các hàng rào bảo vệ bằng hook/permission

Khuyến nghị triển khai theo mức tối thiểu trước:

- **Session start:** hiển thị branch, HEAD, dirty tree và đường dẫn handoff.
- **Pre-tool / pre-command:** yêu cầu người dùng xác nhận trước các hành động có side effect: package install/remove, publisher/Sileo, push/merge, private API activation, sửa vùng đóng băng, lệnh tác động thiết bị.
- **Post-edit:** nhắc/kiểm tra có diff, test liên quan và đường dẫn log; không tự ghi nhận PASS nếu không có output.
- **Stop/end:** kiểm tra trạng thái WO, test, artifact và handoff; nếu chưa có bằng chứng thì ghi UNKNOWN/BLOCKED.
- **Permissions:** audit dùng read-only; chỉnh code dùng sandbox và review/approval; chỉ cấp quyền ghi tối thiểu. Không dùng chế độ unrestricted/`--yolo` trên repo chính hoặc máy có kết nối thiết bị.
- **Session log:** giữ log sự kiện để truy lại tool calls, child agents và quyết định approve; không tắt session logging trong các WO khó cần audit.

Hook không thay thế quyền phê duyệt của người phụ trách; không dùng hook để tự động phát hành hoặc cài package.

## 7. Cách đặt chế độ và câu lệnh cho Muse

- Kiểm tra `muse --version` và `/models` trước phiên quan trọng. Docs tại thời điểm khảo sát có changelog phiên bản 1.4.13; không mặc định mọi tính năng rollout đều có trên máy người dùng.
- Audit source/data-flow: reasoning `high` hoặc `xhigh`; ABI, crash, private API và kiến trúc đa process: `xhigh`. Không ép `ultra/max` cho mọi công việc.
- `/plan` cho WO nhiều bước; `/grill` để phản biện premise và hợp đồng nghiệm thu; dùng skill chuyên môn cho tác vụ lặp lại.
- Kiểm tra `/workflows` hoặc khả năng workflow trên bản cài. Tài liệu Meta ghi nhận workflow engine có điều kiện rollout/build; không giả định là luôn khả dụng.
- Với tác vụ chỉ đọc, giới hạn agent ở read-only. Với sửa code, mỗi writer dùng worktree riêng.
- Khi chạy headless/CI, phải kiểm tra test report và artifact riêng; mã thoát của một lượt agent không tự chứng minh sản phẩm đúng.

### Prompt mẫu — audit read-only

```text
/effort xhigh
/plan

Nhiệm vụ: audit [WO / bug / pipeline] của DuoFace tại branch [BRANCH], HEAD [SHA].

Chế độ READ-ONLY: không sửa file, không commit, không build, không publish,
không cài/gỡ package, không chạy lệnh tác động iPhone/CarPlay.

Đọc handoff hiện hành và quyết định/WO mới nhất trước. Nếu tài liệu mâu thuẫn,
lập timeline theo commit và timestamp; không tự chọn một WO cũ.

Với từng kết luận, trả:
1. FACT: file + symbol/hàm + dòng hoặc commit/log marker chính xác.
2. INFERENCE: lập luận dựa trên fact nào.
3. UNKNOWN: bằng chứng còn thiếu.
4. COUNTER-HYPOTHESIS: cách giải thích khác có thể đúng.
5. DISCRIMINATING TEST: phép đo phân biệt các giả thuyết, không làm thay đổi runtime.
6. REGRESSION / BLAST RADIUS.
7. STOP CONDITION và điều kiện cần người phụ trách duyệt.

Không dùng CI PASS để khẳng định device PASS. Không dựng payload, field,
alert, tốc độ, maneuver hay trạng thái thiết bị. Không tuyên bố đã đọc file
hoặc log nếu không mở được. Kết thúc bằng danh sách câu hỏi cần quyết định,
không tự triển khai.
```

### Prompt mẫu — triển khai sau khi WO đã duyệt

```text
/effort xhigh

Chỉ thực hiện WO đã duyệt: [WO ID + link/commit + bản cuối đã duyệt].
Trước khi sửa, kiểm tra lại HEAD và nội dung WO có đúng bản duyệt không.

Dùng một worktree riêng. Không thay đổi file/module ngoài phạm vi.
Giữ nguyên hành vi cũ và vùng đang đóng băng trừ khi WO cho phép cụ thể.

Trước khi kết thúc:
- chạy test mới và regression tests đã chỉ định;
- đọc lại diff, tìm thay đổi ngoài phạm vi;
- ghi command, exit code, output và test count;
- phân tách source commit, CI, signed DEB, Sileo publish, installed,
  device test, rollback;
- cập nhật đúng hồ sơ handoff hiện có sau khi có thay đổi thật.

Nếu phát hiện premise sai, ABI không khớp, log không đủ, test fail,
package conflict hoặc cần mở rộng phạm vi: dừng, báo bằng chứng và không
tự chuyển sang phương án khác.
```

## 8. Ưu tiên triển khai

**P0 — hiệu quả cao, ít rủi ro**
1. Thêm `AGENTS.md` ngắn làm luật dự án.
2. Tạo `.agents/memory/MEMORY.md` và 5 note theo chủ đề, chỉ trỏ về hồ sơ gốc.
3. Tạo 5 skill ở mục 3.3.
4. Chuẩn hóa format WO và trạng thái bằng chứng.

**P1 — tăng chất lượng quyết định**
5. Dùng 3–4 reviewer read-only cho các audit lớn; một lead tổng hợp.
6. Bắt buộc independent review trước sửa ABI, GOFA field map, scene lifecycle hoặc package conflict.
7. Thêm hook SessionStart/Stop và approval gates, thử trên bản sao/worktree trước.

**P2 — đo năng suất**
8. Theo dõi số vòng từ báo lỗi tới kết luận được xác minh, số lần kết luận bị phản biện sửa, regression, thời gian/chi phí token và tỷ lệ device acceptance.
9. Chỉ coi một cải tiến là có ích khi giảm số vòng hoặc giảm regression mà không làm giảm độ tin cậy.

## 9. Tiêu chí xác nhận bộ Muse mới có thực sự tốt hơn

Chạy thử trên 3 công việc khác nhau (một source/ABI audit, một GOFA data-flow audit, một DEB/release audit), so với cách làm trước:

- Không có kết luận quan trọng nào thiếu đường dẫn bằng chứng.
- Không lẫn static analysis, CI, publish, installed và device-tested.
- Không dùng field/payload giả hoặc biến GPS thành dữ liệu GOFA.
- Mâu thuẫn giữa handoff/WO được phát hiện trước khi sửa.
- Một writer duy nhất thay đổi source trong mỗi WO.
- Có test và reviewer độc lập; regression không tăng.
- Số vòng trao đổi/đính chính giảm, nhưng không được đổi lấy việc bỏ qua cổng an toàn.

Nếu không đạt, sửa skill/AGENTS/memory trước; không tăng quyền tự động cho Muse để ép tiến độ.

## 10. Nguồn tham khảo

### Meta / Muse Code — nguồn chính thức
- [Introducing Muse Code and Muse Spark 1.2](https://research.meta.ai/blog/introducing-muse-code-and-muse-spark-1-2) — mục tiêu sản phẩm, tác vụ dài, planning/context và multi-agent.
- [Muse Code configuration](https://dev.meta.ai/docs/muse-code/configuration) — project instructions, model, reasoning effort, settings.
- [Muse Code extending and automation](https://dev.meta.ai/docs/muse-code/extending) — skills, hooks, MCP, headless execution.
- [Muse Code memory](https://dev.meta.ai/docs/muse-code/memory) — memory index và topic files.
- [Muse Code permissions](https://dev.meta.ai/docs/muse-code/permissions) — approval và sandbox.
- [Muse Code subagents](https://dev.meta.ai/docs/muse-code/subagents) — fan-out và worktree isolation.
- [Muse Code workflows](https://dev.meta.ai/docs/muse-code/workflows) — workflow orchestration, rollout/build caveats.
- [Muse Code sessions](https://dev.meta.ai/docs/muse-code/sessions) — session state, logs và resume.
- [Muse Code changelog](https://dev.meta.ai/docs/muse-code/changelog) — kiểm tra thay đổi theo version.

### Nghiên cứu độc lập — chỉ dùng làm nguyên tắc thiết kế
- [Learning on the Job: An Experience-Driven Self-Evolving Agent for Long-Horizon Tasks (MUSE)](https://arxiv.org/abs/2510.08002) — kiến trúc memory phân cấp và tổng kết trải nghiệm sau subtasks. Đây là nghiên cứu MUSE khác, **không phải** tính năng của Meta Muse Code.
- [SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering (NeurIPS 2024)](https://arxiv.org/abs/2405.15793) — giao diện/tool chuyên biệt cho điều hướng repo, sửa code và chạy test; hỗ trợ ý tưởng skill/workflow theo nhiệm vụ, không chứng minh riêng hiệu năng Muse.

## 11. Giới hạn xác minh của tài liệu này

- Đã đọc các tài liệu Markdown nền của Gpt-training-: `SKILL_INDEX.md`, `AGENTS.md`, `PROJECT_INSTRUCTIONS.md`, `README.md`, `DEB_IPA_SKILL.md`, và manifest ZIP.
- Đã lấy blob Base64 của các ZIP liên quan `01-github-continuity`, `02-ios-deb-ipa-carplay`, `05-research-debug-testing`; connector trong phiên này không cung cấp bước giải nén ZIP trực tiếp, nên **không tuyên bố đã đọc/kiểm tra toàn bộ nội dung binary ZIP trong lượt nghiên cứu này**. Các chỉ dẫn ở trên dựa trên Markdown đã đọc, tài liệu Meta, nghiên cứu công khai và hồ sơ DuoFace đã mở.
- Đã đọc repo DuoFace và các báo cáo Muse/QA nêu ở trên. Không sửa source, không chạy test, không tạo DEB, không thay đổi trạng thái Sileo hoặc thiết bị.
