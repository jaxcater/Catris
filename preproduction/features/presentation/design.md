# Trình diễn: mèo, gió, âm thanh và xúc giác

**Status:** designed

Các giá trị là `[ASSUMPTION]` để tune bằng clip và iPhone; không phải số đo từ engine nguồn. So sánh với [chuỗi tham chiếu](../../REFERENCE_ANALYSIS.md), đồng thời giữ logic ở [packing](../packing/design.md) độc lập.

## Animation contract

| Trạng thái | Khởi điểm để tune | Kết quả cần nhìn thấy |
|---|---|---|
| Breath | Chu kỳ 3,5–5,5 s, nở 0,8–1,8% ở ngực/bụng | Nhẹ, không rung chân tiếp xúc |
| Blink | Khoảng nghỉ 3–7 s, blink 100–160 ms | Seed riêng; không chớp đồng thời cả bàn |
| Eye look | Mục tiêu đổi sau 2–5 s | Mắt không xuyên mặt, không nhìn đảo liên tục |
| Ear/tail idle | Cử động hiếm sau 5–12 s | Mèo có cá tính, bàn vẫn yên |
| Pickup | 100–150 ms; nâng 0,025–0,04 m | Thân được nhấc, bóng tách và mềm hơn |
| Drag | Root theo tay nhanh; secondary lag 40–90 ms | Không làm input nặng hoặc luôn đuổi theo ngón tay |
| Rotate | 150–220 ms | Quay đúng 90°, có follow-through nhưng không đổi footprint |
| Valid drop | Squash 4–7%, settle 180–320 ms | Giữ thể tích tương đối; không nảy như bóng cao su |
| Invalid return | 180–260 ms, một recoil nhỏ | Không giật mạnh hay hiệu ứng báo động |
| Solve | Một phản ứng 0,8–1,4 s | Vui nhỏ, không khóa thao tác nhiều giây |
| Pet/purr | 0,6–1,2 s | Khác nhau theo mèo; cooldown tránh spam |

Một ô world quy ước 0,25 m trong asset brief; 1 Unity unit = 1 m. Giới hạn deform theo biên độ art direction; không để tai/đuôi chui qua con bên cạnh một cách rõ rệt. Các chi tiết mềm có thể vượt mép ô một chút về thị giác nhưng không làm hit area và rule khó hiểu.

## Quyền sở hữu chuyển động

- Logic giữ transform đích và placement, không đọc mesh deform.
- Một controller sở hữu visual root. Animator hoặc spring additive sở hữu từng bone/layer được phân công, tránh hai hệ thống ghi cùng bone trong một frame.
- Dùng spring có damping và giới hạn dt/substep; so sánh ở 30/60 fps. Khi resume sau nền, reset/taper velocity, không dùng dt dài làm mèo bắn ra ngoài.
- Rig Generic cho mèo; clip keyframe cho hành động có chủ ý; procedural cho blink timing, gaze và secondary lag. Bake constraint vào animation export.
- Render, depth, shadow và outline pass dùng cùng deformation khi shader/bone thay đổi silhouette. Bounds phải bao được pose xa nhất để tránh bị cull.
- Reduce Motion giảm squash, sway và particle; vẫn có highlight/snap đủ rõ. Không tắt feedback thiết yếu.

## Wind contract

Một `WindProfile` per map mô tả hướng, cường độ nền và gust chậm. Không suy các giá trị này từ metadata video.

- Chu kỳ nền thử 5–9 s; gust 12–25 s, blend trơn. Lá đầu cành có pha nhanh nhỏ, thân/cành phản ứng chậm.
- Rèm: đỉnh neo cố định, biên độ cuối vải khoảng 1–3% chiều cao rèm; vẫn có nếp gấp và trọng lượng, không là tấm phẳng lắc cứng.
- Cây: thân gần như đứng; lá/cành có độ cứng khác nhau. Dùng phase theo vị trí world cộng variation per-instance.
- Bụi: 8–20 hạt nhìn thấy trong map phòng tại một thời điểm, không phải rate mỗi giây. Hạt trôi chậm và fade mềm ngoài vùng tương tác.
- Map mưa: giọt và vệt ở lớp kính bên ngoài, không particle mưa xuyên vào bàn; gió ngoài cửa có thể mạnh hơn nhưng mèo không bị rung theo.
- Âm thanh wind/chime phản ứng cùng envelope gust, có cooldown. Không phát một tiếng chuông mỗi nhịp sin.

## Lighting feedback

Contact shadow theo chiều cao nhấc: lúc nghỉ sát và rõ; lúc nâng rộng/mềm và nhạt hơn. Tránh blob shadow cộng với dynamic shadow thành hai bóng tách biệt. Shadow bias tune trên scale board thực; không để mèo trông lơ lửng.

Outline selected trắng kem, thử 1,5–2,5 pixel hiển thị, chuyển vào/ra 80–120 ms. Ảnh reference có sọc đỏ/đen; Catris thử rose tối + pattern mảnh thay đỏ chớp, giữ tín hiệu invalid bằng hình và âm ngắn.

Grid có thể tăng alpha khi kéo; không che mặt mèo. Valid preview nằm trên plane board dưới mèo; không có z-fighting. Trạng thái hợp lệ vẫn đọc được trong map đêm.

## Audio brief

Audio ở đây là đề xuất, chưa được xác nhận bằng nghe track gốc.

| Nhóm | Cần chuẩn bị | Quy tắc phát |
|---|---|---|
| Music | Hai loop 90–150 s, acoustic/ambient thưa, khoảng 65–80 BPM nếu có nhịp | Crossfade 2–4 s; tránh giai điệu dày, không ép nhạc theo từng placement |
| Ambience | Năm loop nền 45–90 s, mỗi map có signature | Loop không click; layer tránh nhận ra chu kỳ lặp |
| Foley | Cloth lift, soft set-down, wood/rug touch, rotate swish; 3–5 variation/event | Random không lặp ngay; pitch ±3% nếu chất lượng cho phép |
| Cats | Ít nhất ba family meow/chirp/purr, 3 variation/family | Tối đa hai voice mèo đồng thời; meow cooldown 8–15 s per cat |
| UI/solve | Click dịu, hint, undo, solve flourish | Không còi báo lỗi; không phát khi preview đổi mỗi frame |

Nguồn lưu WAV 48 kHz/24-bit; lựa chọn import PCM/ADPCM/compressed/streaming dựa trên độ dài và memory thực. Texture/video tham chiếu không phải nguồn âm thanh được phép ship.

Mixer: Master → Music / Ambience / Foley / Cats / UI. Điểm khởi đầu nghe thử: Music −18 dB, Ambience −14 dB, Foley −8 dB, Cats −10 dB, UI −14 dB so với bus gain trung tính; còn phụ thuộc loudness file nguồn. Cân bằng bằng tai trên loa iPhone/tai nghe, không đồng nhất dB bus với loudness đo. Giữ headroom, không clipping; check loop/crossfade và tiếng click khi pause/resume.

## Haptic và lifecycle

Pickup một tick nhẹ, valid snap một pulse ngắn, solve một cặp pulse nhẹ; invalid ưu tiên visual và soft foley. Toggle riêng, không haptic trên từng ô preview. Kiểm tra hỗ trợ thiết bị; unsupported phải im lặng an toàn.

Audio interruption, tai nghe/Bluetooth thay đổi, silent preference của game và background/resume đều được thử. Không restart nhiều ambience layer sau resume. Settings giữ qua lần mở tiếp theo.

**History:** 2026-11-22 — thiết kế đề xuất; chưa có animation, audio hoặc haptic build để kiểm tra.
