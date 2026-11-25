# BÁO CÁO CÔNG VIỆC CỦA LONG

**Dự án:** AlgoBloom

**Người phụ trách:** Long — `@LongSei`

**Ngày báo cáo:** 24/11/2026

**Phiên bản:** 0.2 — Dự thảo

**Phạm vi:** Dịch vụ AI, kiểm chứng bài lập trình và học thích ứng

**Trạng thái tài liệu:** Bản nháp để xem xét trong PR

Bản tiếng Việt vận dụng cách diễn đạt đơn giản và thuật ngữ nhất quán của ASD-STE100. Bản này không tuyên bố tuân thủ đầy đủ tiêu chuẩn dành cho tiếng Anh.

## 1. Mục tiêu và tình trạng

Long phụ trách dịch vụ AI của AlgoBloom.

Mục tiêu trước mắt là triển khai chức năng sinh bài và phân tích mã nguồn. Mục tiêu tiếp theo là xây dựng quy trình sinh bài có kiểm chứng. Dữ liệu người học sẽ hỗ trợ hiệu chuẩn độ khó và gợi ý bài ở pha sau.

Roadmap hiện có gồm:

| Pha | Phạm vi | Issue |
|---|---|---|
| P0 | Kiểm chứng API, nền tảng dịch vụ và hai chức năng AI | #3, #11, #12 |
| P1 | Điều phối sinh và sửa bài; kiểm chứng; độ phủ; kiểm thử đối kháng | #16, #17 |
| P2 | Phản hồi người học, hiệu chuẩn độ khó và gợi ý bài | #18, #19 |
| Nghiên cứu | Đánh giá độc lập, so sánh phương pháp và nghiên cứu với người tham gia | #21 |

Epic #15 theo dõi toàn bộ roadmap.

Tại lần kiểm tra GitHub ngày 24/11/2026, các issue trên đều ở trạng thái **Open / Todo**. Kế hoạch đã được cập nhật. Chưa có đủ bằng chứng để xác nhận hoàn thành triển khai.

Các điều chỉnh kiến trúc trong báo cáo này là **đề xuất để xem xét**. Việc đăng báo cáo không tự bổ sung các đề xuất vào DoD của issue và không mở rộng điều kiện hoàn thành P0.

## 2. Cơ sở thiết kế

Khung tham khảo sử dụng năm bước: diễn giải yêu cầu, đối sánh, lắp ghép, tìm kiếm và kiểm chứng.

AlgoBloom đề xuất áp dụng cách phân chia này cho bài lập trình. Đối tượng cần bảo toàn là yêu cầu của giáo viên và đặc tả bài.

| Bước | Cách áp dụng cho AlgoBloom | Đầu ra |
|---|---|---|
| 1. Chuẩn hóa yêu cầu | Đọc tag, độ khó mục tiêu, kỹ năng và giới hạn do giáo viên chọn. | Bản yêu cầu có cấu trúc. |
| 2. Đối sánh | Tìm thành phần và bài đã kiểm chứng có thể tái sử dụng. Kiểm tra nguy cơ trùng bài. | Danh sách thành phần phù hợp và điều kiện sử dụng. |
| 3. Tạo bộ bài | Tạo đề, lời giải tham chiếu và bộ kiểm thử. Gắn từng phần với bản yêu cầu. | Một phiên bản bài cùng bản đặc tả kiểm chứng. |
| 4. Sinh và sửa có giới hạn | Tạo phương án sửa dựa trên lỗi và kết quả đo. Giữ nguyên các yêu cầu đã chốt. | Phiên bản ứng viên mới và lịch sử thay đổi. |
| 5. Kiểm chứng và duyệt | Kiểm tra ứng viên bằng nguồn đối chiếu độc lập. Chuyển bài đạt điều kiện cho người duyệt. | Quyết định đạt, loại bỏ hoặc cần xem xét. |

Khung này định hướng việc tổ chức hệ thống. Nó không chuyển các chứng minh toán học của tài liệu tham khảo sang AlgoBloom.

Kiểm thử phần mềm chỉ cung cấp bằng chứng trong phạm vi đã kiểm tra. Báo cáo không gọi kết quả đó là chứng minh đúng cho mọi đầu vào.

## 3. Đặc tả cần bảo toàn

### 3.1. Bản yêu cầu

Bản yêu cầu ghi rõ điều giáo viên muốn hệ thống tạo.

Nội dung đề xuất gồm:

