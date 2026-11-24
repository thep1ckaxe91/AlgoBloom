# Tài liệu Thiết kế Hệ thống (Design Document) — AlgoBloom *(Bản cập nhật: Nam)*

Tài liệu này mô tả chi tiết mô hình tài nguyên REST, sơ đồ cơ sở dữ liệu PostgreSQL, sự tách biệt giữa Resource Model và Database Schema, kiến trúc SOA (Gateway Orchestration), luồng tuần tự có **WASM Syntax Gate + Client Formatter + Server-side Canonical Hash / `singleflight` / CE Gate**, và chiến lược kiểm thử của **AlgoBloom**.

---

## 1. Mô hình Tài nguyên (Resource Model) & Quy ước Đặt tên

### 1.1 Quy ước Đặt tên & Định danh
- **Base path:** `/api/v1`
- **Tên tài nguyên:** Danh từ số nhiều, chữ thường, `kebab-case` cho đường dẫn: `/problems`, `/submissions`, `/tags`, `/jobs`, `/students/{studentId}/weaknesses`.
- **Trường JSON:** `snake_case` thống nhất toàn hệ thống (OpenAPI, PostgreSQL, Redis Streams, AI Service).
- **Định danh (Identifiers):** UUID v4 (`string`, format `uuid`).
- **Caching:** `GET /api/v1/problems/{problemId}` và `GET /api/v1/submissions/{submissionId}` trả về weak `ETag` (`W/"problem-<uuid>-v1"`) hỗ trợ `If-None-Match` -> `304 Not Modified`.
- **Tác vụ bất đồng bộ:** `POST /api/v1/problems/generate` và `POST /api/v1/submissions` trả về `202 Accepted` kèm `job_id` để client polling tại `GET /api/v1/jobs/{jobId}`.

### 1.2 Sơ đồ Mô hình Tài nguyên (Resource Model Diagram)

```mermaid
classDiagram
    class User {
        +UUID id
        +string email
        +string full_name
        +enum role [TEACHER, STUDENT]
        +datetime created_at
    }

    class Tag {
        +UUID id
        +string slug
        +string name
        +enum category [ALGORITHM, DATA_STRUCTURE, TECHNIQUE]
    }

    class Problem {
        +UUID id
        +string slug
        +string title
        +string statement_md
        +int difficulty
        +int time_limit_ms
        +int memory_limit_mb
        +string target_complexity
        +Tag[] tags
        +SampleCase[] sample_cases
        +SubtaskTier[] subtask_tiers
        +enum status [DRAFT, VERIFYING, PUBLISHED, FAILED]
    }

    class Submission {
        +UUID id
        +UUID problem_id
        +UUID student_id
        +enum language [cpp17, cpp20, python3]
        +string source_code
        +enum status [PENDING, RUNNING, AC, WA, TLE, MLE, RE, CE, IE]
        +int score
        +int max_time_ms
        +int max_memory_kb
        +SubtaskTiming[] subtask_timings
    }

    class BigOAnalysis {
        +UUID submission_id
        +string detected_complexity
        +string target_complexity
        +string bottleneck_summary
        +string socratic_hint
        +string[] guiding_questions
        +boolean cached
    }

    class Job {
        +UUID id
        +enum type [PROBLEM_GENERATE, SUBMISSION_JUDGE]
        +enum status [PENDING, RUNNING, COMPLETED, FAILED]
        +string resource_type
        +UUID resource_id
        +object result
        +string error_code
        +string error_message
    }

    class StudentWeakness {
        +UUID student_id
        +WeakTagStat[] weak_tags
        +int recommended_difficulty
        +datetime computed_at
    }

    User "1" --> "*" Problem : creates (TEACHER)
    User "1" --> "*" Submission : submits (STUDENT)
    User "1" --> "1" StudentWeakness : computed projection
    Problem "*" --> "*" Tag : embeds tags[]
    Problem "1" --> "*" Submission : receives
    Submission "1" --> "0..1" BigOAnalysis : on-demand /analyze (non-CE)
    Job ..> Problem : tracks PROBLEM_GENERATE
    Job ..> Submission : tracks SUBMISSION_JUDGE
```

