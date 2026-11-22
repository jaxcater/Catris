# Packing và điều khiển dọc

**Status:** designed

Tất cả số bên dưới là `[ASSUMPTION]`/giá trị khởi đầu cho Catris. Quy tắc được đề xuất từ thao tác trong clip, không phải mô tả source game gốc.

## Board, piece và placement

- Board bắt đầu 4 × 4, tăng dần đến tối đa 6 × 6; mask cho phép board không hình chữ nhật ở mức khó hơn. UI vẫn dùng cùng nguyên tắc kích thước ô.
- Mỗi piece có `pieceId`, footprint là tập ô nguyên, `allowedRotations`, model/rig ID và pivot theo ô. Rotation quanh pháp tuyến board theo bội số 90°. Mặc định không mirror.
- Sau rotation, normalize các ô và cập nhật offset pivot; không suy logic từ bounding box mesh hoặc bone đã deform.
- Valid = mọi ô trong mask và không bị piece khác chiếm. Loại footprint cũ của piece đang kéo khỏi kiểm tra. Không dùng rigidbody collision làm occupancy.
- Commit nguyên tử khi thả hợp lệ; position visual được phép settle sau commit. Cancel/invalid trả về placement đã commit trước đó hoặc vị trí khay ban đầu.
- Win = phủ hết mask đúng một lần và đặt đủ piece bắt buộc. Kiểm tra diện tích footprint tổng bằng diện tích mask lúc validate dữ liệu.

## Năm dáng mèo đầu tiên

Các footprint sau là mẫu thiết kế dữ liệu cho asset, chưa phải file level của game. Có thể quay để khớp board. Tên shape chỉ dùng nội bộ; người chơi nhìn thấy mèo hữu cơ.

| Asset | Tính cách | Footprint chuẩn, gốc góc dưới trái |
|---|---|---|
| CAT-01 Nori | Mèo đen dài, bình thản | `(0,0),(0,1),(0,2),(0,3)` |
| CAT-02 Sumi | Mèo nâu cuộn chân, hơi ngái ngủ | `(0,0),(1,0),(0,1),(0,2)` |
| CAT-03 Pudding | Tam thể ôm đồ chơi, tò mò | `(1,0),(0,1),(1,1),(0,2)` |
| CAT-04 Mochi | Mèo kem xám cuộn mình | `(1,0),(0,1),(1,1)` |
| CAT-05 Miso | Mèo cam nhỏ, nhanh nhẹn | `(0,0)` |

Tổng diện tích 16 ô. Ví dụ bố trí có thể kiểm tra bằng tay, đọc hàng trên xuống dưới:

```text
N M H H
N S P H
N S P P
N S S P
```

`N=Nori, M=Miso, H=Mochi, S=Sumi, P=Pudding`. Đây là witness minh họa cho các footprint trên, không phải lời khẳng định đã trích file level từ video. Giữ file level sản xuất riêng khi triển khai.

## State và touch

Luồng: Idle → Pressed → Dragging → PreviewValid/PreviewInvalid → Commit hoặc Return → Idle. Solved và Paused là state riêng. Mỗi touch có owner; UI có ưu tiên khi bắt đầu chạm trong vùng nút.

- Pickup bắt đầu khi vượt khoảng cách kéo 5 pt; tap ngắn khi không kéo có thể pet hoặc chọn. Không vừa pet vừa rotate do chung tap.
- Offset hiển thị khi kéo: thử 48–64 pt phía trên ngón tay, clamp trong vùng chơi; phần ghost trên board biểu thị placement thật. Không để offset này làm lệch grid quantization.
- Rotate bằng nút 44 pt trở lên, truy cập khi giữ; tap chọn rồi bấm rotate cũng hoạt động. Touch thứ hai không tự chiếm piece khác trong cùng giao dịch kéo.
- Xoay giữ điểm bám, chỉ commit orientation khi thao tác hợp lệ. Nút đổi tay thuận chuyển cụm điều khiển, không đổi hướng board.
- Chạm sát rìa, kéo khỏi màn hình, mở pause/settings, vào nền hoặc mất focus đều có đường cancel xác định. Resume không tự thả con mèo vào vị trí ngón tay cũ.
- Mèo khay được thu nhỏ để đủ chỗ, nhưng khi pickup phải blend sang kích thước thế giới thật; không có jump scale hay thay đổi footprint.