- Kỹ năng và thuật toán mục tiêu.
- Độ khó mục tiêu.
- Dạng bài và cấu trúc dữ liệu.
- Giới hạn đầu vào.
- Giới hạn thời gian và bộ nhớ.
- Điều kiện bắt buộc và điều kiện tùy chọn.
- Những điểm còn thiếu hoặc mâu thuẫn.

Hệ thống phải báo yêu cầu chưa được hỗ trợ. Hệ thống không được tự bỏ yêu cầu đó.

Độ khó mục tiêu là giá trị định hướng. Độ khó thực nghiệm phải được ước lượng sau khi có dữ liệu người học phù hợp.

### 3.2. Bản đặc tả kiểm chứng

Mỗi phiên bản bài cần có bản đặc tả để đối chiếu.

Bản đặc tả đề xuất ghi:

| Nhóm | Nội dung cần xác định |
|---|---|
| Đầu vào | Miền giá trị, cấu trúc và điều kiện hợp lệ. |
| Đầu ra | Quan hệ giữa đầu vào và kết quả; cách chấp nhận nhiều đáp án nếu có. |
| Yêu cầu thuật toán | Kỹ thuật mục tiêu và bằng chứng dùng để đánh giá. |
| Tài nguyên | Giới hạn thời gian, bộ nhớ và môi trường đo. |
| Kiểm chứng | Nguồn đối chiếu, bộ kiểm thử, phiên bản và kết quả. |
| Truy vết | Phiên bản bài, nguồn tạo, lần sửa và quyết định duyệt. |

Bản đặc tả phải được đối chiếu với yêu cầu ban đầu. Một bản đặc tả sai có thể khiến hệ thống kiểm tra đúng một bài không đúng ý giáo viên.

### 3.3. Quy tắc sửa bài

Trong cùng một yêu cầu đã chốt, tác nhân sửa bài không được:

- Giảm giới hạn đầu vào chỉ để tránh lỗi thời gian chạy.
- Bỏ kiểm thử đang phát hiện lỗi.
- Đổi kết quả mong đợi để khớp lời giải sai.
- Nới điều kiện đầu ra để tăng tỷ lệ vượt kiểm thử.
- Đổi kỹ năng mục tiêu mà không ghi nhận thay đổi yêu cầu.

Nếu cần thay đổi yêu cầu, hệ thống phải tạo bản yêu cầu mới. Phiên bản bài mới phải được kiểm chứng và duyệt lại.

## 4. Công việc của Long theo từng pha

### 4.1. P0 — Triển khai dịch vụ AI

**#3 — Kiểm chứng API và chọn công nghệ**

Long cần kiểm chứng model thực tế bằng hai luồng: sinh bài và phân tích độ phức tạp.

Kết quả bàn giao gồm mẫu phản hồi thật, cấu hình model, hạn mức quan sát được và quyết định công nghệ. Thông tin bí mật không được đưa vào mã nguồn hoặc báo cáo.

**#11 — Xây dựng nền tảng dịch vụ**

Long cần triển khai:

- Kiểm tra tình trạng hoạt động.
- Xác thực yêu cầu nội bộ.
- Chế độ giả lập không gọi Internet.
- Cơ chế thử lại có giới hạn.
- Docker và kiểm thử nền tảng.

**#12 — Triển khai chức năng**

Long cần triển khai API sinh bài và API phân tích mã nguồn.

Đầu ra phải đúng schema. Phản hồi lỗi phải rõ ràng. Gợi ý Socratic phải hỗ trợ người học mà không cung cấp toàn bộ lời giải.

**Điều kiện hoàn thành P0:** Có mã triển khai, kết quả kiểm thử và bằng chứng tích hợp theo DoD hiện hành.

Khung năm bước không yêu cầu hoàn thành kho thành phần, cơ chế tìm kiếm hoặc hiệu chuẩn ngay trong P0.

### 4.2. P1 — Bảo toàn yêu cầu trong vòng lặp máy

**#16 — Điều phối và sửa bài**

Long triển khai logic:

**Sinh bài → Tạo lời giải → Tạo bộ kiểm thử → Kiểm chứng → Sửa bài.**

Vòng lặp phải có giới hạn số lần sửa, thời gian và chi phí. Mỗi lần sửa phải gắn với lỗi cụ thể.

Gateway lưu trạng thái và lịch sử. Kết quả đến trùng hoặc đến muộn không được tạo thêm lần sửa ngoài ý muốn.

Bài phải được kiểm chứng bằng nguồn đối chiếu phù hợp. Ví dụ gồm phép vét cạn trên miền nhỏ hoặc lời giải được xây dựng độc lập.

