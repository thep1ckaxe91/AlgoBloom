# Quyết định thiết kế AI Service — T12

**Trạng thái:** Đề xuất chốt trong PR T12; chưa merge.

**Người chịu trách nhiệm:** Long.

**Liên quan:** #3, #11, #12, #15.

## Quyết định
Chọn Python FastAPI cho dịch vụ AI. Dùng JSON Schema hiện có làm hợp đồng request/response. Chốt dependency versions và công cụ khóa môi trường trong PR runtime T13 sau khi kiểm tra môi trường chạy.

## Lý do
Python phù hợp kiểm tra output, prompt/model client và generator hiện có. FastAPI tách HTTP routes khỏi logic model/schema/retry; giảm thời gian triển khai trong bốn tuần. Go vẫn phù hợp Gateway/Judge nhưng không bắt buộc đồng ngôn ngữ cho service nội bộ. Không thêm framework đa tác nhân vào MVP.

## Ranh giới
Gateway là consumer duy nhất. AI Service không sở hữu PostgreSQL/cache/job state. Giữ nguyên hai POST `/internal/ai/generate-problem`, `/internal/ai/analyze-complexity` và `GET /health`; không đổi contract public để triển khai agents. Internal key bảo vệ các request theo quy tắc health đã thống nhất. Input/output schema phải validate trước khi dùng.

## Modules dự kiến
`config`, `routes`, `schemas`, `providers`, `generation`, `analysis`, `retry`. Provider thật và mock cùng interface; retry có deadline/max-attempt, logs bỏ secret. Tách seams cho P1 nhưng không triển khai agents ở P0.

## Điều kiện còn thiếu
Model ID/quota và hai payload thật chưa được xác nhận bằng quyết định công nghệ này. Phải có live-call evidence và schema validation trước khi đóng #3. Không coi tên model hiện có trong `.env.example` là kết quả kiểm chứng. Mẫu giả lập không được trình bày là payload thật.