## Layout thích ứng

Lấy safe rect trước, sau đó dành lề ngang 16 pt. Các vùng khởi đầu theo chiều cao safe rect: HUD 0–10%, khoảng thở/props 10–22%, board 22–70%, khay 72–91%, controls 92–100%. Đây là gợi ý composition; layout solver phải ưu tiên kích thước board và vùng chạm khi màn hình ngắn.

- Board rộng tối đa vùng safe width trừ hai lề và viền thảm; fit theo cả chiều cao còn lại. Không stretch các ô thành hình chữ nhật.
- Ô touch tương đương ít nhất 44 pt, mục tiêu 52 pt trở lên. Nếu không đủ thì giảm độ lớn board logic hoặc điều chỉnh khay/HUD; không thu nhỏ tới mức khó chơi.
- Khay có mini preview của đủ piece trong board; bố trí hai hàng hoặc chuyển trang rõ ràng. Không cất một piece bắt buộc ngoài khung mà thiếu chỉ báo.
- Kiểm tra logical viewport 320 × 568, 375 × 667, 390 × 844 và 430 × 932, cộng safe insets tương ứng. Đây là bộ kiểm tra layout, không đồng nghĩa hỗ trợ mọi model iPhone cũ.
- UI dùng font có dấu tiếng Việt, trạng thái không chỉ dựa vào màu; tùy chọn English nếu thêm localization.

## Hint, undo và replay

Hint theo ba cấp: chỉ một vùng có thể giải → cho silhouette/orientation một piece → cho phép đặt giúp. Solver tìm completion của state hiện tại trước. Nếu state không còn completion, chỉ piece nên di chuyển hoặc gợi ý undo; không đưa ghost bất khả thi.

Undo lưu giao dịch gồm piece, placement cũ/mới và orientation. Một drag dù phát nhiều preview chỉ tạo một undo entry. Không ghi các frame deformation. Undo không giới hạn; retry không tốn tài nguyên.

Board sản xuất là dữ liệu authored hoặc dữ liệu sinh đã được xác thực bằng solver. Mỗi board lưu solution witness, version và mức khó. Không cần duy nhất một lời giải trừ khi puzzle cụ thể yêu cầu.

## Nhịp tiến độ

Ba board tutorial; sau đó người chơi được chọn cả năm map. Mỗi map đề xuất 12 board: bốn dễ, năm vừa, ba thử thách nhẹ. Thời gian mong muốn mỗi board khoảng 30 giây–3 phút; điều chỉnh bằng playtest, không ép thành timer.

Hoàn thành lần đầu bốn board trong một map thêm một prop trang trí; không ghi nhận lặp vô hạn để farm. Board đã chơi có thể chơi lại. Không streak penalty, energy, gacha hoặc cửa chặn quảng cáo trong phạm vi mặc định.

## Save và nghiệm thu

Save local có `schemaVersion`, map/board ID, placements đã commit, progress, settings và đồ trang trí; ghi file tạm rồi replace/backup. Kiểm tra schema và legality khi load. Nếu file hỏng, thử backup và báo nhẹ; không crash hoặc xóa im lặng toàn bộ tiến độ.

Các kiểm tra bắt buộc khi có code: quay bốn lần trở lại footprint; rejection ngoài mask/chồng ô; self-occupancy; cancel; undo; hint từ state solvable/unsolvable; save/resume; interrupted drag; board solvability. Chưa đánh dấu test nào đã chạy ở giai đoạn chuẩn bị.

**History:** 2026-11-22 — thiết kế theo D-003, dữ liệu minh họa chưa triển khai.