Thiếu bằng chứng phải được ghi là chưa xác minh. Hệ thống không được chuyển trạng thái này thành đã đạt.

**#17 — Độ phủ và kiểm thử đối kháng**

Long triển khai cách đo độ phủ theo cấu trúc thuật toán. Tag chỉ là một phần của phép đo.

Bộ kiểm thử phải được đánh giá bằng lời giải sai có chủ đích. Một tập lời giải sai riêng phải được giữ lại cho đánh giá cuối.

Kết quả cần báo cả hai loại lỗi:

- Lời giải sai vẫn được chấp nhận.
- Lời giải đúng bị loại.

**Đề xuất điều chỉnh từ cơ sở tham khảo**

Kho tái sử dụng có thể lưu mẫu cấu trúc bài, bộ sinh dữ liệu, nguồn đối chiếu và kết quả kiểm chứng.

Mỗi mục phải có phiên bản, điều kiện áp dụng và nguồn gốc. Một ứng viên chưa đạt không được trở thành mẫu tin cậy.

Khi tái sử dụng, hệ thống phải kiểm tra lại điều kiện áp dụng. Việc đã đạt ở bài trước không bảo đảm đạt ở bài mới.

Phạm vi kho này cần được chốt trước khi đưa vào DoD của #16 hoặc #17.

### 4.3. P2 — Học từ dữ liệu sau xuất bản

**#18 — Hiệu chuẩn độ khó**

Long xây dựng phương pháp ước lượng độ khó từ dữ liệu người học.

Đầu ra phải có mức bất định, số mẫu và trạng thái chất lượng dữ liệu. Hệ thống cần xét năng lực người học, số lần thử và việc sử dụng gợi ý.

Khi thiếu dữ liệu, hệ thống giữ đánh giá ban đầu hoặc đánh giá của giáo viên.

**#19 — Gợi ý bài thích ứng**

Long xây dựng chính sách gợi ý dựa trên hồ sơ kỹ năng và kết quả hiệu chuẩn.

Chính sách phải có phiên bản, lý do gợi ý và phương án khi thiếu dữ liệu. Bài được gợi ý phải đã được duyệt và xuất bản.

Dữ liệu vận hành và dữ liệu học tập có mục đích khác nhau:

| Dữ liệu | Mục đích |
|---|---|
| Lỗi kiểm chứng, thời gian chạy, chi phí và chất lượng kiểm thử | Chọn phương án sinh hoặc sửa bài. |
| Kết quả làm bài và phản hồi người học | Hiệu chuẩn độ khó và điều chỉnh gợi ý. |

Phương án sinh nhanh hơn không mặc nhiên tạo bài tốt hơn cho người học.

## 5. Kiểm chứng, duyệt và xuất bản

Quy trình đề xuất gồm bốn cổng:

| Cổng | Kiểm tra | Khi chưa đạt |
|---|---|---|
| Cấu trúc | Schema, trường bắt buộc và tính hợp lệ của dữ liệu. | Trả lỗi hoặc yêu cầu sửa. |
| Yêu cầu | Nội dung bài có phù hợp yêu cầu đã chốt hay không. | Sửa bài hoặc yêu cầu làm rõ. |
| Thực thi | Kết quả đối chiếu, kiểm thử và giới hạn tài nguyên. | Sửa, loại bỏ hoặc chuyển xem xét. |
| Phê duyệt | Người có thẩm quyền duyệt đúng phiên bản bài. | Giữ trạng thái chưa xuất bản. |

Điểm chất lượng chỉ được dùng để so sánh sau khi ứng viên vượt các điều kiện bắt buộc tương ứng.

Điểm cao không được bù cho lỗi đúng đắn hoặc vi phạm yêu cầu.

Duyệt trước xuất bản thuộc quy trình phát hành. Phản hồi sau xuất bản thuộc quy trình hiệu chuẩn. Hai hoạt động này không thay thế nhau.

## 6. Kế hoạch đánh giá nghiên cứu

Issue #21 theo dõi đánh giá riêng.

Để kiểm tra giá trị của kiến trúc đề xuất, bộ so sánh cần có:

1. Sinh toàn bộ bài bằng một lần gọi model.
2. Sinh, nhận xét và sửa với ngân sách tương đương.
3. Sinh bài theo yêu cầu có cấu trúc.
4. Bổ sung kho tái sử dụng đã kiểm tra.
5. Bổ sung vòng sửa có kiểm chứng.
6. Bổ sung dữ liệu hiệu chuẩn của con người.