---

## 2. Sơ đồ Cơ sở Dữ liệu PostgreSQL (ERD)

Core Gateway (`services/gateway/`) là thành phần **duy nhất** sở hữu schema và kết nối trực tiếp tới PostgreSQL. Định nghĩa DDL chuẩn nằm tại `services/gateway/migrations/001_init.sql`.

> **Ghi chú kỹ thuật về `source_code_sha256`:** Cột `source_code_sha256` trong `submissions` và `ai_cache` luôn lưu mã băm `SHA-256` của **mã nguồn sau khi Gateway tự canonicalize** (xóa comment + chuẩn hóa khoảng trắng), tuyệt đối không băm chuỗi thô và không nhận hash do client gửi lên.

```mermaid
erDiagram
    users ||--o{ problems : "created_by"
    users ||--o{ submissions : "student_id"
    users ||--o{ jobs : "requested_by"
    problems ||--o{ problem_tags : "has"
    tags ||--o{ problem_tags : "tagged_in"
    problems ||--o{ submissions : "target"
    problems ||--o{ ai_cache : "cached_for"

    users {
        uuid id PK
        text email UK
        text password_hash
        text full_name
        text role
        timestamptz created_at
        timestamptz updated_at
    }

    tags {
        uuid id PK
        text slug UK
        text name
        text category
    }

    problems {
        uuid id PK
        text slug UK
        text title
        text statement_md
        text input_format_md
        text output_format_md
        text constraints_md
        int difficulty
        int time_limit_ms
        int memory_limit_mb
        text target_complexity
        jsonb sample_cases
        jsonb subtask_tiers
        text generator_code
        text reference_solution_cpp
        text storage_path
        text status
        uuid created_by FK
        int version
        timestamptz created_at
        timestamptz updated_at
    }

    problem_tags {
        uuid problem_id PK,FK
        uuid tag_id PK,FK
    }

    submissions {
        uuid id PK
        uuid problem_id FK
        uuid student_id FK
        text language
        text source_code
        char64 source_code_sha256
        text status
        int score
        int max_time_ms
        int max_memory_kb
        jsonb subtask_timings
        text compiler_output
        int version
        timestamptz created_at
        timestamptz judged_at
    }

    jobs {
        uuid id PK
        text type
        text status
        uuid requested_by FK
        text resource_type
        uuid resource_id
        jsonb payload
        jsonb result
        text error_code
        text error_message
        timestamptz created_at
        timestamptz updated_at
        timestamptz completed_at
    }

    ai_cache {
        uuid id PK
        uuid problem_id FK
        char64 source_code_sha256
        text language
        text detected_complexity
        text target_complexity
        text bottleneck_summary
        text socratic_hint
        jsonb guiding_questions
        text model_version
        timestamptz created_at
    }
```

---

## 3. Vì sao Resource Model KHÁC với Database Schema?

