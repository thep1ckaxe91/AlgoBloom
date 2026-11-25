# Báo cáo Tiến độ Tuần 12 (Design Review Progress Report) — AlgoBloom

- **Dự án:** AlgoBloom — AI-Augmented Online Judge (SOA Gateway Orchestration)
- **Repository:** `https://github.com/thep1ckaxe91/AlgoBloom`
- **Giai đoạn báo cáo:** Tuần 12 — Thiết kế Kiến trúc, Hợp đồng API & Mock Server
- **Thành viên nhóm:** Nam, Khánh, Long, Sơn

---

## 1. Công việc đã hoàn thành (Completed Work)

1. **Chốt Kiến trúc SOA & Quyết định Đánh đổi (`docs/adr-summary.md`, `docs/design.md`):**
   - Hoàn thiện kiến trúc Gateway Orchestration (Option A) với 4 thành phần tách biệt (`frontend`, `services/gateway`, `services/ai-service`, `services/judge-worker`) và Redis Streams Broker.
   - Hoàn thiện sơ đồ Resource Model, sơ đồ ERD PostgreSQL (7 bảng), bảng phân tích sự khác biệt giữa Resource Model và DB Schema, sơ đồ SOA Topology với ranh giới tin cậy và Sequence Diagram luồng tự xác minh đề + chấm bài + phân tích Big-O.
2. **Hoàn thiện Hợp đồng API & Message Broker (`contracts/openapi.yaml`, `contracts/redis-schemas.json`):**
   - Xây dựng đầy đủ đặc tả OpenAPI 3.0.3 cho 14 endpoints `/api/v1/*` kèm bảo mật JWT (`BearerAuth`) & `X-Internal-API-Key`, phân trang/lọc/sắp xếp, `202 Accepted` async jobs, `ETag` caching, unified error format (`400`/`401`/`403`/`404`/`422`/`429`/`500`) và payload mẫu thực tế.
   - Đặc tả JSON Schema + ví dụ cho 4 Redis Streams (`verify_jobs`, `verify_results`, `judge_jobs`, `judge_results`).
3. **Dựng Stack Demo Swagger UI + Prism Mock & Bộ kiểm thử Postman:**
   - Cung cấp `docker-compose.mock.yml` chạy một lệnh ra Swagger UI (`:8080`) + Stoplight Prism 4 (`:4010`).
   - Khởi tạo bộ Postman Collection (`tests/postman/algobloom-w12-mock.postman_collection.json`) kiểm chứng happy path và negative cases (`401`, `403`, `422`).
4. **Chuẩn bị Tài liệu Dự án, Kế hoạch & Khung mã nguồn Tuần 13 (Premove):**
   - Hoàn thành `README.md`, `docs/project-brief.md`, `docs/backlog-and-plan.md`, `docs/slides-outline-w12.md`.
   - Khởi tạo khung dịch vụ sạch cho Tuần 13 (`services/gateway` + SQL migrations/seed, `services/judge-worker`, `services/ai-service/schemas`, `frontend/README.md`) và phân rã toàn bộ GitHub Issues cho Tuần 12–13.
