# Thư mục Tài liệu Làm việc của Nam (`docs/nam/`)

## Quy ước Làm việc Song song trên `docs/`

Để tránh xung đột merge (git conflict) khi 4 thành viên cùng chỉnh sửa các tài liệu thiết kế trong `docs/`, nhóm thống nhất quy ước:

- Thư mục làm việc riêng của từng thành viên đặt theo **tên ngắn viết thường** (khớp quy ước `docs/long/` đã dùng ở PR #23–#26):
  - `docs/nam/`
  - `docs/khanh/`
  - `docs/long/`
  - `docs/son/`
- Mỗi thành viên chỉnh sửa bản sao hoặc bổ sung tài liệu trong thư mục riêng của mình và mở PR bình thường.
- Các file gốc tại `docs/*.md` giữ làm **bản tổng hợp chính (master)**; Nam (Tech Lead) sẽ rà soát, tổng hợp nội dung từ cả 4 thư mục vào `docs/*.md` ở bước chốt cuối cùng.

---

## Nội dung Bản cập nhật trong `docs/nam/` (PR #20)

1. **`adr-summary.md`:**
   - Cập nhật **ADR-05:** Nâng cấp cơ chế chống lách cache & spam AI: Gateway bắt buộc **tự canonicalize** (xóa comment + chuẩn hóa khoảng trắng) và **tự tính `sha256`** ở phía server (không tin hash từ client), chặn cứng `422` khi bài nộp bị `CE`, và dùng `singleflight` / Redis lock chống bấm đồng thời trên 2 tab.
   - Cập nhật **ADR-06:** Bổ sung **Client-side WASM Syntax Checker (`web-tree-sitter`, hỗ trợ mở rộng language pack `.wasm`: C++, Python) + Client Formatter** trước khi submit, nhưng vẫn **loại bỏ Backend Full LSP (`clangd`/`pyright` qua WebSocket)** để giữ nhẹ hạ tầng và tránh lỗ hổng bảo mật `#include`.
   - Bổ sung **ADR-07:** Phân pha tiến hóa AI Service 2 vòng lặp **P0 → P1 (Machine Loop) → P2 (Human Loop)** theo Issue #15–#19, bảo toàn hợp đồng P0 Tuần 12–13.
2. **`project-brief.md`:** Kế thừa bản gọn từ PR #27 của Sơn, cập nhật bảng MVP/UC cho luồng WASM Syntax Gate + Formatter + Server Canonical Hash và bổ sung Mục 7 (Lộ trình mở rộng AI P0 → P1 → P2).
3. **`design.md`:** Cập nhật sơ đồ kiến trúc SOA, Sequence Diagram (Pha B có bước kiểm tra cú pháp WASM + format phía Client và Canonicalizer/Lock/CE-Gate phía Gateway) và điểm mở rộng P1/P2.
4. **`backlog-and-plan.md`:** Cập nhật Risk Register & phân công Tuần 13–15 cho WASM Syntax/Formatter (Sơn), Canonicalizer + `singleflight` + `CE` Gate (Khánh) và mốc tùy chọn P1/P2 (Long).
5. **`progress-report-w12.md` & `evidence/swagger-ui-w12.png`:** Phần báo cáo & minh chứng Swagger UI của Nam cho Tuần 12.
