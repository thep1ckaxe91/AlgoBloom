# Báo cáo Tiến độ Tuần 12 (Design Review) — AlgoBloom

- **Dự án:** AlgoBloom — AI-Augmented Online Judge (Kiến trúc SOA — Gateway Orchestration)
- **Repository:** `https://github.com/thep1ckaxe91/AlgoBloom`
- **Ngày cập nhật:** 25/11/2026 | **Nhóm thực hiện:** Nam, Khánh, Long, Sơn

---

## 1. Công việc đã hoàn thành & Bằng chứng (Completed Work & Evidence)

| Thành viên | Vai trò | Công việc đã hoàn thành ở Tuần 12 | Bằng chứng (Commit / PR / Tệp) |
| :--- | :--- | :--- | :--- |
| **Nam** (`@thep1ckaxe91`) | Judge Infra, Redis Broker & Tech Lead | - Bootstrap monorepo SOA, hợp đồng `openapi.yaml` (13 paths / 14 operations), `redis-schemas.json` (4 streams), `docker-compose.mock.yml`, khung dịch vụ T13 và hệ thống Issues (#1–#19).<br>- Chạy kiểm chứng thực tế Swagger UI (`:8080`) kết nối Prism Mock (`:4010`).<br>- Phối hợp Long phân pha AI Service **P0 → P1 → P2** (#15–#19); phối hợp Khánh chốt **Option 1** (Client WASM Syntax Gate + Formatter; Gateway tự canonicalize + `sha256` + `singleflight` + chặn `422` bài `CE`).<br>- Review và merge PR #27 (Sơn) & PR #23 (Long). | Commit `9de57f3`, **PR #20** (Merged `f307773`), [docs/nam/](nam/README.md), ảnh [swagger-ui-w12.png](nam/evidence/swagger-ui-w12.png), [redis-schemas.json](../contracts/redis-schemas.json) |
| **Sơn** (`@ngobason`) | Client SPA & Presentation | - Tinh gọn `docs/project-brief.md` (1–2 trang, rõ MVP vs Out-of-Scope và giới hạn Mock).<br>- Hoàn thiện 3 wireframe SVG đối chiếu OpenAPI Contract (Tag-Combiner Studio, Code Workspace, Big-O Hint Drawer — on-demand, không Backend LSP).<br>- Xuất bộ 7 slide PDF Design Review và tự tay chạy thử luồng demo 4 bước trên Swagger UI + Prism (`401`, `202`, `200`, `TLE` 4 subtask, Big-O Socratic hint). | **PR #27** (Merged `bdb59e2`, đóng Issue #4), [AlgoBloom_W12_Slide.pdf](presentation/AlgoBloom_W12_Slide.pdf), [wireframes/](wireframes/), 6 ảnh mock `docs/evidence/01..06-*.png` |
| **Long** (`@LongSei`) | AI Pedagogical Service | - Chốt ngôn ngữ triển khai AI Service là **Python FastAPI** (giữ nguyên hợp đồng `/internal/ai/*` & 4 JSON Schemas).<br>- Đề xuất định hướng mở rộng 2 vòng lặp P0 → P1 → P2 (#15) tách thành follow-up issues #16–#19 không phình phạm vi T13.<br>- Hoàn thiện bộ tài liệu thiết kế AI T12, prompt, JSON request mẫu tổng hợp, kịch bản trình bày và checklist nghiệm thu T12–T15. | **PR #23** (Merged `db22224`), Issue #15, [docs/long/t12/README.md](long/t12/README.md), [ai-service-stack-decision.md](long/ai-service-stack-decision.md), [services/ai-service/README.md](../services/ai-service/README.md) |
| **Khánh** (`@namnkahn1607`) | Core Gateway, Auth & DB | - Khung hợp đồng OpenAPI 3.0.3, PostgreSQL DDL 7 bảng (`001_init.sql`, `002_seed.sql`), bảng Resource Model vs DB Schema và bộ Postman Collection đã có sẵn trên `main` và đạt kiểm tra cú pháp/JSON/`$ref`.<br>- Tham gia chốt quy ước chống xung đột `docs/<member>/` và phương án chống lách cache / spam `CE` (Option 1). | Commit `9de57f3`, [openapi.yaml](../contracts/openapi.yaml), [001_init.sql](../services/gateway/migrations/001_init.sql), [Postman Collection](../tests/postman/algobloom-w12-mock.postman_collection.json) |

*Phạm vi xác nhận trung thực:* Kết quả chạy thử Tuần 12 là kiểm chứng **Contract/Mock** trên Swagger UI + Stoplight Prism (`docker-compose.mock.yml`), chưa phải kiểm thử E2E trên PostgreSQL, Redis Streams, `cptbox` hay live LLM provider.

---

## 2. Công việc chưa hoàn thành (Incomplete Items)

- [ ] **Khánh (Issue #2):** Chưa mở PR cá nhân để ghi nhận kết quả chạy thực tế Postman Collection trên Prism Mock Server (happy path + `401`/`403`/`422`) và đối chiếu chi tiết lần cuối giữa `openapi.yaml` với `001_init.sql`.
- [ ] **Long (Issue #3):** Chưa chạy xác thực cuộc gọi API thật tới model provider (`gemini-3.8-flash` / kiểm chứng quota thật) để thay thế các payload tổng hợp trong `openapi.yaml`; toàn bộ payload hiện tại là dữ liệu mẫu phục vụ Contract/Mock.
- [ ] **Nam (Issue #1):** Đã kiểm chứng Swagger/Prism và đồng bộ tài liệu vào `docs/nam/` (PR #20), còn bước hoàn thiện spike `cptbox` thực tế sẽ thực hiện ngay đầu Tuần 13.

---

## 3. Khó khăn, Rủi ro & Vấn đề cần Giảng viên hỗ trợ (Blockers & Support Needed)

1. **Rủi ro kỹ thuật `cptbox` trong Docker (R-01 — Nam):** Chưa kiểm chứng quyền kernel (`SYS_PTRACE`, seccomp, cgroups v2) của `dmoj/judge-small` trên máy các thành viên $\to$ xử lý bằng spike kỹ thuật đầu tiên ở Tuần 13 (#8).
2. **Giới hạn quota Free Tier & lách cache AI (R-02 — Long & Khánh):** Đã thiết kế 4 lớp bảo vệ tại Gateway (on-demand + chặn `422` bài `CE` + Server-side Canonicalizer xóa comment/space trước khi `sha256` + `singleflight` lock) kết hợp `MOCK_AI=true` và exponential backoff `429`.
3. **Nội dung xin góp ý từ Giảng viên trong buổi Design Review:**
   - Góp ý ranh giới tách biệt giữa **Resource Model** và **PostgreSQL ERD** (`problem_tags`, computed `StudentWeakness`, ẩn `ai_cache`).
   - Xác nhận tính hợp lý của luồng bất đồng bộ **`202 Accepted` + polling `GET /api/v1/jobs/{jobId}`** cùng quyết định dùng **Client WASM Syntax Gate** thay vì Backend Full LSP.

---

## 4. Kế hoạch Tuần 13 & Phân công Trách nhiệm (Week 13 Plan)

Mục tiêu Tuần 13: Chạy backend kết nối **PostgreSQL & Redis Streams thật**, demo tối thiểu 3 API operations liên quan cùng ít nhất 1 trường hợp lỗi/không đủ quyền (`401`/`403`/`422`).

| Thành viên | Issue Tuần 13 | Công việc trọng tâm | Tiêu chí hoàn thành (DoD) |
| :--- | :--- | :--- | :--- |
| **Khánh** | #5, #6, #7 | Triển khai Go Core Gateway: JWT + RBAC, migrations/seed PostgreSQL, CRUD + `ETag`, `202` Job Dispatcher, Redis result consumer, Server Canonicalizer + `singleflight` + chặn `CE` gọi `/analyze` | Server Go chạy với DB thật; chạy lại Postman Collection trỏ về `:8000` PASS toàn bộ happy path & `401`/`403`/`422` |
| **Nam** | #8, #9, #10 | Spike `cptbox` trên `dmoj/judge-small`; hiện thực Go Redis Streams Worker cho `verify_jobs` (`:rw`) và `judge_jobs` (`:ro`), đo `subtask_timings[]` 4 tầng | Chấm thật 1 bài `AC` $O(N \log N)$ và 1 bài `TLE` $O(N^2)$ trong `cptbox` qua Redis Streams (0 DB credentials) |
| **Long** | #11, #12 | Triển khai Python FastAPI AI Service: `X-Internal-API-Key`, `/internal/ai/generate-problem` & `/internal/ai/analyze-complexity`, backoff `429`, `MOCK_AI=true` + kiểm chứng live provider | Trả JSON đúng 100% schema ở cả chế độ mock và live provider; kiểm thử thiếu/sai internal key trả `401` |
| **Sơn** | #13, #14 | Khởi tạo React SPA + Monaco + `web-tree-sitter` WASM Syntax Gate (C++/Python packs) + Client Formatter; nối 3 màn hình chính + Job polling + Big-O Hint Drawer | Demo đầu-cuối trên UI: Login -> Tag-Combiner Studio -> Code Workspace (chặn lỗi cú pháp trước submit) -> Big-O Drawer |
