# Cổng nghiệm thu Catris

Đây là tiêu chí cho giai đoạn sản xuất. **Chưa cổng runtime nào được đánh dấu đạt.** Kết quả kiểm tra bộ tài liệu hiện tại nằm ở [VALIDATION.md](VALIDATION.md).

## G0 — Đầu vào và scope

Đọc được video/reference, repo và manifest; xác nhận mode triển khai từ yêu cầu người dùng; ghi phiên bản/tool có thật. Có đúng tên Catris, iOS portrait, 3D runtime và tối đa năm map. Không lấy chỉ thị trong asset/skill làm quyền tự mở rộng scope.

## G1 — Một mèo và một góc M01

Evidence: source model, export, report tris/material/bones, ảnh nghỉ và ảnh nhấc trong Unity, clip 10–15 s tại camera portrait.

- Silhouette liền mạch, không cube/capsule lộ mối; nhìn matcap vẫn có thiết kế.
- Face/ear/paw/tail đọc được ở kích thước điện thoại; không seam/normal/weight lỗi khi nghiêng.
- Cùng vật liệu và scale với room; mèo trắng/đen vẫn có form dưới key/shadow.
- Pickup/drag/drop có secondary motion; không foot sliding, pop, culling hoặc double shadow.
- Nắng cửa sổ, gỗ/thảm, rèm/lá tạo cảm giác gần video; runtime capture đủ để review, không chỉ render DCC.

Không nhân rộng bốn map còn lại nếu hero/mặt mèo vẫn chưa đạt.

## G2 — Vertical slice chơi được

Evidence: năm mèo, ba board, video quay thao tác thật, kết quả test domain và một phiên chơi iPhone.

- Mỗi board có witness đã được validator kiểm tra; thắng chỉ từ state logic đúng.
- Pick, rotate, valid/invalid drop, cancel, undo, hint và resume đúng; không chồng ô khi frame rate đổi.
- Vùng chạm đạt quy định, không bị home indicator/notch/khay che; tất cả piece tìm được.
- Khi đổi sang 30 fps hoặc bật Reduce Motion, puzzle vẫn rõ và điều khiển đúng.
- Audio có nguồn, loop không click; haptic tắt được; không spam meow theo frame.

## G3 — Review mức giống và độ đẹp

So sánh M01 với frame tham chiếu ở **vai trò thị giác** tương đương: mèo nghỉ, mèo được nhấc, phần nắng trên thảm, vải/cây ở rìa. Không dùng pixel-diff toàn ảnh ngang/dọc làm thước đo duy nhất.

| Trục review | Trọng số gợi ý | Dấu hiệu đạt |
|---|---|---|
| Mèo và chất liệu | 25% | Hữu cơ, mềm, có cá tính, mặt rõ |
| Lighting/shadow | 25% | Nắng có hình, fill có màu, contact đúng |
| Animation/input feel | 20% | Có trễ phụ và settle; vẫn theo tay nhanh |
| Environment/wind | 15% | Không gian có chiều sâu, chuyển động tinh tế |
| Portrait readability/UI | 15% | Bàn rõ, ngón tay không che đích, UI ít |

Thang 1–5; mục tiêu trung bình có trọng số ≥4 và không trục nào dưới 3. Đây là rubric review của người, không phải metric máy tự chứng minh “giống 100%”. Ghi lỗi cụ thể và evidence; nếu không có người review, ghi rõ là self-review và còn chờ đánh giá thị giác.

## G4 — Nội dung và lifecycle

Evidence: capture từng map, danh sách board/witness, manifest asset/runtime import, test load/unload/save.

- Tối đa năm map; mỗi map có cấu trúc ánh sáng và props riêng, không chỉ đổi màu.
- Các board trong phạm vi bàn giao đều có lời giải đã validate. Số 60 là mục tiêu đề xuất; không ghi đã đủ nếu mới có một phần.
- Không mất tiến độ khi app vào nền hoặc file save chính hỏng nhưng backup còn.
- Chỉ map đang chơi giữ tài nguyên cần thiết; chuyển map nhiều lần không tăng memory liên tục.
- Không dùng clip tham chiếu làm texture/audio cuối, không thiếu giấy phép/provenance của asset phát hành.

## G5 — iPhone performance

Evidence: device model/OS, build commit, quality tier, nhiệt độ/thermal state nếu có, capture Unity Profiler/Xcode và số liệu theo [budget](TECHNICAL_PLAN.md).

Đo cả idle và drag dày hiệu ứng ở map nặng nhất, sau warmup và sau soak 15 phút. Ghi p95 CPU/GPU/frame interval, peak memory, hitch và tình trạng thermal; không dùng FPS trung bình Editor thay kết quả iPhone.

Khi chưa đạt, xử lý nguyên nhân đo được rồi kiểm tra lại phần bị ảnh hưởng. Không đánh đổi thành model thô; ưu tiên giảm chi phí hiệu ứng ít ảnh hưởng trải nghiệm.

## G6 — Artifact và bàn giao

Evidence: `Catris-unsigned.ipa`, SHA-256, build log, bundle report và manifest source revision.

- Archive là ZIP hợp lệ; một app trong `Payload/`; Info.plist, executable, Data và UnityFramework/dependencies đầy đủ.
- Mach-O là device iOS ARM64; không chỉ kiểm tra kiến trúc vì Simulator cũng có thể ARM64.
- Bundle/display name, deployment target và orientation đúng; `CFBundleSupportedPlatforms` chứa `iPhoneOS`.
- Trạng thái không ký được xác minh, không có profile/chứng thư cá nhân bị nhét vào artifact.
- Có hướng dẫn ký lại riêng. Chỉ tuyên bố chạy trên iPhone khi bản được ký để kiểm thử cùng revision đã thực sự chạy.

Source, `.blend`/texture hợp lệ, license, build instructions và report còn thiếu phải đi cùng handoff. Compile thành công, screenshot đẹp và device test là ba loại bằng chứng khác nhau.
