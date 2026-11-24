# Checklist hoàn tất T12 của Long

Mục tiêu trước mắt: hoàn thành thiết kế và evidence của #3. Các dòng chưa chọn chưa được xác nhận hoàn thành.

## 1. Đã chuẩn bị trong bộ tài liệu T12
- [x] Phân định consumer, trách nhiệm SOA và scope P0.
- [x] Soạn đề xuất FastAPI và trade-offs.
- [x] Soạn request examples và prompt cho hai luồng.
- [x] Soạn kịch bản ba operations, phần nói của Long và báo cáo tiến độ.
- [x] Tách kế hoạch khỏi kết quả thực thi; không dùng số liệu giả làm evidence.

## 2. Cần review trước thực thi
- [ ] Xác nhận FastAPI và quy tắc bảo vệ health.
- [ ] Chốt retry/error/timeout boundary với Gateway.
- [ ] Duyệt nội dung hai prompts và input.
- [ ] Chọn model ID và cấu hình khóa cục bộ hợp lệ; không chia sẻ khóa trong chat/tài liệu.

## 3. Evidence còn thiếu
- [ ] Response generation thật + model/config/time + validation output.
- [ ] Response analysis thật + model/config/time + validation output.
- [ ] Nhận xét consistency, tiers, Socratic hint và giới hạn correctness.
- [ ] Examples OpenAPI đã review với Khánh.
- [ ] Swagger/Prism chạy được và có ba operations minh họa luồng consumer.
- [ ] Bằng chứng contribution, phần slide nhóm và báo cáo tiến độ đã cập nhật.

## 4. Cổng nộp bài
Chỉ báo hoàn thành thiết kế sau khi review phù hợp. Chỉ đóng #3 khi đạt DoD issue, bao gồm evidence API thật. Mock được chấp nhận cho demo thiết kế T12 nhưng không thay DoD gọi model thật của #3.

Bộ tài liệu được công bố theo từng commit trong PR #23 để review. Không đưa paper/PDF nguồn, bản trích xuất, ảnh nguồn hoặc thông tin bí mật vào bộ bàn giao. Việc công bố tài liệu không tự hoàn tất các hạng mục thực thi.
