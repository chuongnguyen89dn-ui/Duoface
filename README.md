# DuoFace

**Định hướng chính thức từ 2026-10-15:** phát triển **DuoFace độc lập** cho CarPlay jailbreak, không phụ thuộc lõi hoặc cơ chế cấp phép/thời hạn DuoNavi. Giữ và tái sử dụng những thành quả về chia màn hình, menu, fullscreen và nhận diện DuoFace theo khả năng kỹ thuật được kiểm chứng.

## Bàn giao dự án — đọc đầu tiên

**[DUOFACE_INDEPENDENT_HANDOFF.md](./DUOFACE_INDEPENDENT_HANDOFF.md)** — đầu mối **mới và đang hoạt động** cho dự án DuoFace độc lập; đây là nơi cập nhật quyết định, tiến trình, commit, source, run, build, test và bước tiếp theo.

**[tiep tuc du an.md](./tiep%20tuc%20du%20an.md)** — hồ sơ **lịch sử** của các bản DuoFace trước đây còn kế thừa DuoNavi. Giữ để nghiên cứu và đối chiếu; **không ghi tiến độ hướng độc lập vào đây nữa**.

## Trạng thái kỹ thuật tại thời điểm chuyển giao

- Baseline gần nhất trên nền cũ: `dist/candidates/menu-native1/com.duonavi.app_1.0.3-12_menu-native1_iphoneos-arm64.deb`, Actions run `38679315617` **success** và artifact `11947453212`. Build DEB đã xác minh; chưa có xác nhận test CarPlay trên thiết bị đối với candidate này, chưa phát hành Sileo.
- Phiên bản **DuoFace độc lập**: đã chốt yêu cầu, **chưa viết lõi mới/chưa có DEB độc lập**.
- Không sửa, ghi đè, cài đè hoặc phát hành các DEB đang có chỉ vì tạo đầu mối bàn giao mới.

## Nguồn kỹ năng

Tra `chuongnguyen89dn-ui/Gpt-training-` → `SKILL_INDEX.md` và các kỹ năng phù hợp trước khi bắt đầu công việc lập trình. Mã nguồn, bằng chứng, artifacts và bàn giao **luôn thuộc repo DuoFace này**, không lưu vào repo kỹ năng.
