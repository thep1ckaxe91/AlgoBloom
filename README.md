# AlgoBloom — Hệ thống Online Judge Tích hợp AI Sư phạm

**AlgoBloom** là hệ thống chấm bài lập trình trực tuyến tăng cường AI (AI-Augmented Online Judge) được thiết kế theo kiến trúc hướng dịch vụ (**SOA — Gateway Orchestration**), giải quyết hai khoảng trống lớn của các hệ thống OJ truyền thống (Codeforces, LeetCode, DMOJ):

1. **Teacher Intent-Driven Problem Studio:** Giáo viên chọn tổ hợp thẻ thuật toán (chuẩn Codeforces) + độ khó mục tiêu (+ hồ sơ điểm yếu học sinh tùy chọn) thay vì viết prompt tự do. Hệ thống tự động sinh đề bài, mã nguồn sinh test (`generator.py`) và lời giải tối ưu C++ (`reference.cpp`), sau đó **tự xác minh trong sandbox cô lập** qua các tầng kích thước dữ liệu ($N = 10^2, 10^3, 10^4, 10^5$) trước khi xuất bản.
2. **Student Empirical Big-O & Socratic Hint Coach:** Bài nộp của học sinh được chấm trên các subtask phân tầng để đo thời gian thực nghiệm và xác định "vách đá TLE". Khi học sinh chủ động bấm nút yêu cầu phân tích (on-demand), AI kết hợp mã nguồn và số liệu thời gian thực tế để chẩn đoán độ phức tạp Big-O hiện tại so với mục tiêu, đồng thời đưa ra gợi ý theo phương pháp Socratic mà không làm lộ lời giải hoàn chỉnh.

---

## Tóm tắt Kiến trúc SOA (Gateway Orchestration — Option A)

- **`frontend/` (Client SPA):** React + `@monaco-editor/react` + **Client-side Tree-sitter WASM Syntax Gate (C++, Python) + Client Formatter** (không Backend Full LSP). Chỉ giao tiếp với Core Gateway qua `/api/v1/*`, polling trạng thái job `GET /api/v1/jobs/{jobId}` và tận dụng HTTP `ETag` caching của trình duyệt.
- **`services/gateway/` (Core Gateway & Orchestrator — Go + PostgreSQL):** Thành phần **duy nhất** sở hữu cơ sở dữ liệu PostgreSQL. Phụ trách xác thực JWT/RBAC (`TEACHER`, `STUDENT`) với Redis TTL refresh token (`auth:refresh:<jti>`), danh mục Tag, Student Weakness Profiler, điều phối tác vụ bất đồng bộ `202 Accepted`, **Server-side Canonicalizer + `sha256` + `singleflight` lock + CE Gate (`422`)**, gọi nội bộ tới AI Service và tiêu thụ kết quả từ Redis Streams.
- **`services/ai-service/` (AI Pedagogical Service — Python FastAPI):** Dịch vụ nội bộ (bảo vệ bởi header `X-Internal-API-Key`), tích hợp Gemini Free Tier với JSON Schema đầu ra nghiêm ngặt, cơ chế exponential backoff cho lỗi `429` và chế độ giả lập xác định `MOCK_AI=true`.
- **`services/judge-worker/` (Judge Infra — Go + `dmoj/judge-small`):** Worker kéo job qua Redis Streams (`verify_jobs`, `judge_jobs`) và đẩy kết quả (`verify_results`, `judge_results`) dùng `XADD`/`XREADGROUP`/`XACK`. Hoàn toàn stateless, **ZERO database credentials** và bị cô lập mạng `broker_net` (không chạm DB, không ra Internet). Worker xác minh mount `/data/problems:rw`; các worker chấm bài chỉ mount `:ro`.

---

## Phân công Thành viên (4 Thành viên)

| Thành viên | Vai trò chính | Phạm vi sở hữu chính trong Repo |
| :--- | :--- | :--- |
| **Nam** | Judge Infra & Redis Broker | `contracts/redis-schemas.json`, `services/judge-worker/`, pipeline tự xác minh đề bài, sơ đồ kiến trúc SOA & sequence |
| **Khánh** | Core Gateway, Auth & Database | `contracts/openapi.yaml`, `services/gateway/`, ERD PostgreSQL & SQL migrations/seed, phân tích Resource vs. DB Schema, Postman tests |
| **Long** | AI Pedagogical Service | `services/ai-service/`, hợp đồng AI nội bộ, kiểm chứng payload `gemini-3.8-flash`, chiến lược xử lý `429` & cache băm PostgreSQL |
| **Sơn** | Client SPA & Presentation | `frontend/`, `docs/project-brief.md`, wireframe 3 màn hình chính, slide báo cáo thiết kế (`docs/slides-outline-w12.md`), kịch bản demo Mock |

