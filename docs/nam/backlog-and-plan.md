# Backlog, Lộ trình Triển khai & Quản trị Rủi ro (Tuần 12–15) — AlgoBloom *(Bản cập nhật: Nam)*

---

## 1. Lộ trình Tổng thể (Week 12–15 Roadmap)

| Tuần | Mốc đánh giá | Mục tiêu cốt lõi | Sản phẩm bàn giao (Deliverables) |
| :--- | :--- | :--- | :--- |
| **Tuần 12** | **Design Review** (Thứ Tư) | Chốt kiến trúc SOA, hợp đồng OpenAPI 3.0.3, ERD, Redis Schemas, Mock Server chạy được & toàn bộ 4 thành viên có PR merge trên Git (theo quy ước `docs/<member>/`) | `docs/*`, `contracts/openapi.yaml`, `contracts/redis-schemas.json`, `docker-compose.mock.yml`, Postman starter collection, 7 slide + báo cáo tiến độ W12 |
| **Tuần 13** | **Implementation Review (Core)** | Dựng trục xương sống chạy được đầu-cuối (vertical slice) từng dịch vụ theo đúng hợp đồng P0 + bổ sung WASM Syntax Gate/Formatter (FE) và Canonical Hash + `singleflight` + CE Gate (Gateway) | Go Gateway (Auth, CRUD, DB migrations, Canonicalizer, `singleflight`, Job dispatcher), Judge Worker (`dmoj/judge-small` + Redis Streams), AI Service (`MOCK_AI=true` + Gemini), React SPA (3 màn hình + Tree-sitter WASM + Formatter) |
| **Tuần 14** | **Integration & Hardening (+ P1 AI)** | Tích hợp hoàn chỉnh 4 dịch vụ qua Docker Compose, chạy thật luồng sinh đề tự xác minh + nộp bài TLE + phân tích Big-O, bắt đầu mở rộng P1 Agentic (#16, #17) nếu P0 ổn định | `docker-compose.yml` full stack, Newman/Postman trên Gateway thật, kiểm thử `429` backoff, `ETag`, `singleflight`, P1 Self-Revision & Adversarial hooks |
| **Tuần 15** | **Final Demo & Defense (+ P2 Eval)** | Đóng gói dữ liệu demo ổn định, hoàn thiện tài liệu tổng kết, kiểm thử hồi quy, chạy đánh giá P2/Ablation (#18, #19) nếu đủ dữ liệu và trình bày bảo vệ cuối kỳ | Video/kịch bản dự phòng, bộ test hồi quy pass 100%, báo cáo cuối kỳ & slide bảo vệ |

---

## 2. Sổ đăng ký Rủi ro & Biện pháp Giảm thiểu (Risk Register)

| ID | Rủi ro | Mức độ | Ảnh hưởng | Biện pháp giảm thiểu (Mitigation) | Người phụ trách |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **R-01** | `cptbox` bên trong Docker gặp lỗi quyền kernel (`SYS_PTRACE`, seccomp, cgroups v2) | Cao | Chặn chấm bài và tự xác minh đề | Spike kỹ thuật ngay đầu Tuần 13 (`--cap-add=SYS_PTRACE --security-opt seccomp=unconfined`) | **Nam** |
| **R-02** | `gemini-3.8-flash` Free Tier trả `429` hoặc bị người dùng lách cache (thêm space/comment, bấm 2 tab, gửi bài `CE`) | Cao | Gián đoạn demo / đốt hết quota | 1) On-demand + chặn cứng `422` với bài `CE`; 2) **Gateway tự canonicalize (xóa comment/space) + `sha256` + `singleflight` lock**; 3) Exponential backoff + `MOCK_AI=true` | **Long** & **Khánh** |
| **R-03** | AI sinh `generator.py` hoặc `reference.cpp` sai cú pháp / không đạt `AC` khi tự xác minh | Trung bình | Job `PROBLEM_GENERATE` rơi vào `FAILED` | JSON Schema nghiêm ngặt + prompt kèm mẫu `generator.py` chuẩn 4 tầng; mở rộng Self-Revision ở P1 (#16) | **Long** & **Nam** |
| **R-04** | Lệch tên trường giữa OpenAPI, PostgreSQL, Redis Streams và Frontend | Trung bình | Lỗi tích hợp phút chót ở Tuần 14 | Khóa chặt `contracts/openapi.yaml` và `contracts/redis-schemas.json`; chạy Postman Collection trên cả Prism và Gateway thật | **Khánh** |
| **R-05** | Phình phạm vi Frontend (sa đà vào Backend LSP `clangd`/`pyright` hoặc WebSocket) | Trung bình | Trễ tiến độ 3 màn hình chính | Khóa cứng kiến trúc Option 1: chỉ dùng **Tree-sitter WASM Syntax Gate + Client Formatter** (0 tải server, dễ mở rộng language pack `.wasm`), tuyệt đối không dựng Backend LSP | **Sơn** |
| **R-06** | Xung đột Git khi 4 người cùng sửa `docs/*.md` | Thấp | Tốn thời gian resolve conflict | Áp dụng quy ước thư mục riêng `docs/<member>/` (`docs/nam/`, `docs/khanh/`, `docs/long/`, `docs/son/`); Nam tổng hợp vào `docs/*.md` sau cùng | **Nam** (cả nhóm) |

---

## 3. Ma trận Công việc theo Thành viên (Tuần 12 & Tuần 13)

| Thành viên | Nhiệm vụ Tuần 12 (Trong `docs/<member>/`) | Nhiệm vụ Tuần 13 (Core Implementation) | Nhánh Git đề xuất |
| :--- | :--- | :--- | :--- |
| **Nam** *(Judge Infra & Redis Broker)* | - Review `contracts/redis-schemas.json`, sơ đồ SOA/Sequence & kiểm chứng `docker-compose.mock.yml`<br>- Đồng bộ tài liệu kiến trúc trong `docs/nam/` (P0/P1/P2 + Option 1 Editor/Hash) & tổng hợp `docs/*.md` | - Dựng `services/judge-worker/Dockerfile` từ `dmoj/judge-small`, spike `cptbox`<br>- Go Redis Streams worker cho `verify_jobs` và `judge_jobs`, thu thập `subtask_timings[]` | `docs/w12-align-ai-roadmap`<br>`feat/w13-nam-judge-worker` |
| **Khánh** *(Core Gateway, Auth & DB)* | - Đối chiếu `contracts/openapi.yaml` với `001_init.sql`<br>- Chạy Postman Collection trên Prism & ghi nhận vào `docs/khanh/` | - Go Gateway: JWT + RBAC, migrations/seed, CRUD + `ETag`, `202` Job Dispatcher, Redis consumer<br>- **Server-side Canonicalizer (xóa comment/space) + `sha256` + `singleflight` lock + chặn `422` cho bài `CE`** | `docs/w12-khanh-openapi-erd`<br>`feat/w13-khanh-gateway-core` |
| **Long** *(AI Pedagogical Service)* | - Kiểm chứng `gemini-3.8-flash` payload thật, chốt stack Python FastAPI & tài liệu T12 trong `docs/long/` (PR #23) | - AI Service P0 (`/internal/ai/generate-problem`, `/internal/ai/analyze-complexity`, `X-Internal-API-Key`, backoff `429`, `MOCK_AI=true`, tách module sẵn sàng cho P1) | `docs/w12-long-ai-design`<br>`feat/w13-long-ai-service` |
| **Sơn** *(Client SPA & Presentation)* | - **Đã merge PR #27:** Project Brief, 3 wireframe SVG, Slide PDF 7 trang & 6 ảnh mock | - React SPA + `@monaco-editor/react` + **Client WASM Syntax Gate (`web-tree-sitter` C++/Python packs) + Client Formatter** (không Backend LSP)<br>- Nối 3 màn hình chính + Job polling + Big-O Hint Drawer | `docs/w12-son-brief-wireframes`<br>`feat/w13-son-frontend-spa` |
