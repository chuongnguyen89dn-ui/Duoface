# DuoFace

> **Ưu tiên mới 2026-10-17 — cứu DuoFace VisualTest12 chạy lại trước:** tạm hoãn viết App Bridge độc lập hoàn chỉnh. Trước mắt kiểm tra và tái sử dụng có chọn lọc cơ chế scene host của DuoDash (Airaw chỉ tham khảo fullscreen/chrome), giữ split UI DuoFace và giữ nguyên Native12 Hub. **Chưa có DEB mới / chưa có xác minh thiết bị chạy lại.** [Quyết định và bước kiểm tra chi tiết](./docs/duodash-native-appbridge-replacement-visualtest12-20261017.md#ưu-tiên-mới-17102026--khôi-phục-chạy-được-trước).


**Định hướng chính thức từ 2026-10-15:** phát triển **DuoFace độc lập** cho CarPlay jailbreak, không phụ thuộc lõi hoặc cơ chế cấp phép/thời hạn DuoNavi. Giữ và tái sử dụng những thành quả về chia màn hình, menu, fullscreen và nhận diện DuoFace theo khả năng kỹ thuật được kiểm chứng.

## Bàn giao dự án — đọc đầu tiên

**[Bàn giao dự án DuoFace mới](./ban%20giao%20du%20an%20duoface%20moi.md)** (`ban giao du an duoface moi.md`) — hồ sơ **chính thức đang sử dụng** cho dự án DuoFace độc lập; lưu yêu cầu, quyết định, tiến độ, bản sửa đổi, mã nguồn, kết quả đóng gói, thử nghiệm và bước tiếp theo.

**[tiep tuc du an.md](./tiep%20tuc%20du%20an.md)** — hồ sơ **lịch sử** của các bản DuoFace trước đây còn kế thừa DuoNavi. Giữ để nghiên cứu và đối chiếu; **không ghi tiến độ hướng độc lập vào đây nữa**.

## Trạng thái kỹ thuật tại thời điểm chuyển giao

- Baseline gần nhất trên nền cũ: `dist/candidates/menu-native1/com.duonavi.app_1.0.3-12_menu-native1_iphoneos-arm64.deb`, Actions run `38679315617` **thành công** và tệp kết quả `11947453212`. Đã xác minh việc đóng gói DEB; chưa có xác nhận test CarPlay trên thiết bị đối với bản thử nghiệm này, chưa phát hành Sileo.
- Phiên bản **DuoFace độc lập**: đã chốt yêu cầu, **chưa xây dựng phần lõi mới/chưa có DEB độc lập**.
- Không sửa, ghi đè, cài đè hoặc phát hành các DEB đang có chỉ vì tạo đầu mối bàn giao mới.

## Nguồn kỹ năng

Tra `chuongnguyen89dn-ui/Gpt-training-` → `SKILL_INDEX.md` và các kỹ năng phù hợp trước khi bắt đầu công việc lập trình. Mã nguồn, bằng chứng, tệp kết quả và bàn giao **luôn thuộc repo DuoFace này**, không lưu vào repo kỹ năng.
