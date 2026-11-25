# Bản Tóm tắt Dự án (Project Brief) — AlgoBloom

## 1. Bài toán & Mục tiêu

Giáo viên tốn công tạo đề, bộ test và lời giải chuẩn; phản hồi `TLE`/`WA` chưa giúp học sinh tìm điểm nghẽn. AlgoBloom hướng tới giảm công sức tạo đề theo kỹ năng và hỗ trợ tự cải thiện thuật toán bằng chấm phân tầng, chẩn đoán Big-O và gợi ý Socratic.

## 2. Đối tượng sử dụng

- **Giáo viên (`TEACHER`):** Chọn tag, độ khó, tham khảo điểm yếu học sinh và yêu cầu sinh đề.
- **Học sinh (`STUDENT`):** Duyệt đề, viết/nộp code, xem kết quả và chủ động xin gợi ý qua Client SPA.

## 3. Các nghiệp vụ chính theo thiết kế

1. **UC-01 — Xác thực & Phân quyền:** Đăng ký/đăng nhập, cấp và làm mới JWT; chỉ giáo viên được sinh đề.
2. **UC-02 — Tra cứu tag & Điểm yếu:** Cung cấp danh mục tag và hồ sơ tổng hợp từ lịch sử nộp bài để định hướng chọn đề.
3. **UC-03 — Sinh & Tự xác minh đề:** Nhận tag, độ khó và học sinh mục tiêu tùy chọn; AI sinh đề, bộ sinh test, lời giải chuẩn. Worker xác minh trên bốn tầng kích thước trước khi xuất bản.
4. **UC-04 — Nộp bài & Chấm phân tầng (có Tiền kiểm cú pháp WASM):** Trước khi gửi bài, trình duyệt chạy **WASM Syntax Checker (`web-tree-sitter`)** để chặn lỗi cú pháp cơ bản ngay tại client và chạy **Client Formatter** làm sạch code. Gateway nhận mã nguồn/ngôn ngữ, chuẩn hóa & tính `sha256` ở phía server, trả `202 Accepted` và ID bài nộp/job; Client polling tới `COMPLETED` hoặc `FAILED`, xem verdict, điểm và thời gian từng subtask.
5. **UC-05 — Big-O & Gợi ý Socratic on-demand:** Chỉ gọi phân tích khi học sinh bấm nút (Gateway từ chối `422` nếu bài nộp bị `CE`). Trước khi gọi AI, Gateway tra cache băm PostgreSQL trên mã nguồn đã **canonicalize phía server** (xóa comment + chuẩn hóa khoảng trắng) kết hợp khóa chống trùng lặp đồng thời (`singleflight`/Redis lock) để chặn lách cache và bấm trùng 2 tab.

## 4. Phạm vi MVP vs. Ngoài phạm vi (Out-of-Scope)

| Hạng mục | Trong phạm vi MVP (Tuần 12–15) | Ngoài phạm vi (Out-of-Scope) |
| :--- | :--- | :--- |
| Người dùng | JWT, `TEACHER` / `STUDENT` | OAuth2/SSO, đa tổ chức |
| Sinh đề | Tag + độ khó, điểm yếu tùy chọn; tự xác minh 4 tầng | Prompt tự do, đề tương tác, special judge |
| Ngôn ngữ | `cpp17`, `cpp20`, `python3` (kiến trúc language pack dễ mở rộng) | Java, Rust, Go, C# |
| Soạn code | `@monaco-editor/react` + **Client WASM Syntax Gate (`web-tree-sitter`) + Formatter** | **Backend Full LSP** (`clangd`/`pyright` qua WebSocket), cộng tác thời gian thực |
| Trợ lý AI | Big-O thực nghiệm, Socratic on-demand, Server Canonical Hash Cache + `singleflight` + chặn `CE` | Chat tự do nhiều lượt, tự sửa code |
| Luyện tập | Danh sách đề, nộp cá nhân, hồ sơ điểm yếu | Thi quy mô lớn, xếp hạng ICPC realtime, chống đạo văn |
| Cập nhật | Polling job; `ETag`/`304` cho chi tiết đề/bài nộp | WebSocket, SSE |

