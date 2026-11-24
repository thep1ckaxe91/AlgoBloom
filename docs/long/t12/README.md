# Bộ nháp T12 của Long

Ngày: 24/11/2026. Trạng thái: bản nháp trên nhánh T12, chờ review; chưa có runtime hoặc kết quả gọi model thật.

Bộ này chuẩn bị phần thiết kế và báo cáo của Long cho Design Review T12. Chưa triển khai runtime T13 và chưa gọi model thật.

| Tệp | Mục đích |
|---|---|
| [01-thiet-ke-ai.md](01-thiet-ke-ai.md) | Quyết định công nghệ, ranh giới SOA, hợp đồng và tình huống lỗi |
| [02-prompt-va-payload.md](02-prompt-va-payload.md) | Prompt nháp, mẫu request, quy trình kiểm chứng API thật |
| [03-demo-va-trinh-bay.md](03-demo-va-trinh-bay.md) | Kịch bản demo nhóm và phần trình bày AI của Long |
| [04-bao-cao-tien-do.md](04-bao-cao-tien-do.md) | Bản nháp báo cáo tiến độ ngắn để xem xét trước khi nộp |
| [05-checklist-nghiem-thu.md](05-checklist-nghiem-thu.md) | Việc ưu tiên, bằng chứng và các điểm cần chốt |
| `examples/*.request.json` | Mẫu input được soạn thủ công; không phải response từ model |

## Cách xem
Đọc thiết kế trước, rồi kiểm tra prompt và kịch bản demo. Chỉ thay trạng thái pending sau khi có output thực thi và người kiểm tra. Các tệp được cập nhật bằng commit riêng trên nhánh `docs/w12-long-ai-design`, trong [draft PR #23](https://github.com/thep1ckaxe91/AlgoBloom/pull/23). Không đổi schema hoặc OpenAPI trong bộ nháp này.

## Phạm vi
P0 gồm sinh bài, phân tích độ phức tạp/gợi ý, auth nội bộ, schema, bounded retry và mock có nhãn. P1/P2/nghiên cứu giữ làm hướng phát triển sau MVP. Không kèm paper, PDF yêu cầu, nội dung trích xuất, ảnh nguồn hoặc secret.
