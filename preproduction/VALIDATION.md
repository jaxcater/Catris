# Kiểm tra bộ chuẩn bị

**Phạm vi:** kiểm tra tài liệu, skill, nguồn tải và tính toàn vẹn của bộ chuẩn bị. Không phải báo cáo game/build iOS.

Ngày kiểm tra: 22/11/2026. Các báo cáo máy có thể đọc:

- [Skill validator](research/skill-validation.json): validator của skill-creator cho tám skill mới.
- [Pack validation](research/validation-report.json): map/asset schema, checksum, skill count, cú pháp helper và link tài liệu.
- [SHA-256 manifest](research/checksums.json): file trong bộ chuẩn bị; loại trừ chính manifest và báo cáo sinh lại.
- [Vendor lock](research/vendor-lock.json): nguồn GitHub, commit và blob SHA.

## Những kiểm tra thực hiện

- Metadata video, SHA-256 bản copy và 72 frame trích từ video; bốn contact sheet gắn thời gian đã được tạo. Đã xem các bảng ảnh, ảnh native resolution và chuỗi chuyển động để viết phân tích.
- Bảy tệp vật liệu đã đối chiếu byte length/MD5 do API Poly Haven cung cấp lúc tải, rồi lưu SHA-256 để kiểm tra lại. Đã xem texture gỗ nguồn; chúng vẫn chưa được duyệt làm material game.
- Tám skill Catris qua validator frontmatter/name/description. Đây là kiểm tra cấu trúc, không phải forward-test trong một engine.
- 110 file vendor được so với Git blob SHA đúng commit; giữ nội dung upstream và license. Helper được kiểm tra cú pháp Python bằng AST, không import/chạy Blender API.
- Manifest 48 hạng mục và năm map có ID/status nhất quán, không asset nào bị gán `runtime-approved` khi chưa có game.
- Link nội bộ và encoding Markdown được kiểm tra; game-docs checker kiểm tra hai feature trạng thái `designed`.

Kết quả cuối cùng và số lượng chính xác nằm trong `validation-report.json`; nếu file được sửa sau đó, chạy lại validator thay vì coi báo cáo cũ là bằng chứng mới.

## Chưa kiểm chứng và chưa thực hiện

- Chưa nghe/đánh giá soundtrack nguồn bằng tai; audio spec là đề xuất.
- Chưa có model/rig/animation/âm thanh Catris cuối; chưa có scene hay shader runtime.
- Chưa có Unity/Blender/Xcode/MCP hoạt động để chạy các workflow vendor. `create-ui` được loại khỏi tuyến mặc định vì version mismatch.
- Chưa có test gameplay, solvability của 60 board sản xuất, screenshot game, device test, profile thermal hoặc IPA. Không được đánh dấu các cổng G1–G6 đã đạt.
- Chưa mua asset, đẩy GitHub, kích hoạt Actions hoặc cài skill vào thư mục toàn cục.

## Chạy lại phần kiểm tra bộ chuẩn bị

Python 3.11+ là đủ cho helper kiểm tra pack; không cần Unity/Blender:

```text
python preproduction/scripts/validate_preparation.py
```

Muốn trích lại ảnh cần FFmpeg, và dùng `extract_reference.py --ffmpeg <path> --input <Game.mp4> --output <references>`. Script gắn nhãn contact sheet dùng PowerShell/System.Drawing trên Windows. Các helper không tạo game hoặc kích hoạt CI.