5. **Sơn — Hoàn thiện sản phẩm Design Review (Issue #4):**
   - Rà soát, tinh gọn `docs/project-brief.md` trong giới hạn 1–2 trang; làm rõ MVP và Out-of-Scope.
   - Hoàn thiện 3 wireframe SVG trong `docs/wireframes/`: Tag-Combiner Studio, Code Workspace, Big-O Hint Drawer; đối chiếu OpenAPI Contract, Big-O theo yêu cầu (on-demand), không tích hợp LSP.
   - Xuất bộ 7 slide theo nội dung **gốc** của `docs/slides-outline-w12.md`, bàn giao bản PDF tại `docs/presentation/AlgoBloom_W12_Slide.pdf`; không sửa dàn ý gốc.
   - Trực tiếp thử luồng demo trên Swagger UI + Prism: không có token nhận `401`; tạo đề `202`; GET Job `200`; GET Problem `200`; nộp bài `202`; GET Submission `200` với `TLE` và 50/100 điểm, đủ 4 Subtask; phân tích Big-O `200` với `O(N²)` so với `O(N log N)` và gợi ý Socratic. Đã lưu 6 ảnh minh chứng ở `docs/evidence/`.
   - **Phạm vi xác nhận:** Đây là thử nghiệm Contract/Mock, không phải kiểm thử E2E trên Gateway/Judge/AI thật; chưa xác nhận Postman chạy PASS.

---

## 2. Hạng mục đang hoàn thiện trong Thứ Ba (In-Progress / Pending before Wednesday Review)

- [ ] **Nam:** Kiểm chứng chạy thực tế `docker-compose.mock.yml` trên máy local, chụp ảnh minh chứng Swagger UI + rà soát sơ đồ Mermaid/Redis schemas qua PR.
- [ ] **Khánh:** Rà soát đối chiếu 100% trường giữa `contracts/openapi.yaml` và `001_init.sql`, chạy Postman Collection trên Prism và ghi nhận kết quả qua PR.
- [ ] **Long:** Chạy gọi thử `gemini-3.8-flash` thật để tinh chỉnh payload mẫu trong `openapi.yaml` và chốt ngăn xếp triển khai AI Service (Python FastAPI vs. Go) qua PR.
- [x] **Sơn:** Đã hoàn thiện 3 wireframe, Project Brief, bộ slide PDF 7 trang theo dàn ý gốc và minh chứng Swagger UI + Prism; đã commit `b2b0aaa`, push lên fork và mở PR vào repository nhóm.
- [ ] **Sơn (chờ review):** PR đã mở nhưng còn yêu cầu ít nhất một approving review từ người có quyền Write; chưa merge vào `main`.

---

## 3. Khó khăn / Rủi ro & Đề xuất Hỗ trợ (Blockers & Support Needed)

- **Kỹ thuật sandbox (`cptbox` trong Docker):** Chưa chạy thử nghiệm `dmoj/judge-small` trên môi trường Linux/Docker của từng thành viên (rủi ro về `SYS_PTRACE` / cgroups v2). Nhóm đã xếp lịch spike đầu tiên cho Nam ngay sau buổi Review Thứ Tư.
- **Giới hạn Free Tier của `gemini-3.8-flash`:** Rủi ro gặp lỗi `429` khi nhiều thành viên cùng test. Nhóm đã thiết kế cơ chế `MOCK_AI=true` + cache băm PostgreSQL để phát triển độc lập không phụ thuộc quota.
- **Hỗ trợ cần từ Giảng viên:** Nhờ giảng viên góp ý trong buổi Design Review về ranh giới tách `Resource Model` vs `DB Schema` và thiết kế luồng `202 Accepted` polling `GET /api/v1/jobs/{jobId}` trước khi nhóm khóa hợp đồng bước vào Tuần 13.

---

## 4. Kế hoạch Tuần 13 (Week 13 Implementation Plan)

| Thành viên | Công việc trọng tâm Tuần 13 | Tiêu chí hoàn thành (DoD) |
| :--- | :--- | :--- |
| **Khánh** | Triển khai Go Core Gateway: Auth JWT/RBAC, migrations/seed PostgreSQL, CRUD Tags/Problems/Submissions + `ETag`, `202` Job Dispatcher & Redis consumer | Server Go chạy ổn định, Postman collection chạy pass trên Gateway thật (`:8000`) |
| **Nam** | Dựng Docker image `dmoj/judge-small` + Go Redis Streams worker cho `verify_jobs` và `judge_jobs`, đo `subtask_timings[]` | Chấm thành công 1 bài `AC` $O(N \log N)$ và 1 bài `TLE` $O(N^2)$ trong `cptbox` qua Redis Streams |
| **Long** | Triển khai AI Service (`/internal/ai/generate-problem`, `/internal/ai/analyze-complexity`), `X-Internal-API-Key`, backoff `429`, `MOCK_AI=true` | Trả về JSON đúng schema 100% ở cả chế độ `MOCK_AI=true` và Gemini thật |
| **Sơn** | Khởi tạo React SPA + plain `@monaco-editor/react` (no LSP), nối 3 màn hình chính với API + polling job | Demo được trọn vẹn luồng UI từ đăng nhập -> chọn tag tạo đề -> code & nộp bài -> mở drawer gợi ý Big-O |

---

## 5. Minh chứng (Evidence Links)

> *Ghi chú: Các thành viên điền link commit/PR cụ thể và đính kèm ảnh chụp Swagger/Postman vào mục này trước giờ nộp Thứ Tư.*

- **Repository & Bootstrap Commit:** `https://github.com/thep1ckaxe91/AlgoBloom/commits/main`
- **GitHub Issues (Tuần 12 & 13):** `https://github.com/thep1ckaxe91/AlgoBloom/issues`
- **PR Tuần 12 của các thành viên:**
  - Nam (Redis Schemas & Diagrams): *(điền link PR sau khi mở)*
  - Khánh (OpenAPI, ERD & Postman): *(điền link PR sau khi mở)*
  - Long (Gemini Samples & AI Stack): *(điền link PR sau khi mở)*
  - Sơn (Project Brief, Wireframes & Slides): https://github.com/thep1ckaxe91/AlgoBloom/pull/27
    - [Project Brief](project-brief.md); [Tag-Combiner Studio](wireframes/01-tag-combiner-studio.svg); [Code Workspace](wireframes/02-code-workspace.svg); [Big-O Hint Drawer](wireframes/03-big-o-hint-drawer.svg); [Slide PDF 7 trang](presentation/AlgoBloom_W12_Slide.pdf).
    - Ảnh mock: [Generate 202](evidence/01-generate-problem.png), [Job 200](evidence/02-job-polling.png), [Problem 200](evidence/03-get-problem.png), [Submit 202](evidence/04-submit-code.png), [Submission Result 200](evidence/05-submission-result.png), [Big-O Analyze 200](evidence/06-big-o-analysis.png).
- **Ảnh chụp Swagger UI & Mock Response:** *(đính kèm trong `docs/evidence/` sau khi chạy `docker compose -f docker-compose.mock.yml up`)*