| Khía cạnh | Trong PostgreSQL Schema | Trong Public REST Resource Model | Lý do tách biệt |
| :--- | :--- | :--- | :--- |
| **Quan hệ nhiều-nhiều `problems` <-> `tags`** | Bảng trung gian `problem_tags(problem_id, tag_id)` chuẩn hóa 3NF | Mảng nhúng `tags: Tag[]` ngay bên trong đối tượng `Problem` | Tránh N+1 request phía Frontend; bảng nối không có ý nghĩa độc lập với consumer. |
| **Hồ sơ điểm yếu (`StudentWeakness`)** | **Không có bảng riêng** (tổng hợp động bằng `JOIN`) | Tài nguyên chỉ đọc `GET /api/v1/students/{studentId}/weaknesses` | Dữ liệu dẫn xuất (computed projection), tránh dư thừa đồng bộ ở MVP. |
| **Bảng `ai_cache`** | Khóa duy nhất `(problem_id, source_code_sha256)` trên mã nguồn đã canonicalize | **Ẩn hoàn toàn** khỏi public API; chỉ biểu diễn qua `cached: boolean` | Caching & canonicalization là tối ưu nội bộ phía Gateway; không tin hash từ client. |
| **Trường nhạy cảm / nội bộ** | `password_hash`, `generator_code`, `reference_solution_cpp`, `storage_path`, `source_code_sha256` | **Loại bỏ hoàn toàn** khỏi response công khai | Bảo mật xác thực, chống gian lận lời giải mẫu và che giấu filesystem máy chủ. |
| **Cột `version`** | `version INT` trong `problems` và `submissions` | Ánh xạ thành HTTP Header `ETag: W/"problem-<id>-v<version>"` | Tận dụng cơ chế chuẩn HTTP `304 Not Modified`. |
| **Tài nguyên bất đồng bộ `Job`** | Lưu `payload` nội bộ + `(resource_type, resource_id)` | Chuẩn hóa `PENDING`/`RUNNING`/`COMPLETED`/`FAILED` + `resource_id` | Che giấu chi tiết Redis Streams và dễ mở rộng loại job mới. |

---

## 4. Kiến trúc Hệ thống SOA (System Architecture Diagram)

```mermaid
flowchart LR
    subgraph ClientZone["Vùng Client (Trình duyệt — 0 tải Server cho Syntax/Format)"]
        SPA["Client SPA (React + Monaco)<br/>Tree-sitter WASM Syntax Gate (C++/Py packs)<br/>+ Client Formatter (No Backend LSP)"]
    end

    subgraph CoreZone["Vùng Điều phối Trung tâm (Core Boundary)"]
        GW["Core Gateway & Orchestrator (Go)<br/>JWT/RBAC + ETag + Job Tracker<br/>Canonicalizer + SHA-256 + singleflight + CE Gate"]
        PG[("PostgreSQL<br/>(SOLE Owner: Gateway)")]
    end

    subgraph AIZone["Vùng Dịch vụ AI Nội bộ"]
        AI["AI Pedagogical Service<br/>(Internal Only)<br/>429 Backoff + MOCK_AI"]
        GEM["Gemini API<br/>gemini-3.8-flash (Free Tier)"]
    end

    subgraph BrokerZone["Message Broker"]
        RS[("Redis Streams<br/>verify_jobs / verify_results<br/>judge_jobs / judge_results")]
    end

    subgraph SandboxZone["Vùng Thực thi Cô lập (Zero DB Credentials)"]
        VW["Verification Worker (Go)<br/>dmoj/judge-small + cptbox"]
        JW["Judging Workers xN (Go)<br/>dmoj/judge-small + cptbox"]
        VOL[("Shared Volume<br/>/data/problems")]
    end

    SPA -- "HTTPS + JWT Bearer<br/>Polling /jobs/{id} + ETag" --> GW
    GW -- "SQL (Read/Write)" --> PG
    GW -- "Internal HTTP<br/>Header: X-Internal-API-Key" --> AI
    AI -- "HTTPS JSON Schema" --> GEM
    GW -- "XADD verify_jobs / judge_jobs" --> RS
    RS -- "XREADGROUP verify_results / judge_results" --> GW
    RS -- "XREADGROUP verify_jobs" --> VW
    VW -- "XADD verify_results" --> RS
    RS -- "XREADGROUP judge_jobs" --> JW
    JW -- "XADD judge_results" --> RS
    VW -- "Mount :rw" --> VOL
    JW -- "Mount :ro" --> VOL
```

### Tóm tắt Ranh giới Tin cậy (Trust Boundaries)

