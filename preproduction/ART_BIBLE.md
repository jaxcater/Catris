# Catris — Art bible

**Mục tiêu:** chất lượng game hoạt hình 3D mềm, ấm và có sự sống như [video tham chiếu](REFERENCE_ANALYSIS.md), được dựng lại cho màn hình dọc. Các con số dưới đây là điểm xuất phát thiết kế, chưa được nghiệm thu trong engine.

## Hình khối và composition

Mèo có thân liền mạch với phần đầu, vai, bụng, chân và đuôi chuyển tiếp mềm. Polyomino là footprint bên dưới, không phải các cube hiển thị. Nếp gấp nhỏ, bất đối xứng nhẹ và mặt có biểu cảm giúp tránh vẻ đồ chơi nhựa vô hồn. Không cần lông từng sợi để có cảm giác mềm.

Camera orthographic là lựa chọn đầu tiên, thử elevation 78° so với mặt đất (12° lệch khỏi nhìn thẳng xuống). Tune bằng silhouette: thấy đủ độ dày thân và bóng, nhưng mắt/ô đích vẫn rõ. Không tuyên bố đây là góc camera đo từ clip. M01 là chuẩn visual cho mèo và material chung.

Giữ board chiếm trọng tâm, xung quanh có khoảng thở. Thảm không phải một rectangle màu phẳng: có mép bo, độ dày, hơi lún, đường may và họa tiết lớn thưa. Props chính có silhouette đọc được ở rìa; những chi tiết rất nhỏ nên vào texture thay vì hàng trăm mesh.

## Palette vai trò

| Vai trò | Màu khởi điểm | Cách dùng |
|---|---|---|
| Nắng | `#FFE4AA` | Highlight và ánh sáng, không nhuộm trắng cả cảnh |
| Gỗ mật ong | `#C88F58` | Sàn M01, có biến thiên ván/vân |
| Thảm rose | `#D98DA5` | Nền board M01, tương phản với mèo |
| Vải kem | `#F2E7D5` | Rèm, highlight vật liệu, UI dịu |
| Lá sage | `#78936C` | Màu phụ ngoại vi |
| Bóng nâu tím | `#59464F` | Vùng bóng còn màu, không đen tuyệt đối |
| Lông đen | `#24252B` | Chừa khoảng sáng để đọc form |
| UI tối | `#403E3A` | Chữ trên nền kem |

Đây là palette thiết kế bằng mắt, không phải phép đo màu tuyệt đối từ video BT.709. Khóa color management nguồn/import/runtime trước khi chỉnh màu. Màu hex là sRGB; dữ liệu normal/mask/roughness không nhập sRGB.

## Material family

| Family | Đặc tính | Chất lượng phải nhìn thấy |
|---|---|---|
| Fur stylized | Nonmetal, roughness khoảng 0,60–0,82; normal rất nhẹ | Khối mềm, mảng lông sạch, không bóng nhựa |
| Nose/eyes | Specular kiểm soát; mắt không thành kính cầu lồi | Catchlight vừa đủ, mí đọc được |
| Linen/rug | Roughness 0,78–0,92; weave tương phản thấp | Sợi chỉ cảm nhận ở gần, không moiré ở camera game |
| Wood | Roughness 0,45–0,70; seam/vân có tiết chế | Ván gỗ đẹp trong mảng nắng; không photogrammetry bẩn |
| Ceramic | Roughness 0,25–0,45, màu men dịu | Một highlight rộng, không tạo điểm chói lấn board |
| Leaves | Roughness 0,55–0,80, mặt trước/sau có sắc khác | Cảm giác lá mềm mà không cần transmission nặng |

URP dùng smoothness trong nhiều shader: chuyển đổi có chủ đích từ roughness (`smoothness = 1 − roughness` khi đúng convention), không gán trực tiếp kênh roughness vào alpha metallic. Không coi ARM/ORM của một pack là đúng channel layout cho shader tùy chỉnh.

