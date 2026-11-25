# Tóm tắt Quyết định Kiến trúc & Đánh đổi (ADR Summary) — AlgoBloom

Tài liệu này ghi nhận các quyết định kiến trúc cốt lõi (Architecture Decision Records) của hệ thống **AlgoBloom**, đã cập nhật bổ sung cơ chế chống spam Compile Error / lách cache (ADR-05, ADR-06) và lộ trình tiến hóa AI Service 2 vòng lặp (ADR-07).

---

## ADR-01: Tách rời `dmoj/judge-small` (Headless) thay vì triển khai nguyên khối DMOJ Monolith

- **Bối cảnh:** AlgoBloom cần sandbox chấm bài C++/Python an toàn (cách ly syscall, giới hạn CPU/RAM chính xác) để đo thời gian chạy theo từng subtask phân tầng ($N = 10^2, 10^3, 10^4, 10^5$).
- **Quyết định:** Chỉ sử dụng container tối giản `dmoj/judge-small` kèm `dmoj-cli` và `cptbox` ở chế độ headless, được bọc bởi một Go Redis Streams Worker (`services/judge-worker/`). Không triển khai DMOJ Django site, Celery, hay Bridge server gốc.
- **Lý do & Đánh đổi:**
  - *Ưu điểm:* Giảm mạnh footprint tài nguyên, loại bỏ phụ thuộc vào schema Django/MySQL của DMOJ, kiểm soát trực tiếp định dạng `subtask_timings[]` trả về cho AI Coach.
  - *Nhược điểm:* Nhóm tự viết lớp wrapper gọi `dmoj-cli`, đóng gói `init.yml` và parse kết quả đầu ra.
  - *Kiểm soát rủi ro:* Nam thực hiện spike kiểm chứng `cptbox` trong Docker ngay đầu Tuần 13 (`SYS_PTRACE` / seccomp).

---

## ADR-02: Hàng đợi kéo (Pull-based Competing Consumers) qua Redis Streams thay vì HTTP Load Balancer

- **Bối cảnh:** Tác vụ sinh test + xác minh đề (`verify_jobs`) và chấm bài (`judge_jobs`) tốn nhiều CPU với thời gian thực thi biến động mạnh.
- **Quyết định:** Giao tiếp bất đồng bộ giữa Core Gateway và Judge Workers thông qua 4 Redis Streams (`verify_jobs`, `verify_results`, `judge_jobs`, `judge_results`) sử dụng `XADD` / `XREADGROUP` / `XACK`. Không đặt HTTP Load Balancer trước các Judge Worker.
- **Lý do & Đánh đổi:**
  - *Ưu điểm:* Tự nhiên hỗ trợ backpressure (worker rảnh mới kéo job), scale ngang dễ dàng cùng consumer group, chống mất job khi worker crash (qua Pending Entries List — PEL).
  - *Nhược điểm:* Cần cơ chế polling trạng thái job (`GET /api/v1/jobs/{jobId}`) và xử lý idempotency khi retry PEL.

---

## ADR-03: Kiến trúc SOA — Gateway Orchestration (Option A) thay vì Choreography phân tán

- **Bối cảnh:** Luồng nghiệp vụ liên quan đến 3 thành phần: Gateway, AI Service và Judge Worker.
- **Quyết định:** Áp dụng **Gateway Orchestration** (`services/gateway/` bằng Go). Gateway là thành phần **duy nhất** sở hữu PostgreSQL:
  - Client SPA chỉ giao tiếp với Gateway qua `/api/v1/*`.
  - Gateway gọi nội bộ tới AI Service qua header `X-Internal-API-Key`.
  - Judge Worker hoàn toàn stateless và có **ZERO database credentials**.
  - Verification worker mount `/data/problems:rw`; Judging workers chỉ mount `:ro`.
- **Lý do & Đánh đổi:**
  - *Ưu điểm:* Ranh giới bảo mật rõ ràng (sandbox không bao giờ chạm được DB), quản lý trạng thái `jobs` tập trung tại 1 nguồn chân lý.
  - *Nhược điểm:* Gateway tập trung nhiều logic điều phối hơn; bắt buộc tách gọn `handler` / `service` / `repo`.

---

## ADR-04: Chẩn đoán Big-O bằng Subtask phân tầng thực nghiệm kết hợp LLM thay vì chỉ dùng LLM đọc code