1. **Public Edge (`SPA -> Gateway`):** Chỉ cho phép HTTPS + JWT Bearer (`TEACHER` / `STUDENT`). Client chạy Tree-sitter WASM Syntax Gate & Formatter để cải thiện UX và chặn sớm lỗi cú pháp, nhưng **Gateway không bao giờ tin đầu vào đã format hay hash từ client** — Gateway luôn tự canonicalize và tự tính `sha256`.
2. **Internal AI Boundary (`Gateway -> AI Service`):** AI Service không mở port ra ngoài Internet; bắt buộc kiểm tra header `X-Internal-API-Key`.
3. **Sandbox Isolation (`Redis Streams -> Judge Workers`):** Judge Workers chạy code không tin cậy bên trong `cptbox`, **ZERO DB credentials**. Verification Worker mount `/data/problems:rw`; Judging Workers chỉ đọc `:ro`.

### Điểm mở rộng Kiến trúc cho P1 / P2 (Không phá vỡ hợp đồng P0 — Theo #15)

- **P1 (Machine Loop — #16, #17):** Kiến trúc Gateway Orchestration cho phép cắm vòng lặp **Self-Revision** (khi `verify_results.verified == false`, Gateway gọi lại AI Service với phản hồi lỗi tối đa `max_revisions` lần) và mở rộng trường tùy chọn `adversarial_solutions[]` trên `verify_jobs` để Judge Worker kiểm chứng mutation kill rate mà không thay đổi luồng P0.
- **P2 (Human Loop — #18, #19):** Sau khi P0/P1 ổn định, có thể bổ sung bảng `problem_feedback`, cột `calibrated_difficulty` và endpoint đánh giá chất lượng đề để cung cấp dữ liệu hiệu chỉnh độ khó thực nghiệm cho AI Service.

---

## 5. Sơ đồ Tuần tự Luồng Trọng tâm (Sequence Diagram)

```mermaid
sequenceDiagram
    autonumber
    actor Teacher as Giáo viên (SPA)
    actor Student as Học sinh (SPA + WASM)
    participant GW as Core Gateway (Go)
    participant DB as PostgreSQL
    participant AI as AI Service
    participant RS as Redis Streams
    participant JW as Judge Worker (cptbox)

    Note over Teacher,JW: PHA A: Sinh đề bài theo chủ đích & Tự xác minh 4 tầng Subtask
    Teacher->>GW: POST /api/v1/problems/generate (tags, difficulty, JWT TEACHER)
    GW->>DB: INSERT jobs (PROBLEM_GENERATE, PENDING)
    GW-->>Teacher: 202 Accepted { job_id }

    GW->>AI: POST /internal/ai/generate-problem (X-Internal-API-Key)
    AI-->>GW: { statement, generator.py, reference.cpp, subtask_tiers }
    GW->>DB: INSERT problems (status=VERIFYING), UPDATE jobs (RUNNING)
    GW->>RS: XADD verify_jobs { job_id, problem_id, generator_code, reference_solution_cpp }

    RS->>JW: XREADGROUP verify_jobs
    JW->>JW: Chạy generator.py tạo test 4 tầng (N=10^2..10^5) -> /data/problems/:rw
    JW->>JW: Biên dịch & chạy reference.cpp trong cptbox kiểm chứng AC toàn bộ
    JW->>RS: XADD verify_results { job_id, problem_id, verified: true, subtask_benchmarks }

    RS->>GW: XREADGROUP verify_results
    GW->>DB: UPDATE problems (status=PUBLISHED), UPDATE jobs (COMPLETED, resource_id)
    Teacher->>GW: GET /api/v1/jobs/{job_id}
    GW-->>Teacher: 200 OK { status: COMPLETED, resource_id: problem_id }

    Note over Student,JW: PHA B: WASM Syntax Gate + Format -> Nộp bài -> Chặn CE & Canonical Hash Cache
    Student->>Student: Tree-sitter WASM kiểm tra cú pháp (C++/Python pack)
    alt Lỗi cú pháp nghiêm trọng
        Student-->>Student: Báo lỗi tại Editor (chặn submit, 0 tải server)
    else Hợp lệ cú pháp
        Student->>Student: Client Formatter chuẩn hóa code (UX)
        Student->>GW: POST /api/v1/submissions (problem_id, cpp20, source_code)
    end

    GW->>GW: Server Canonicalizer (xóa comment + khoảng trắng) -> sha256
    GW->>DB: INSERT submissions (PENDING, canonical_sha256) & jobs (SUBMISSION_JUDGE)
    GW-->>Student: 202 Accepted { job_id, submission_id }
    GW->>RS: XADD judge_jobs { job_id, submission_id, storage_path, source_code }

    RS->>JW: XREADGROUP judge_jobs
    JW->>JW: Chấm trên /data/problems/:ro đo thời gian từng subtask tier
    JW->>RS: XADD judge_results { status: TLE, score: 50, subtask_timings[] }
    RS->>GW: XREADGROUP judge_results
    GW->>DB: UPDATE submissions (TLE, subtask_timings), UPDATE jobs (COMPLETED)

    Student->>GW: GET /api/v1/submissions/{submission_id}
    GW-->>Student: 200 OK + ETag { status: TLE, subtask_timings[] }

    Student->>GW: POST /api/v1/submissions/{submission_id}/analyze (On-Demand)
    alt submission.status == CE hoặc chưa chấm xong
        GW-->>Student: 422 VALIDATION_ERROR (không phân tích bài lỗi biên dịch)
    else Bài đã chấm (non-CE)
        GW->>GW: singleflight / Redis lock theo (problem_id, canonical_sha256)
        GW->>DB: SELECT * FROM ai_cache WHERE (problem_id, source_code_sha256)
        alt Cache Hit
            GW-->>Student: 200 OK { detected_complexity, socratic_hint, cached: true }
        else Cache Miss
            GW->>AI: POST /internal/ai/analyze-complexity (code + subtask_timings)
            AI-->>GW: { detected_complexity: O(N^2), socratic_hint, guiding_questions }
            GW->>DB: INSERT INTO ai_cache ON CONFLICT DO NOTHING
            GW-->>Student: 200 OK { detected_complexity, socratic_hint, cached: false }
        end
    end
```

---

## 6. Ngăn xếp Công nghệ & Chiến lược Kiểm thử

### 6.1 Tech Stack
- **Frontend:** React + TypeScript + `@monaco-editor/react` + **`web-tree-sitter` (WASM language packs: C++, Python) + Client Formatter** (không chạy Backend Full LSP).
- **Core Gateway:** Go (`net/http`, `pgx`, `go-redis`, `golang.org/x/sync/singleflight`), PostgreSQL 16, Redis 7 Streams.
- **Judge Worker:** Go Redis Streams consumer bọc `dmoj/judge-small` (`dmoj-cli` + `cptbox`).
- **AI Service:** Python (FastAPI) gọi `gemini-3.8-flash` với structured JSON output (chi tiết tại `docs/long/`).
- **Contract & Mock Tooling:** OpenAPI 3.0.3, Swagger UI (`swaggerapi/swagger-ui`), Stoplight Prism 4 (`stoplight/prism:4`).

### 6.2 Chiến lược Kiểm thử (Testing Strategy)
1. **Tuần 12 (Contract-First Validation):** Kiểm tra OpenAPI 3.0.3, chạy `docker-compose.mock.yml`, chạy Postman Collection trên Prism.
2. **Tuần 13–14 (Unit, Integration & Sandbox Verification):**
   - **Go Gateway:** `httptest` kiểm chứng JWT/RBAC, `ETag` `304`, **canonicalizer (thêm space / comment ra cùng 1 `sha256`)**, `422` khi gọi `/analyze` trên bài `CE`, và **concurrent test 2 request song song vào `/analyze` chỉ gọi AI Service đúng 1 lần (`singleflight`)**.
   - **Frontend:** Kiểm chứng Tree-sitter WASM chặn lỗi cú pháp C++/Python trước khi gửi request và formatter chạy đúng trước `POST /submissions`.
   - **Judge Worker:** Kiểm thử `AC` $O(N \log N)$ vs `TLE` $O(N^2)$ trong `cptbox` qua Redis Streams.
   - **AI Service:** Kiểm thử JSON Schema validation ở cả `MOCK_AI=true` và `gemini-3.8-flash` thật + retry `429`.