## Ánh sáng và bóng

M01: một nguồn nắng nghiêng tạo pattern cửa sổ chéo, fill ấm và bóng tiếp xúc rõ. Bắt đầu với key/fill tương phản vừa phải, tune để mèo đen trong bóng còn mắt và form. Baked GI cho nền, probe/ánh sáng phù hợp cho mèo động, shadow nhận đúng ở thảm. Giảm brightness pattern nắng nơi che ranh giới puzzle nếu cần.

Một light rig có mô tả hướng key, màu, fill, exposure, shadow distance/resolution, bake và probe. Lưu cùng map. Không lấy screenshot Blender để thay chứng cứ Unity/Metal. Không dùng bloom hoặc fog toàn màn hình để làm mọi thứ “mềm”.

Tone mapping thử Neutral và grade nhẹ trước; chỉ chọn ACES khi màu pastel vẫn được giữ qua so sánh. Bloom chỉ ở phần thực sự sáng, không khiến lông mèo phát quang. Vignette rất nhẹ hoặc tắt; board không tối ở rìa.

## Quy ước asset

- Scene unit 1 m; một ô board 0,25 m; model source và Unity cùng quy ước. Bone/mesh scale sau import phải được kiểm tra, không mặc định FBX không lỗi ×100.
- Unity board nằm trên XZ, +Y là lên; footprint `(x,y)` logic ánh xạ sang `(X,Z)` qua một hàm duy nhất có quy ước chiều hàng. Root gameplay ở pivot ô; mesh offset, rig và collider proxy tách rõ.
- Chiều cao thân mèo lúc nghỉ thử 0,08–0,12 m; head/ears có thể cao hơn. Mèo dài và mèo cuộn giữ mặt nhìn được từ camera đã khóa.
- `CAT_`, `ENV_`, `PROP_`, `MAT_`, `TEX_`, `ANIM_` là prefix; mỗi asset có ID trong manifest. Nguồn chỉnh sửa tách khỏi runtime export.
- BaseColor không bake shadow cửa sổ; normal/roughness giữ thông tin vật liệu. Ánh sáng không dính vào lông khi con mèo bị nhấc hoặc xoay.

## Wind và animation

Dùng [animation contract](features/presentation/design.md). Model phải được thiết kế để deform: vòng topology quanh vai/bụng/đuôi, weight mềm, hinge tai, shape key mí. Không dồn mọi cử động vào scale toàn bộ object. Rèm có độ dày và nếp gấp; cây có cuống/cành thực, không tấm billboard lớn lắc qua lại.

Gió ít ở bàn, nhiều hơn ở ngoại vi; ánh sáng và shadow phản ứng hợp lý. Cây/vải không rơi khỏi anchor. Không đồng bộ toàn bộ lá, hơi nước và bụi bằng cùng một pha sin.

## Mức đạt và mức loại

| Đạt | Loại |
|---|---|
| Silhouette liền, model đẹp cả khi tắt texture | Các capsule/cube còn đọc như đồ xếp khối |
| Shadow giữ mèo trên thảm | Mèo nổi, xuyên, bóng hai lớp hoặc trễ transform |
| Biểu cảm đọc ở kích thước điện thoại | Mặt nhỏ, mắt dính hoặc decal trôi khi deform |
| Texture có scale và chi tiết tiết chế | Noise quá dày, vân sắc gắt, texture ảnh thực lệch style |
| Cử động phụ nhẹ, phản hồi theo tay | Dao động vô hạn, rung/nhảy khi đổi fps hoặc resume |
| Ánh nắng là một cấu trúc trong cảnh | Overlay trắng vàng phủ mọi thứ |

Mẫu review phải gồm một frame nghỉ, một frame nhấc, clip kéo/xoay/thả và cảnh nhìn nhỏ trên điện thoại. Chỉ nhân rộng asset family sau khi hero và camera đầu tiên đạt.
