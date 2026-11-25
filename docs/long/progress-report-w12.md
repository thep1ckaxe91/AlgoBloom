# Báo cáo tiến độ T12 — AlgoBloom

**Mốc:** Design Review. **Cập nhật:** 24/11/2026. **Nhóm:** Nam, Khánh, Long, Sơn.

**Repository:** [thep1ckaxe91/AlgoBloom](https://github.com/thep1ckaxe91/AlgoBloom).

## 1. Mục tiêu và phạm vi

AlgoBloom hỗ trợ giáo viên tạo bài theo tổ hợp thuật toán và hỗ trợ học sinh phân tích mã chậm bằng gợi ý Socratic. T12 tập trung thiết kế và hợp đồng API; backend hoàn chỉnh là mục tiêu triển khai các tuần sau.

Năm use case chính: xác thực/phân quyền; tra cứu tag và điểm yếu; sinh và kiểm chứng đề; nộp/chấm bài theo subtask; phân tích độ phức tạp theo yêu cầu. Luồng trình bày trọng tâm là giáo viên tạo đề, học sinh nộp bài rồi yêu cầu phân tích.

MVP giữ hai vai trò TEACHER/STUDENT, sinh đề và test bốn tầng, chấm C++/Python, polling job và gợi ý có cache. LSP, WebSocket, thi đấu thời gian thực và chatbot tự do nằm ngoài phạm vi. Agent loop, calibration, adaptive learning và nghiên cứu có issue riêng; không chặn nghiệm thu P0.

## 2. Thiết kế và sản phẩm đã chuẩn bị

| Nội dung | Thiết kế và bằng chứng |
|---|---|
| Consumers và SOA | SPA gọi Gateway qua JWT. Gateway gọi AI bằng internal API key. Judge Worker nhận/trả message qua Redis. Gateway là thành phần duy nhất sở hữu PostgreSQL; AI và Worker không truy cập DB. Xem [project brief](project-brief.md), [sơ đồ kiến trúc/sequence](design.md). |
| Resource và dữ liệu | User, Tag, Problem, Submission, BigOAnalysis, Job và StudentWeakness được trình bày trong resource model. ERD có 7 bảng; `problem_tags` là bảng nối, `ai_cache` là dữ liệu nội bộ. Resource API không ánh xạ một-một với bảng DB. Xem [thiết kế](design.md), [migration](../services/gateway/migrations/001_init.sql). |
| API contract | [OpenAPI 3.0.3](../contracts/openapi.yaml) có 13 public paths, 14 operations; định nghĩa input/output, status codes, lỗi thống nhất, JWT/RBAC, pagination/filter/sort và ETag ở các operation liên quan. Đây là hợp đồng, chưa là bằng chứng thực thi. |
| Tác vụ bất đồng bộ | Generation/submission nhận `202` và job ID; consumer polling `GET /api/v1/jobs/{jobId}`. Bốn Redis Streams được mô tả trong [message schema](../contracts/redis-schemas.json). Thiết kế tránh giữ request dài; đổi lại phải quản lý job và kết quả đến trễ. |
| Môi trường thiết kế | Có [Compose Swagger/Prism](../docker-compose.mock.yml), [Postman collection](../tests/postman/algobloom-w12-mock.postman_collection.json), khung Gateway/Judge và bốn JSON Schema AI trên main. Có cấu hình hoặc collection không đồng nghĩa đã chạy thành công. |

API công khai dùng `/api/v1`; AI chỉ dùng nội bộ. Hướng kiểm soát lỗi gồm validation, `401/403`, lỗi nghiệp vụ và lỗi giới hạn gọi. AI dự kiến dùng bounded backoff và mock có nhãn. Cache phân tích thuộc Gateway. Các lựa chọn và trade-offs được ghi trong [ADR](adr-summary.md).

## 3. Tiến độ và đóng góp cá nhân

| Thành viên | Kết quả hiện có | Còn phải xác nhận trước nghiệm thu T12 |
|---|---|---|
| Nam | [PR #20](https://github.com/thep1ckaxe91/AlgoBloom/pull/20) có cập nhật roadmap và tệp ảnh Swagger. | Review sơ đồ/Redis theo [#1](https://github.com/thep1ckaxe91/AlgoBloom/issues/1); đối chiếu bằng chứng mock. PR chưa merge. |
| Khánh | Main có OpenAPI, ERD, migrations/seed và Postman collection. | [#2](https://github.com/thep1ckaxe91/AlgoBloom/issues/2): đối chiếu API/DB và kết quả chạy Postman; chưa có PR riêng/kết quả thực thi được xác nhận trong lần rà soát này. |
| Long | [PR #23](https://github.com/thep1ckaxe91/AlgoBloom/pull/23) có thiết kế FastAPI, contract boundaries, prompt, input tổng hợp, demo script và checklist. PR sẵn sàng review; chưa merge. | [#3](https://github.com/thep1ckaxe91/AlgoBloom/issues/3): xác nhận model ID/quota, hai response API thật và schema validation; review quyết định công nghệ, rồi cập nhật examples. |
| Sơn | [PR #27](https://github.com/thep1ckaxe91/AlgoBloom/pull/27) có project brief cập nhật, 3 wireframe SVG, slide PDF 7 trang và 6 ảnh demo mock. | Review/merge sản phẩm [#4](https://github.com/thep1ckaxe91/AlgoBloom/issues/4). PR nêu chưa chạy E2E service thật và chưa xác nhận Postman. |

Bốn issue T12 vẫn mở tại mốc rà soát. Tài liệu trên main được đối chiếu ở commit [`9de57f3`](https://github.com/thep1ckaxe91/AlgoBloom/commit/9de57f3b3c7cd71db241d4754d153ab9a7142852). Các PR mở là đóng góp đang chờ tích hợp, không phải sản phẩm đã merge. Không quy kết toàn bộ tệp bootstrap là đóng góp cá nhân đã được nghiệm thu.

## 4. Demo Design Review và mức bằng chứng

1. `POST /api/v1/problems/generate`: trình bày tags/difficulty/limits và response `202`.
2. `GET /api/v1/jobs/{jobId}`: trình bày trạng thái và resource ID.
3. `GET /api/v1/problems/{problemId}`: trình bày statement, ví dụ và subtask tiers.
4. Nếu còn thời gian: nộp bài và yêu cầu phân tích; minh họa response lỗi theo OpenAPI.

Ảnh Swagger nằm trong PR #20; sáu ảnh generate/poll/read/submit/result/analyze nằm trong PR #27. PR #27 báo đã thử luồng trên Swagger/Prism. Chưa có kết quả Postman được xác nhận. Mock minh họa contract, không chứng minh DB, JWT/RBAC, Redis, sandbox hoặc provider AI đã chạy. Timings và input tự soạn không được ghi là kết quả đo thật.

## 5. Việc chưa xong, rủi ro và hỗ trợ

| Việc cần xử lý | Người phụ trách và hành động |
|---|---|
| Tích hợp tài liệu T12 | Nhóm review PR #20/#23/#27, xử lý phần báo cáo trùng thay đổi trước merge; Sơn tổng hợp bộ nộp và slide. |
| API/schema/DB consistency | Khánh hoàn tất đối chiếu, chạy collection và lưu pass/fail gắn commit; không đặt sẵn kết quả 100%. |
| Model và quota | Long kiểm chứng API thật, lưu output đã lọc secret. Tên model trong cấu hình chưa xác nhận khả dụng; mock chỉ là phương án phát triển/demo có nhãn. |
| Sandbox và quyền Docker | Nam thực hiện spike T13 về môi trường Judge; chưa ghi nhận đã chấm đúng chỉ từ Dockerfile. |
| Góp ý thiết kế | Xin giảng viên phản hồi về ranh giới resource/DB, async polling và mức MVP trước khi triển khai. |

## 6. Kế hoạch tiếp theo và điều kiện hoàn thành

**Trước buổi T12:** review thiết kế, xác nhận demo ba operations, bổ sung API/model và Postman evidence còn thiếu; cập nhật báo cáo theo kết quả thực tế. Nộp project brief, diagrams, OpenAPI/Swagger, repository/backlog, báo cáo 1–2 trang và bộ slide 6–8 trang. Tài liệu chi tiết của Long nằm trong [bộ T12](long/t12/README.md).

**T13:** Khánh triển khai auth/DB/CRUD/jobs/cache; Nam triển khai worker/sandbox; Long triển khai hai API AI, auth nội bộ, validation, retry, mock/live provider và tests; Sơn nối UI/polling. Nhóm cần demo ít nhất ba operations liên quan với DB thật và một request lỗi/không đủ quyền. JSON dựng sẵn không thay bằng chứng backend.

**T14:** hoàn thành MVP, integration/regression, README và môi trường chạy lại. **T15:** security/performance evidence, lifecycle/compatibility, quickstart và release sau nghiệm thu. Mỗi kết luận hoàn thành phải gắn code, commit/PR, API response hoặc test result tương ứng.
