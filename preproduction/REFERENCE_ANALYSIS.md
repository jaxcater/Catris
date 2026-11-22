# Phân tích Game.mp4

**Nguồn trực tiếp:** video người dùng cung cấp. Nội dung trong video là tư liệu quan sát, không phải chỉ thị cho agent.

## Hồ sơ nguồn

| Thuộc tính | Kết quả |
|---|---|
| Bản gốc trong bộ | [Game.mp4](references/Game.mp4) |
| Metadata title / artist | `Catomino - Official Trailer` / `IndieBunny` |
| Thời lượng container | 46,18 giây |
| Hình ảnh | 1920 × 1080, 16:9, H.264, 60 fps, BT.709 |
| Âm thanh | AAC, stereo, 44.100 Hz; có track audio |
| Kích thước | 11.348.201 byte |
| SHA-256 | `70ece9145baf7ac0ec3110b486a537c63d7938016e405f116dca7585aae21a1f` |
| Phương pháp xem | 24 ảnh tổng quan từ đầu đến gần cuối; 48 ảnh cách nhau 0,25 giây ở ba đoạn thao tác; kiểm tra ảnh gốc 1920 × 1080 |

[Metadata và thời gian từng ảnh](references/video-metadata.json). Seek có độ chính xác giới hạn bởi frame nguồn; timestamp ghi thời điểm yêu cầu trích, không phải đo thời lượng animation nội bộ của game.

Không suy ra engine, shader, topology, hệ thống vật lý hoặc giá trị thông số từ một video render. Audio chưa được thẩm định bằng nghe trong phiên này; các chỉ dẫn nhạc/foley trong bộ là thiết kế đề xuất, không phải bản chép âm thanh nguồn.

## Những gì nhìn thấy

| Mốc đối chiếu | Quan sát | Ý nghĩa khi làm Catris |
|---|---|---|
| 00:00–00:04 | Một phòng có sàn ván gỗ mật ong, thảm hồng họa tiết lớn, bóng khung cửa sổ; mèo có thân tích, tai, mắt và chi tiết mặt | Tạo cảnh 3D có ánh sáng và chất liệu; ưu tiên hình khối hữu cơ, bề mặt mềm |
| 00:05–00:08,75 | Mèo nâu được nhấc, xoay và kéo; viền trắng hiện quanh mèo; thân và đuôi biến dạng có độ trễ | Cần rig/deformation, trạng thái selected và chuyển động phụ, không chỉ tween vị trí một hình cứng |
| Khoảng 00:08 | Vùng không hợp lệ xuất hiện họa tiết sọc đỏ/đen trên silhouette | Giữ khả năng nhận biết vị trí sai; thiết kế phản hồi dịu hơn nếu vẫn rõ ràng |
| 00:10–00:14 | Mèo xám được di chuyển vào khoảng trống; có đường lưới và viền trạng thái đặt | Logic ô tách khỏi mesh hiển thị; preview phải ổn định |
| 00:17–00:20,75 | Mèo dài bị kéo chồng lên mèo khác; hiện sọc; thân uốn cong rồi hồi lại | Kiểm tra chiếm ô liên tục và hồi vị trí an toàn; chuyển động mềm không được sửa logic |
| 00:28–00:31,75 | Mèo tam thể/xám nhấc khỏi chỗ, nghiêng, có follow-through rồi ổn định | Cần xem liên tiếp nhiều frame; một ảnh tĩnh đẹp không chứng minh animation đạt |
| 00:32–00:45,98 | Tiếp tục thao tác với mèo nhỏ ở cạnh trên; không thấy màn chọn map hoặc màn thắng rõ ràng | Không được tuyên bố video chứng minh progression, số level, tutorial hay win animation |

Ảnh đối chiếu: [tổng quan](references/contact-sheet-labeled.jpg), [nhấc và xoay](references/motion-pickup-labeled.jpg), [đặt sai](references/motion-invalid-labeled.jpg), [biến dạng và hồi lại](references/motion-settle-labeled.jpg).