---

## Khởi chạy Full-Stack Dev với Database thật (Tuần 13+)

Yêu cầu: Docker & Docker Compose.

```bash
cp .env.example .env
docker compose up -d --build
```

Sau khi khởi động thành công:
- **Core Go Gateway:** http://localhost:8000 (`GET /health`)
- **Swagger UI:** http://localhost:8080 *(chọn server `http://localhost:8000` để gọi Gateway thật)*
- **PostgreSQL 16:** tự động chạy `001_init.sql` (7 bảng) & `002_seed.sql` khi khởi tạo lần đầu (mạng nội bộ `db_net` chỉ mở cho `gateway`)
- **Redis 7:** Streams broker + TTL refresh token store (`broker_net` nội bộ)

Các profile mở rộng khi đã sẵn sàng service tương ứng:
```bash
docker compose --profile workers up -d --build   # Kèm judge-verify-worker (:rw) & judge-worker (:ro)
docker compose --profile full up -d --build      # Toàn bộ stack gồm cả ai-service (Python FastAPI)
```

Tự kiểm chứng stack bằng script:
```bash
./scripts/verify-dev-stack.sh
```

---

## Khởi chạy Swagger UI + Prism Mock Server (Tuần 12 Contract Mock)

```bash
docker compose -f docker-compose.mock.yml up
```

Sau khi khởi động thành công:
- **Swagger UI:** http://localhost:8080 (tự động trỏ về hợp đồng `contracts/openapi.yaml`, hỗ trợ bấm **Try it out** trực tiếp vào Prism)
- **Prism Mock Server:** http://localhost:4010 (bật sẵn CORS, trả về dữ liệu mẫu thực tế từ `contracts/openapi.yaml`)

Ví dụ kiểm tra nhanh qua `curl`:
```bash
curl -s http://localhost:4010/api/v1/tags | head -c 300
curl -s -H "Authorization: Bearer mock-token" http://localhost:4010/api/v1/problems | head -c 300
```

---

## Cấu trúc Thư mục Monorepo

```text
AlgoBloom/
├── contracts/
│   ├── openapi.yaml                                  # Hợp đồng REST API chuẩn OpenAPI 3.0.3
│   └── redis-schemas.json                            # JSON Schema & payload mẫu cho 4 Redis Streams
├── docs/
│   ├── adr-summary.md                                # Quyết định kiến trúc & phân tích đánh đổi (ADR)
│   ├── project-brief.md                              # Mô tả bài toán, phạm vi MVP & luồng demo chính
│   ├── design.md                                     # Resource Model, ERD, SOA Topology & Sequence
│   ├── backlog-and-plan.md                           # Lộ trình Tuần 12-15, Risk Register & Ma trận công việc
│   ├── slides-outline-w12.md                         # Dàn ý 7 slide Design Review & kịch bản demo
│   └── progress-report-w12.md                        # Báo cáo tiến độ Tuần 12 (mẫu nộp giảng viên)
├── services/
│   ├── gateway/                                      # Khung Go Core Gateway + PostgreSQL migrations
│   ├── judge-worker/                                 # Khung Go Redis Streams Worker + Dockerfile dmoj/judge-small
│   └── ai-service/                                   # Đặc tả & JSON Schema nội bộ cho AI Service
├── frontend/                                         # Hướng dẫn & ràng buộc triển khai React SPA
├── tests/postman/                                    # Bộ kiểm thử hợp đồng Postman (W12 Mock -> W13 Gateway)
└── docker-compose.mock.yml                           # Stack demo Swagger UI + Stoplight Prism
```

---

## Quy ước Git Branching & Pull Request

- **Nhánh chính (`main`):** Luôn ở trạng thái sạch, hợp lệ. Không push trực tiếp các thay đổi lớn lên `main` sau giai đoạn bootstrap.
- **Đặt tên nhánh:** `<type>/<week>-<member>-<short-topic>`
  - Ví dụ: `docs/w12-son-brief-slides`, `feat/w13-khanh-gateway-auth`, `feat/w13-nam-judge-worker`, `fix/w13-long-ai-retry`.
- **Các tiền tố hợp lệ:** `feat/`, `docs/`, `fix/`, `refactor/`, `chore/`.
- **Quy tắc PR & Review:**
  - Mỗi thành viên tạo PR gắn với GitHub Issue tương ứng (`Closes #<id>`).
  - Yêu cầu ít nhất **1 thành viên khác review và approve** trước khi merge vào `main`.
  - Không commit file `.env` chứa secret thật hoặc dữ liệu volume cục bộ.