- **Bối cảnh:** LLM đọc code thuần dễ ảo giác độ phức tạp với các vòng lặp có điều kiện thoát sớm hoặc hằng số ẩn.
- **Quyết định:** Mỗi đề bài có bộ test 4 tầng ($N = 10^2, 10^3, 10^4, 10^5$). Judge Worker thu thập `subtask_timings[]` thực tế; AI Service kết hợp **mã nguồn + số liệu thời gian thực nghiệm** để đối chiếu Big-O và đưa gợi ý Socratic (không lộ full code).
- **Lý do & Đánh đổi:**
  - *Ưu điểm:* Neo lập luận vào bằng chứng thực nghiệm ("vách đá TLE"), tăng độ tin cậy và tính sư phạm.
  - *Nhược điểm:* `generator.py` phải tuân thủ nghiêm ngặt cấu trúc tham số kích thước $N$ theo từng tầng.

---

## ADR-05: AI Coach On-Demand + Server-side Canonical Hash Cache + In-Flight Deduplication & Chặn `CE`

- **Bối cảnh:** `gemini-3.8-flash` (Free Tier) có giới hạn RPM/TPM chặt. Nếu chỉ tính `sha256` trên chuỗi `source_code` thô (hoặc tin hash do client gửi), người dùng chỉ cần thêm dấu cách, thêm comment (`// test`), nộp code lỗi biên dịch (`CE`), hoặc mở 2 tab bấm "Phân tích" cùng lúc là có thể lách cache và đốt cạn quota `429`.
- **Quyết định:** Áp dụng **4 lớp bảo vệ tại Core Gateway** (theo nguyên tắc *Never trust the client*):
  1. **Kích hoạt On-Demand:** Tuyệt đối không tự động gọi AI sau khi chấm; học sinh phải chủ động bấm nút `POST /api/v1/submissions/{submissionId}/analyze`.
  2. **Chặn cứng Compile Error (`CE`):** Gateway từ chối ngay với `422 Unprocessable Entity` nếu `submission.status == 'CE'` (hoặc chưa chấm xong) — không đốt tài nguyên AI cho code lỗi cú pháp/biên dịch.
  3. **Server-side Canonicalization + `sha256`:** Trước khi tra/lưu bảng `ai_cache`, Gateway tự chạy bộ chuẩn hóa nhẹ (~0.1ms trong Go: **xóa comment `//`, `/* */`, `#` + chuẩn hóa khoảng trắng/xuống dòng**) rồi **tự tính `sha256(canonical_source_code)`** ở server. Client vẫn format code cho đẹp UX, nhưng server không bao giờ tin hash hay giả định đầu vào đã format từ client.
  4. **In-Flight Deduplication Lock:** Dùng `golang.org/x/sync/singleflight` (hoặc Redis `SETNX` lock theo khóa `analyze:{problem_id}:{sha256}`) kết hợp `INSERT ... ON CONFLICT` để chặn tình trạng mở 2 tab bấm cùng lúc gây 2 request LLM song song.
- **Lý do & Đánh đổi:**
  - *Ưu điểm:* Chống triệt để lách cache bằng dấu cách/comment/curl, chống race condition 2 tab, không tốn quota AI cho bài `CE`, giữ nguyên schema bảng `ai_cache(problem_id, source_code_sha256)`.
  - *Nhược điểm:* Cần viết hàm canonicalizer riêng cho cú pháp comment của từng ngôn ngữ hỗ trợ (C++, Python — dễ mở rộng theo bảng cấu hình ngôn ngữ).

---

## ADR-06: Plain Monaco + Client-side WASM Syntax Gate & Formatter (Không chạy Backend Full LSP) + HTTP `ETag`

- **Bối cảnh:** Người mới học thường nộp code lỗi cú pháp cơ bản (thiếu `;`, lệch ngoặc, sai thụt lề Python) gây lãng phí lượt chấm của Judge Worker. Đồng thời nhóm muốn chuẩn hóa code ngay trên trình duyệt để hỗ trợ UX trước khi nộp, với kiến trúc có thể mở rộng thêm gói ngôn ngữ mới.
- **Quyết định:**
  - Dùng `@monaco-editor/react` kết hợp **Client-side WASM Syntax Checker (`web-tree-sitter`)** + **Client Formatter** (gói ngôn ngữ MVP: C++, Python; thiết kế dạng plugin language pack `.wasm` để dễ mở rộng thêm Java/Rust/Go sau này).
  - Khi học sinh bấm **Submit**:
    1. Trình duyệt chạy kiểm tra cú pháp tức thì bằng Tree-sitter WASM; nếu phát hiện lỗi cú pháp nghiêm trọng (`ERROR` / `MISSING` node trong CST), chặn gửi và báo vị trí lỗi cho người dùng sửa ngay trên trình duyệt.
    2. Nếu qua bước kiểm tra cú pháp, Client chạy Formatter làm sạch code trước khi gửi `POST /api/v1/submissions` lên Gateway (sau đó Gateway vẫn tự canonicalize & tính `sha256` theo ADR-05).
  - **Không** triển khai Backend Full LSP (`clangd`/`pyright` qua WebSocket).
  - Giữ HTTP `ETag` / `If-None-Match` (`304 Not Modified`) cho `GET /api/v1/problems/{id}` và `GET /api/v1/submissions/{id}`.
