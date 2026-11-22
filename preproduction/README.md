# Catris — bộ chuẩn bị sản xuất

**Ngày:** 22/11/2026 · **Trạng thái:** CHỈ CHUẨN BỊ · **Game chưa được triển khai.**

Mở [CATRIS_MASTER_PROMPT.md](../CATRIS_MASTER_PROMPT.md) để lấy prompt đầy đủ. Giữ prompt cùng thư mục `preproduction/` khi chuyển sang máy hoặc agent khác.

## Có sẵn trong bộ này

- Phân tích video dài 46,18 giây; bản video gốc, 72 ảnh trích và bốn bảng ảnh có thời gian.
- Tám skill riêng cho Catris; 20 skill tải từ hai repository GitHub theo commit cố định, kèm tài liệu, helper và giấy phép. Một skill UI mới hơn engine mục tiêu được giữ làm tài liệu tham khảo, không nằm trong tuyến sử dụng mặc định.
- Art bible, thiết kế game, năm map tối đa, yêu cầu model/rig/animation, danh mục vật tư và prompt giao việc cho artist/công cụ.
- Bảy tệp vật liệu CC0 đã tải, có URL, tác giả, MD5 nguồn và SHA-256 bản lưu. Các tệp này là nguồn thô; chưa phải material được duyệt trong game.
- Kế hoạch Unity URP/iOS, quy trình dự kiến tạo IPA unsigned, tiêu chí kiểm tra đồ họa và hiệu năng.

## Đọc theo nhu cầu

| Tài liệu | Dùng để làm gì |
|---|---|
| [Phân tích video](REFERENCE_ANALYSIS.md) | Phân biệt quan sát, suy luận và phần đề xuất |
| [Bảng ảnh tổng quan](references/contact-sheet-labeled.jpg) | Xem toàn bộ clip theo mốc thời gian |
| [Art bible](ART_BIBLE.md) | Giữ đúng cảm giác đồ họa, ánh sáng và chất liệu |
| [Thiết kế game](GDD.md) | Core loop, phạm vi và quyết định thiết kế |
| [Năm map](MAPS.md) | Bối cảnh, props, gió, ánh sáng và âm thanh mỗi map |
| [Brief vật tư](ASSET_BRIEFS.md) | Đặt hàng/tạo model, texture, rig, animation, audio |
| [Manifest vật tư](assets/asset-manifest.json) | Biết thứ gì đã có và thứ gì cần sản xuất |
| [Skill và kết quả rà soát](SKILLS.md) | Đọc đúng skill theo từng công việc |
| [Kế hoạch kỹ thuật](TECHNICAL_PLAN.md) | Engine, import, rendering, giới hạn thiết bị |
| [IPA unsigned](IOS_UNSIGNED_IPA.md) | Handoff build cho repository của bạn |
| [Cổng nghiệm thu](QUALITY_GATES.md) | Không đánh đồng build thành công với game đẹp |
| [Nguồn đã tra cứu](SOURCES.md) | Kiểm tra lại tài liệu và giấy phép |
| [Kết quả kiểm tra bộ chuẩn bị](VALIDATION.md) | Các kiểm tra đã chạy và phần chưa thể chứng minh |

## Ranh giới của giai đoạn này

Chưa tạo Unity project, scene chơi được, model mèo, code gameplay, workflow Actions hoặc IPA. Chưa cài Unity/Blender/MCP, chưa chạy helper Blender tải từ GitHub, chưa mua asset và chưa đẩy file lên GitHub. Các helper đã chạy chỉ phục vụ trích video, tải vật liệu và kiểm tra tài liệu.

Thư mục làm việc hiện tại không phải Git checkout. Repository [jaxcater/Catris](https://github.com/jaxcater/Catris) đã được kiểm tra ở commit `d69e399a9d8830f7a21d54b9dc5c3d9346039ddf`: chỉ có README. Khi triển khai phải đọc lại remote trước khi chọn cách đưa source vào đó.

Các skill mới nằm ở `preproduction/skills/` để mang theo bộ tài liệu. Agent đọc trực tiếp đường dẫn trong prompt; chúng chưa được cài toàn cục hoặc tự động đưa vào `.agents/skills/`. Không cần cài cả catalog để dùng bộ này.

Để bắt đầu giai đoạn sau, gửi toàn bộ prompt cùng thư mục này và yêu cầu rõ **“BẮT ĐẦU TRIỂN KHAI CATRIS”**. Câu này là cách phân biệt giai đoạn chuẩn bị với giai đoạn làm game; chỉ đọc hoặc sửa prompt không phải lệnh bắt đầu.