## 5. Kiến trúc tổng quan & Giá trị SOA

**Gateway Orchestration (Option A)** phân định service boundaries:

- **Client → API Gateway (Go):** Chạy tiền kiểm cú pháp WASM & format ở trình duyệt, sau đó chỉ gọi `/api/v1/*` theo API Contract `contracts/openapi.yaml`; Gateway xác thực, phân quyền, tự canonicalize/hash mã nguồn, điều phối và độc quyền truy cập PostgreSQL.
- **Gateway → AI Service:** HTTP nội bộ, bảo vệ bằng `X-Internal-API-Key`; Client không gọi AI trực tiếp.
- **Gateway ↔ Judge Worker:** Job/kết quả qua Redis Streams bất đồng bộ; Worker chấm trong sandbox, không có DB credentials.

Contract hỗ trợ phát triển, kiểm thử độc lập; hàng đợi tách tác vụ nặng khỏi HTTP và cho phép mở rộng worker. Đổi lại, cần polling, xử lý message lặp và kiểm soát logic điều phối tại Gateway. Chi tiết: `docs/design.md`, `docs/adr-summary.md`.

## 6. Kịch bản minh họa & Giới hạn Mock Tuần 12

Luồng thiết kế, minh họa bằng dữ liệu Contract:

1. **Tạo đề:** Chọn `dp + binary-search`, độ khó `1600`; nhận job. Khi `Job.status = COMPLETED`, dùng `Job.resource_id` đọc đề và xác nhận `Problem.status = PUBLISHED`.
2. **Nộp code:** Học sinh đọc đề, vượt qua kiểm tra cú pháp WASM & format ở client, nộp lời giải C++ `O(N^2)` và theo dõi job chấm.
3. **Xem TLE:** Đọc kết quả mẫu `TLE`, 50/100 điểm, quan sát thời gian tăng và TLE từ tầng thứ ba.
4. **Xin gợi ý:** Bấm phân tích Big-O; nhận chẩn đoán `O(N^2)` so với mục tiêu `O(N log N)` và gợi ý Socratic.

**Swagger UI + Prism** chỉ minh họa request/response theo Contract; không sinh đề, chấm thật hay lưu trạng thái nghiệp vụ. Example phân tích hiện có `cached: false`; không cam kết lần gọi mock thứ hai trả `cached: true`. Cache hit, canonicalization và `singleflight` lock cần kiểm chứng trên Gateway/DB thật.

## 7. Định hướng Mở rộng AI Service sau MVP (Phân pha P0 → P1 → P2 — Theo Issue #15)

Để giữ tiến độ Tuần 12–13 ổn định đồng thời mở đường cho hướng nghiên cứu *Human-Calibrated Self-Evolving Programming Problem Generation*, nhóm phân pha rõ ràng:

- **P0 — Current MVP (Tuần 12–13, giữ nguyên hợp đồng hiện tại):** Bảo toàn toàn bộ `/api/v1/*`, `/internal/ai/*` và JSON Schemas đã chốt; tích hợp sinh đề tự xác minh 4 tầng + phân tích Big-O Socratic on-demand có server-side canonical hash cache.
- **P1 — Agentic Extension (Machine Loop — Sau Tuần 13, #16 & #17):** `Generate → Solve → Test → Verify → Revise`. Bổ sung Agent Orchestrator, Self-Revision Loop khi `verify_results.verified == false`, Coverage Agent (tìm tag/độ khó thiếu) và Adversarial Agent (sinh lời giải sai/chậm để kiểm chứng độ mạnh bộ test).
- **P2 — Human-Calibrated Learning & Research (Human Loop — Tuần 14–15 / Post-MVP, #18 & #19):** `Publish → Collect Feedback → Calibrate → Adapt Generation`. Thu thập đánh giá chất lượng đề, hiệu chỉnh độ khó thực nghiệm từ dữ liệu nộp bài thật, gợi ý thích ứng và chạy thực nghiệm ablation so sánh với single-LLM baseline.
