# Bản nháp báo cáo tiến độ T12 của Long

Dự án: AlgoBloom. Người phụ trách: Long (`@LongSei`). Ngày: 24/11/2026.

## 1. Mục tiêu tuần
Chuẩn bị thiết kế dịch vụ AI và hợp đồng có thể triển khai. Dịch vụ hỗ trợ sinh bài lập trình và phân tích độ phức tạp cùng gợi ý Socratic. Gateway là API consumer trực tiếp.

## 2. Phần đã chuẩn bị
Đã xác định ranh giới AI/Gateway/Judge/Frontend. Hợp đồng hiện có gồm hai POST nội bộ cho generation và analysis, cùng endpoint health. Bốn JSON Schema mô tả request/response của hai chức năng.

Đã chuẩn bị nhánh và draft PR T12–T15. Bản thiết kế T12 đề xuất Python FastAPI, giữ schema hiện có và tách model provider khỏi logic nghiệp vụ. Quyết định này còn chờ review; nó không chứng minh runtime đã hoàn thành.

Trong bộ nháp T12, đã bổ sung thiết kế lỗi/retry, prompt, hai mẫu input thủ công, kịch bản demo và checklist nghiệm thu. Các phần được đưa lên nhánh T12 bằng commit riêng trong PR #23 để review; chưa là bằng chứng chạy API hoặc hoàn thành #3.

## 3. Phần chưa hoàn thành
Chưa có bằng chứng từ hai lần gọi model thật cho sinh bài dp + binary-search và phân tích O(N²) TLE. Chưa xác nhận model ID/quota hoặc validate response thật. Chưa thay OpenAPI examples bằng payload đã kiểm chứng.

Kịch bản Swagger/Prism chưa được chạy trong đợt soạn nháp này. Chưa có ảnh demo, test report hoặc bằng chứng sandbox mới. Không ghi các nội dung này là hoàn thành.

## 4. Vấn đề cần phối hợp
Long cần môi trường API hợp lệ để kiểm chứng model. Khánh cần thống nhất error mapping, public examples và cách healthcheck dùng internal key. Nam phối hợp bước chạy generator/reference trong sandbox. Sơn tổng hợp phần AI vào slide và demo nhóm.

Các mẫu input hiện tại là dữ liệu tổng hợp. Chúng không được trình bày là output model hoặc số đo của Judge.

## 5. Kế hoạch trước buổi Design Review
Review quyết định FastAPI và ranh giới dịch vụ. Kiểm tra hai input/prompt, chạy model khi có cấu hình hợp lệ, validate output rồi đề xuất cập nhật examples. Chạy thử ba API operations trong kịch bản mock của nhóm và ghi rõ giới hạn mock. Tổng hợp phần trình bày AI và cập nhật trạng thái bằng evidence thực tế.

## 6. Kế hoạch T13
Triển khai nền tảng #11 và chức năng #12. Thêm auth, mock provider, schema validation, bounded retry, Docker và tests. Phối hợp Gateway/DB/Judge để demo end-to-end với dữ liệu thật. Không đưa toàn bộ P1/P2 hoặc nghiên cứu vào điều kiện hoàn thành MVP.

## 7. Liên kết theo dõi
- Issue #3: https://github.com/thep1ckaxe91/AlgoBloom/issues/3
- Draft PR T12: https://github.com/thep1ckaxe91/AlgoBloom/pull/23
- Epic: https://github.com/thep1ckaxe91/AlgoBloom/issues/15

Các tài liệu nháp nằm trong `docs/long/t12/` của PR #23. Liên kết response thật, validation và demo sẽ bổ sung sau khi có kết quả thực thi.
