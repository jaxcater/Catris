# Catris — Game Design

**Status:** preproduction · **Ngày:** 22/11/2026 · Chưa có gameplay implementation.

Catris là game packing mèo 3D trên iPhone dọc: nhấc, xoay và đặt những con mèo mềm vào một tấm thảm; hoàn thành những puzzle ngắn trong năm không gian thư giãn. Đối tượng là người thích spatial puzzle nhẹ, mèo và cảm giác tương tác dễ chịu.

## Trụ cột

- Thấy muốn chạm: silhouette hữu cơ, gương mặt rõ, vật liệu mềm, chuyển động có trọng lượng nhẹ.
- Một ngón tay cũng chơi được: preview đúng, không bị ngón tay che ô đích, undo và hint luôn sẵn.
- Không gian đáng ở lại: ánh sáng, gió, âm thanh và chuyển động môi trường có chủ đích.
- Thư giãn có chiều sâu: suy nghĩ về khoảng trống và thứ tự đặt; không có countdown hoặc mất mạng.

## Vòng chơi

Chọn không gian → chọn board → thử placement/xoay → phản hồi mềm và rõ → sửa bằng kéo lại hoặc undo → giải xong → mèo thư giãn, một chi tiết nhỏ của map được mở → chơi tiếp hoặc ngắm cảnh. Save giữ board dở dang và trang trí; không cần tài khoản.

## Phạm vi đề xuất

`[ASSUMPTION]` Unity 6.3 LTS + URP/C#, Blender; iOS 17+, iPhone 12 trở lên. Tối đa năm map là yêu cầu người dùng. Đề xuất 12 board/map, 60 board; slice đầu gồm M01, năm mèo và ba board. Số board và device floor là quyết định thiết kế có thể sửa, không phải dữ liệu của clip.

## Feature index

| Feature | Status | Design |
|---|---|---|
| Packing, touch dọc, hint, undo, save state | designed | [packing](features/packing/design.md) |
| Mèo mềm, môi trường, audio và haptic | designed | [presentation](features/presentation/design.md) |
| Bộ năm map và 60 board | idea | [brief map](MAPS.md) |
| Trang trí nhẹ theo tiến độ | idea | Sau mỗi bốn board mới hoàn thành trong cùng map, thêm một chi tiết trang trí; không ảnh hưởng lời giải |
| Build iOS và IPA unsigned | idea | [kế hoạch build](IOS_UNSIGNED_IPA.md) |

## Decisions

| ID | Ngày | Quyết định | Phương án cân nhắc | Lý do | Ảnh hưởng |
|---|---|---|---|---|---|
| D-001 | 2026-11-22 | 3D runtime, mesh authored | SpriteKit procedural / web wrapper | Yêu cầu trực tiếp về 3D và không ghép hình thô | Toàn bộ hình ảnh |
| D-002 | 2026-11-22 | Đề xuất Unity URP | Godot Mobile / native RealityKit | Pipeline mesh/rig, mobile rendering và Xcode phù hợp; chưa có engine cần giữ trong repo | Kỹ thuật và skill |
| D-003 | 2026-11-22 | Packing tự do, không khối rơi | Tetris real-time | Kéo/xoay/đặt thấy trong video, mục tiêu thư giãn | [packing](features/packing/design.md) |
| D-004 | 2026-11-22 | Một map slice trước; tối đa năm map | Xây đồng loạt | Kiểm tra chất lượng và chi phí trên iPhone trước khi nhân rộng | Nội dung |
| D-005 | 2026-11-22 | Bộ chuẩn bị có chế độ riêng | Tự khởi tạo project | Người dùng nói chưa bắt đầu làm | Toàn bộ phiên hiện tại |

## Change log

- 2026-11-22: lập brief từ yêu cầu, kiểm tra repository và video; chưa có kết quả playtest hoặc build.
