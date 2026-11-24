# Kịch bản demo và phần trình bày T12 của Long

Trạng thái: kịch bản Design Review T12. T12 dùng Swagger hoặc Prism mock có nhãn; chưa là demo backend hoàn chỉnh.

## 1. Chuẩn bị chung
Nhóm chạy Swagger UI/Prism theo README hiện có và mở OpenAPI. Khánh kiểm tra public schema/auth, Sơn tổng hợp slide, Nam giải thích verification, Long trình bày AI contract.

Với môi trường hiện có, Swagger UI dự kiến ở localhost:8080 và Prism ở localhost:4010 theo docker-compose.mock.yml. Cần kiểm tra thực tế trước demo; môi trường chưa được chạy trong lần chuẩn bị này.

## 2. Luồng tạo bài cho giáo viên
| Bước | API operation | Điều cần chỉ ra |
|---|---|---|
| 1 | POST `/api/v1/problems/generate` | Input tags/difficulty/limits; quyền TEACHER; 202 cùng job_id và poll_url |
| 2 | GET `/api/v1/jobs/{jobId}` | Trạng thái job, lỗi nếu có và resource_id khi hoàn thành |
| 3 | GET `/api/v1/problems/{problemId}` | Statement, ví dụ, constraints và tiers theo schema public |

Ở T12, mock có thể trả ví dụ độc lập, không lưu trạng thái request trước. Dùng IDs có trong examples hiện hành, không nói đã tạo DB record hoặc chạy verification thật. Nói rõ COMPLETED/verified trong mock là response minh họa hợp đồng.

Long giải thích AI trả candidate đúng response schema cho Gateway. Gateway mới điều phối Redis/Judge. Không để frontend gọi AI bằng internal key.

## 3. Luồng phân tích bổ sung nếu còn thời gian
Dùng POST `/api/v1/submissions/{submissionId}/analyze`, đọc job và kết quả theo OpenAPI. Giải thích input gồm source code/timings, Gateway kiểm tra cache trước khi gọi AI và gợi ý không cung cấp full solution. Không diễn giải cache mock là cache PostgreSQL đang hoạt động.

## 4. Trường hợp lỗi
Chọn ví dụ 401/403/422 có trong OpenAPI và xác nhận cách Prism trả example bằng môi trường thực tế trước buổi demo. Không giả định Prism đang enforce JWT/RBAC như code thật. Demo auth/authorization thực tế là nhiệm vụ T13 trở đi.

## 5. Phần nói của Long trong slide nhóm
Đây là nội dung đóng góp vào bộ slide 6–8 trang của nhóm, không phải yêu cầu nhóm thêm một bộ slide riêng.

- Vai trò: Gateway là consumer duy nhất, AI phục vụ generation và Socratic analysis.
- Thiết kế: FastAPI đề xuất, module nhỏ, giữ JSON Schema và AI stateless.
- Trade-offs: mock để tái hiện và tránh quota; mock không chứng minh provider thật hoặc DB integration.
- Failure handling: input/auth không retry; 429/503 có giới hạn; malformed output không thành công.
- Tiến độ: nói đúng phần tài liệu đã có và những lần thực thi chưa chạy.
- Mốc tiếp theo: #11 nền tảng, #12 chức năng và tích hợp DB/Judge qua Gateway.

## 6. Evidence cần chụp sau khi chạy
- Swagger cho thấy ba operations và schema liên quan.
- Request/response minh họa với nhãn mock.
- Phần contribution của Long và commit/PR tương ứng.
- Nếu có live model test: lưu riêng, gắn model/config/time và kết quả schema validation.

Không chụp màn hình có API key, token, cookie hoặc source code người dùng thật.