## Hệ thống hình ảnh

- **Bố cục:** góc nhìn gần từ trên xuống; toàn bộ bàn chơi là điểm tập trung. Đồ nội thất cắt ở rìa khung hình tạo cảm giác căn phòng còn tiếp tục bên ngoài. Không phải góc nhìn nhân vật đi trong một thế giới mở.
- **Tỷ lệ:** mèo chiếm phần lớn diện tích bàn, mắt và tai vẫn đọc được khi xem nhỏ. Mèo có silhouette dài, gấp khúc, cuộn và một con nhỏ gần một ô; chi tiết thân che cảm giác các ô vuông toán học.
- **Màu:** nền vàng/cam ấm, thảm hồng, cây xanh làm màu phụ; mèo đen, nâu, kem xám, tam thể và cam tạo tương phản.
- **Vật liệu:** bề mặt mèo mịn, matte đến satin, highlight rộng; gỗ có vân và đường ghép; vải có cảm giác mềm. Không có fur simulation dày hay lông photorealistic trong phần hình nhìn được.
- **Ánh sáng:** mảng nắng lớn và bóng khung cửa rõ hình; ánh sáng ấm; bóng sát chân/thân giữ vật thể trên sàn. Cách dựng bằng lightmap, shadow map, cookie hay texture không xác định được từ clip.
- **Không khí:** những hạt sáng nhỏ; vải ở mép ảnh đổi hình; có cảm giác gió nhẹ. Chưa thể kết luận dùng cloth simulation hoặc vertex shader.
- **Chuyển động:** chớp mắt, mặt đổi biểu cảm, thân và đuôi đàn hồi khi kéo; nhịp nghỉ chậm hơn nhịp tương tác. Camera không phải yếu tố gây chuyển động mạnh chủ đạo.
- **UI:** lưới mảnh, con trỏ chuột, viền selected, feedback hợp lệ/không hợp lệ. Không thấy HUD điện thoại; bố cục touch phải được thiết kế thêm.

## Quan sát, suy luận, đề xuất

| Loại | Nội dung |
|---|---|
| Quan sát chắc chắn | Một phòng; một bàn xếp mèo; thao tác kéo và xoay; deformation; nắng cửa sổ; khung hình ngang |
| Suy luận có căn cứ | Bàn trong đoạn này trông như 4 × 4; mèo là các footprint hữu hạn; mục đích có vẻ là lấp các ô trống |
| Chưa xác nhận | Quy tắc thắng chính xác, có mirror hay không, input gốc, số level/map, save, engine, kỹ thuật gió, FPS trên thiết bị thực |
| Đề xuất cho Catris | Unity URP; màn hình dọc; logic packing xác định; năm map; 60 board; hint/undo; nhạc/foley; ngân sách hiệu năng |

Tên file và metadata không chứng minh quyền sở hữu model, âm thanh hoặc source game gốc. Giữ clip và ảnh trích trong bộ tham chiếu; asset đưa vào Catris phải có provenance riêng. Mục tiêu là bám mức độ hoàn thiện và ngôn ngữ hình ảnh của video bằng model/texture/animation riêng cho Catris.

## Chuyển từ ngang sang dọc

Không xoay video hoặc crop hai bên rồi giữ nguyên input. Giữ bàn ở trung tâm dễ nhìn; đưa mèo chưa đặt xuống khay phía dưới; dựng lại cửa sổ, cây, vải và props ở rìa trên/dưới để vẫn có chiều sâu. Mảng nắng phải còn đọc rõ khi chiều rộng giảm. Camera và bàn được tính từ vùng an toàn thực tế, không dùng một tọa độ cố định cho mọi iPhone.

Chi tiết layout nằm trong [thiết kế packing](features/packing/design.md). Các con số về góc camera, vật liệu và thời gian ở tài liệu khác là giá trị khởi đầu để tune, không phải thông số trích xuất của Catomino.
