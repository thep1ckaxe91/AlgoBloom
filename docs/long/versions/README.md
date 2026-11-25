# Lộ trình bốn phiên bản của Long — T12 đến T15

**Mốc hiện tại:** T12. Còn bốn tuần bao gồm tuần này. Không gắn ngày deadline khi chưa có lịch học cụ thể.

| Mốc | Nhánh | Bàn giao bắt buộc |
|---|---|---|
| T12 | `docs/w12-long-ai-design` | Thiết kế, chốt công nghệ, API examples và evidence #3 |
| T13 | `feat/w13-long-ai-service` | Runtime P0 #11/#12, test cơ bản và tích hợp backend/DB thật |
| T14 | `feat/w14-long-ai-integration` | MVP hoàn chỉnh, integration/regression, môi trường demo tái hiện |
| T15 | `chore/w15-long-ai-quality-release` | Security/performance/lifecycle/quickstart và final evidence |

## Cách dùng nhánh
Các nhánh khởi tạo độc lập từ cùng `origin/main`, mỗi nhánh có kế hoạch riêng. Đây là nhánh chuẩn bị, chưa phải bốn bản phần mềm đã chạy. Sau mỗi mốc được review và merge, cập nhật nhánh kế tiếp bằng main mới trước khi triển khai. Không merge nhánh tương lai chỉ để ghi nhận kế hoạch là code hoàn thành. PR #22 là báo cáo tổng quan riêng, không là phụ thuộc bắt buộc.

## Phạm vi và ưu tiên
P0 là phần phải hoàn thành trong lịch nộp bài. MVP phải đạt ở T14; T15 dành cho chất lượng và bảo vệ. #16/#17 (P1), #18/#19 (P2) và #21 (research) có DoD riêng và tiếp tục post-MVP nếu thiếu thời gian. Giữ hướng thiết kế năm bước nhưng không triển khai toàn bộ nghiên cứu trong bốn tuần.

## Quy tắc bằng chứng
Mỗi báo cáo tuần có việc đã làm/chưa xong/hỗ trợ/kế hoạch/người phụ trách. Mọi kết luận hoàn thành cần commit/PR, code, API response hoặc test output tương ứng. Mock phải có nhãn; không thay DB thật ở T13 hoặc số liệu live-provider ở T15. Không commit secret, PDF nguồn, bản trích xuất hoặc ảnh từ tài liệu tham khảo. Các tệp báo cáo yêu cầu được đọc cục bộ; nhánh chỉ lưu kế hoạch được soạn cho AlgoBloom.