Các thí nghiệm cần giữ điều kiện so sánh phù hợp. Điều kiện gồm model, dữ liệu, số lần gọi và ngân sách.

Chỉ số đề xuất gồm:

- Mức đáp ứng yêu cầu ban đầu.
- Số lỗi bị bỏ sót và số bài đúng bị loại.
- Khả năng phát hiện lời giải sai trên tập đánh giá riêng.
- Độ phủ và mức trùng cấu trúc.
- Thời gian, chi phí và số vòng sửa.
- Sai số hiệu chuẩn độ khó và mức bất định.

Số liệu trong tài liệu tham khảo không phải số liệu của AlgoBloom. Mọi kết quả của AlgoBloom phải được đo riêng.

Chưa đặt mục tiêu triển khai chứng minh hình thức như một điều kiện của MVP. Nếu bổ sung hướng này, nhóm phải xác định đối tượng chứng minh, giả định và phạm vi bảo đảm.

## 7. Trách nhiệm và bằng chứng tiến độ

| Thành viên | Trách nhiệm chính |
|---|---|
| Long | Logic AI; yêu cầu và schema; sinh và sửa bài; chất lượng; hiệu chuẩn; chính sách thích ứng; đánh giá. |
| Khánh | Gateway; dữ liệu; trạng thái; chống xử lý trùng; phân quyền và lưu quyết định duyệt. |
| Nam | Môi trường chạy cô lập; thực thi mã; kết quả kiểm chứng và kiểm thử đối kháng. |
| Sơn | Giao diện yêu cầu, duyệt bài, phản hồi và gợi ý bài. |

Bằng chứng đã kiểm tra tại mốc báo cáo:

- Nhánh chính tại [`9de57f3`](https://github.com/thep1ckaxe91/AlgoBloom/commit/9de57f3b3c7cd71db241d4754d153ab9a7142852) có README, cấu hình mẫu và bốn JSON Schema của dịch vụ AI.
- Thư mục AI trên nhánh chính chưa có mã chạy dịch vụ, Dockerfile hoặc kiểm thử.
- [PR #20](https://github.com/thep1ckaxe91/AlgoBloom/pull/20) cập nhật tài liệu roadmap. PR chưa được hợp nhất tại mốc kiểm tra dùng cho bản nháp.
- Các issue đã được cập nhật kế hoạch. Research Evaluation đã được tách sang #21.

Các bằng chứng này xác nhận tiến độ tài liệu và tổ chức công việc. Chúng chưa xác nhận hoàn thành tính năng.

Bước tiếp theo là hoàn tất #3, sau đó triển khai #11 và #12. Nhóm cần xem xét khung yêu cầu và kiểm chứng trong bản nháp trước khi đưa các điều chỉnh mới vào P1.

## 8. Quản lý tài liệu tham khảo

Báo cáo điều chỉnh cơ sở thiết kế tham khảo theo bài toán AlgoBloom. Báo cáo không kèm tài liệu nguồn chưa được phép công bố.

Không đưa PDF nguồn, nội dung trích xuất, hình hoặc bảng của tài liệu nguồn vào repository hay GitHub.

Báo cáo không sử dụng kết quả của tài liệu nguồn để đại diện cho kết quả dự án. Thông tin dẫn nguồn chi tiết cần được xem xét riêng trước khi bổ sung công khai.

## 9. Liên kết theo dõi

- [Epic #15](https://github.com/thep1ckaxe91/AlgoBloom/issues/15).
- [#3 — Kiểm chứng API và chọn công nghệ](https://github.com/thep1ckaxe91/AlgoBloom/issues/3).
- [#11 — Nền tảng AI Service](https://github.com/thep1ckaxe91/AlgoBloom/issues/11).
- [#12 — Chức năng AI và tích hợp](https://github.com/thep1ckaxe91/AlgoBloom/issues/12).
- [#16 — Điều phối và sửa bài](https://github.com/thep1ckaxe91/AlgoBloom/issues/16).
- [#17 — Độ phủ và kiểm thử đối kháng](https://github.com/thep1ckaxe91/AlgoBloom/issues/17).
- [#18 — Hiệu chuẩn độ khó](https://github.com/thep1ckaxe91/AlgoBloom/issues/18).
- [#19 — Gợi ý bài thích ứng](https://github.com/thep1ckaxe91/AlgoBloom/issues/19).
- [#21 — Đánh giá nghiên cứu](https://github.com/thep1ckaxe91/AlgoBloom/issues/21).