- **Lý do & Đánh đổi:**
  - *Ưu điểm:* Bắt được ~80% lỗi CE phổ biến với **0 tải CPU/RAM trên server**, không cần WebSocket proxy, tránh hoàn toàn rủi ro bảo mật `#include "/etc/passwd"` của `clangd`, và mở rộng ngôn ngữ mới chỉ bằng cách nạp thêm grammar `.wasm`. ~20% lỗi semantic/type còn lại được `g++` trên Judge Worker fail nhanh (~150ms, không chạy test) và bị Gateway chặn ở `/analyze`.
  - *Nhược điểm:* Không có kiểm tra kiểu dữ liệu/semantic sâu hay auto-complete STL như IDE cục bộ (chấp nhận được và đồng nhất với thông lệ của Codeforces/AtCoder/DMOJ).

---

## ADR-07: Phân pha Tiến hóa AI Service (P0 → P1 → P2) theo Kiến trúc 2 Vòng lặp (Machine Loop & Human Loop)

- **Bối cảnh:** Đề xuất #15 định hướng mở rộng AlgoBloom thành AI-native Adaptive Online Judge với multi-agent generation (Coverage, Adversarial, Self-Revision) và hiệu chỉnh độ khó bằng phản hồi con người (Human Feedback Loop). Nếu gộp toàn bộ vào Tuần 13 sẽ gây phình phạm vi và vỡ hợp đồng của Gateway, Judge Worker và Frontend.
- **Quyết định:** Áp dụng lộ trình tiến hóa 3 pha không phá vỡ hợp đồng P0:
  - **P0 (Tuần 12–13):** Giữ nguyên 100% hợp đồng `/internal/ai/*`, OpenAPI 3.0.3 và Redis Streams; chỉ yêu cầu `services/ai-service/` tách module sạch (`llm_client` / `agents` / `schemas`).
  - **P1 (Machine Loop — #16, #17):** Mở rộng tương thích ngược cho Self-Revision Loop và Adversarial testing (`adversarial_solutions[]` tùy chọn trên `verify_jobs`).
  - **P2 (Human Loop — #18, #19):** Chỉ triển khai sau khi P0 + P1 ổn định (thêm `problem_feedback`, `calibrated_difficulty` và benchmark ablation).
- **Lý do & Đánh đổi:**
  - *Ưu điểm:* Bảo vệ tuyệt đối mốc Design Review (Tuần 12) và Implementation Review (Tuần 13) của cả 4 thành viên, đồng thời có định hướng nghiên cứu sâu rõ ràng.
  - *Nhược điểm:* Cần duy trì tính tương thích ngược khi mở rộng schema giữa P0 và P1/P2.

---

## Bảng tổng hợp Đánh đổi Kiến trúc

| Chủ đề | Lựa chọn chốt (AlgoBloom) | Phương án loại bỏ | Đánh đổi chính |
| :--- | :--- | :--- | :--- |
| Sandbox chấm bài | `dmoj/judge-small` + Go Worker | DMOJ Monolith | Tự viết wrapper đổi lấy nhẹ và tách DB hoàn toàn |
| Giao tiếp Worker | Redis Streams (`XREADGROUP`) | HTTP Load Balancer | Thêm polling `jobs` đổi lấy backpressure & resilience |
| Điều phối SOA | Gateway Orchestration (Option A) | Event Choreography | Gateway nhiều logic hơn đổi lấy bảo mật 1 nguồn chân lý DB |
| Phân tích Big-O | Subtask thực nghiệm + LLM | Chỉ LLM đọc code | `generator.py` phức tạp hơn đổi lấy chẩn đoán có căn cứ |
| Gọi AI & Chống lách cache | On-demand + Server Canonical Hash + `singleflight` + chặn `CE` | Auto-trigger / Client-side hash | Viết canonicalizer theo ngôn ngữ đổi lấy chống lách cache & 2-tab race |
| Editor & Tiền kiểm lỗi | Monaco + WASM Syntax Gate (`web-tree-sitter`) + Formatter | Backend Full LSP (`clangd`/`pyright` WS) | Không check semantic sâu đổi lấy 0 tải server, an toàn, dễ mở rộng language pack |
| Tiến hóa AI Service | Phân pha P0 → P1 → P2 (2 vòng lặp) | Nhồi Agentic + Calibration vào W13 | Tách follow-up issues đổi lấy giữ ổn định tiến độ MVP |
