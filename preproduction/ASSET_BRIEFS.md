# Vật tư và brief sản xuất

**Trạng thái:** chuẩn bị. Danh mục có cấu trúc ở [asset-manifest.json](assets/asset-manifest.json); bảy tệp nguồn đã tải và checksum ở [downloaded-materials.json](assets/downloaded-materials.json). Model mèo, rig, animation, audio và material game cuối chưa được tạo.

## Vật tư có sẵn và phần còn phải làm

| Hạng mục | Có sẵn | Cần sản xuất sau |
|---|---|---|
| Tham chiếu | Video, 72 frame, bốn contact sheet có thời gian | Capture đối chiếu trong game |
| Gỗ | Diffuse/normal GL/roughness 1K của Poly Haven | Giảm noise, chỉnh palette, kiểm tra seamless/scale và đóng kênh cho shader |
| Vải | Color/normal GL/roughness 1K của Poly Haven | Thiết kế họa tiết riêng M01; dùng weave mức thấp; check moiré |
| Sky lighting | HDRI 1K Autumn Field Pure Sky | Chọn rotation/intensity, bake/probe; không dùng ảnh thực làm toàn bộ bối cảnh |
| Mèo | Footprint, tính cách, art/rig brief | Năm mesh nguồn, texture/UV, rig, clips, export và QA |
| Props/map | Brief năm map, danh sách asset | DCC authoring, bake, import và scene assembly |
| Audio | Danh sách event, loop/mix/cooldown spec | Ghi/commission/source file có license và kiểm tra bằng tai |
| UI | Layout portrait, font source ứng viên | Font import/atlas có tiếng Việt, icon/menu theo art style |

Các nguồn Poly Haven được trang chính thức gắn CC0, kèm metadata tác giả trong từng thư mục; giữ provenance dù attribution không bắt buộc theo mô tả của nguồn. [Poly Haven license](https://polyhaven.com/license). Chưa mua asset trả phí.

## Hero cat package

Một package bàn giao cho mỗi CAT-01…05 gồm: `.blend` có high/low nếu bake; low mesh đã UV; texture BaseColor/Normal/mask theo shader; Generic rig; named animation actions; FBX; preview nghỉ/nhấc/deform; báo cáo tris, bones, weights, materials, scale, clip names; nguồn/giấy phép.

Tuân theo budget tại [kế hoạch kỹ thuật](TECHNICAL_PLAN.md), scale tại [art bible](ART_BIBLE.md), footprint tại [packing](features/packing/design.md). Hình chiếu trên board phải vừa footprint và không làm silhouette giống các khối nối. Không dùng một cat normal rồi stretch phi tuyến cực mạnh để thành mọi shape.

- **CAT-01 Nori:** thân dài đen charcoal, highlight rộng đủ đọc bụng, mắt sáng dịu; spine nhiều đoạn, tail/paws có secondary motion. Không thân cylinder và hai quả cầu mắt dán lên.
- **CAT-02 Sumi:** nâu trầm, dáng L mềm bằng thân/chân cuộn, tai hơi bất đối xứng, nét ngái ngủ. Chỗ gấp phải có topology hỗ trợ deform.
- **CAT-03 Pudding:** tam thể, footprint zigzag, ôm một đồ chơi vải nhỏ do Catris thiết kế. Mảng lông lớn sạch, mặt vẫn đọc khi xoay.
- **CAT-04 Mochi:** kem xám, dáng cuộn nhỏ, tail curl rõ, sọc mảnh vừa đủ. Tránh normal/vân lông lấn biểu cảm.
- **CAT-05 Miso:** mèo cam một ô, đầu và mặt đọc ở kích thước nhỏ; idle tò mò hơn nhưng không nhảy liên tục.

Rig theo nhu cầu hình thể; không mặc định cả năm phải chung một skeleton không phù hợp. Có thể chia sẻ controller và animation semantics. Các bone/shape key tối thiểu: root, body/spine, head, tail chain, ear controls, paws khi cần, blink L/R, eye look, squash/lift corrective. Tên và thứ tự trong manifest clip phải thống nhất.

## Pipeline bắt buộc

Concept từ nhiều góc → sculpt/form refinement → retopo hữu cơ → UV và texel density → bake high-to-low nếu cần → texture family → rig/weights/correctives → animation → LOD → FBX export → import Unity → iPhone look/performance review.

Kiểm tra cả matcap, wireframe, UV và shaded preview. Generated mesh phải qua cùng quy trình. Không lấy một render đẹp làm bằng chứng topology/rig đã đạt. Đối với Unity, material node Blender không tự chuyển nguyên xi; bake texture và dựng material đúng URP.

## Prompt concept mèo — dùng sau khi bắt đầu, chưa gọi công cụ

Thay `[CAT]`, `[FOOTPRINT]`, `[PALETTE]` theo manifest; giữ seed/reference được duyệt xuyên suốt family.

```text
Purpose: a production concept reference for Catris, a premium cozy 3D
cat-packing puzzle for portrait iPhone screens.
Subject: [CAT], a soft stylized cat resting in the organic pose described
by [FOOTPRINT]. The footprint guides the overall occupied space only.
The body must read as one continuous sculpted creature: rounded shoulders,
belly, tucked paws, expressive eyelids, soft ears, a believable curling tail.
Palette: [PALETTE], matte-to-satin fur, broad gentle highlights, clean large
fur markings, tiny controlled material detail, no photorealistic hair.
Views: neutral top, front, side and three-quarter views with consistent
identity and proportions. Include a separate silhouette view for readability.
Lighting: neutral soft studio lighting for the model sheet, no baked window
shadows in the fur. Plain neutral background. Keep all extremities visible.
Avoid: cube or capsule chains, exposed primitive joints, voxel or flat low-poly
style, plastic gloss, oversized accessories, typography, logos and watermarks.
This output is concept art only, not a finished mesh, UV map, rig or animation.
```

## Brief model/rig cho Blender hoặc artist

```text
Build the approved Catris hero concept as a deformable game asset.
Use the supplied footprint and camera as constraints; one grid cell is 0.25 m.
Deliver a continuous organic silhouette and intentionally authored anatomy.
Follow the triangle, bone, material and texture budgets in TECHNICAL_PLAN.md.
Preserve head readability from the portrait overhead game camera.
Retopologize for shoulders, belly, curled limbs, tail and facial deformation.
UV unwrap, paint cohesive stylized albedo, use restrained normal detail.
Keep lighting separate from BaseColor. Rig as a non-humanoid/Generic character.
Provide blink, gaze, ear and tail controls plus corrective shapes for lift/drop.
Bake exported constraints; deliver named clips and a documented rest pose.
Export FBX plus textures, then re-import to validate scale, normals, skin,
blendshapes and clips. Keep editable .blend sources and an asset QA report.
Do not deliver primitive assemblies, a render-only object, or an untested rig.
```

## Prompt concept map — một family, năm composition

```text
Create a portrait 9:16 environment concept for Catris using map [MAP-ID]
from MAPS.md. Premium soft stylized 3D diorama, warm tactile materials,
art-directed indirect light and grounded contact shadows.
Near-overhead game camera with a small tilt; the central playable rug remains
unobstructed and readable. Reserve an integrated lower area for the cat tray
and clear space for tiny controls. Compose the room for portrait from scratch.
Use [MAP PALETTE], [HERO PROPS], [LIGHTING SIGNATURE], [WIND MATERIALS].
Keep the same cat scale and material language as the approved M01 target.
Environmental detail gathers at the frame edges; depth and atmosphere never
obscure the puzzle. No UI text, branding, photorealistic compositing, heavy
bloom, dramatic fog, neon, flat vector scenery or geometric placeholder cats.
This is a concept target; final graphics must be real-time 3D on iPhone.
```

Không sinh cả năm map trước khi M01 và hero mèo được duyệt. Concept phải được đối chiếu với reference; không tự coi một ảnh “premium 3D” là khớp clip.

## Props và texture

Ưu tiên các family trong manifest: floor/rug/window, curtain, broadleaf plant/pot, guitar/books/cup/cushion, oak/root/grass/flower/picnic kit, greenhouse/vine/chime/terracotta, rainy window/lamp/book kit, attic frame/night props. Model silhouette chính; bake chi tiết nhỏ. Cloth phải có nếp và độ dày hợp lý, plant có anchor/mask gió được bàn giao.

Texture prompt nếu sử dụng công cụ sinh ảnh: yêu cầu surface cụ thể, tileable, ánh sáng phẳng, không shadow/specular bake, không text/logo; kiểm tra lát 3×3 và color space sau đó. Normal/roughness phải được kiểm chứng bằng render vật liệu; không coi bản ảnh do AI gọi là “normal map” là dữ liệu chuẩn.

## Audio acquisition brief

Nhạc/ambience/foley theo [presentation](features/presentation/design.md). Không có bản nhạc hay tiếng mèo được tải hoặc tạo trong phiên này. Ưu tiên original recording/commission hoặc asset có license được xác nhận tại trang gốc. Với meow, không nhận một preview bị watermark làm file cuối.

```text
Compose/record a quiet, intimate sound set for Catris, a relaxing cat puzzle.
Deliver clean 48 kHz / 24-bit WAV masters, separate stems where relevant,
seamless loop points, headroom, no sudden loud events, no voiceover or lyrics.
Music: sparse acoustic/ambient, gentle harmonic movement, 90–150 second loops.
Foley: tactile linen/rug pickup and soft placement, subtle rotation swish,
small wooden UI taps; provide several natural variations.
Cats: gentle chirps, short meows and purrs with distinct personalities;
keep playback suitable for frequent close listening on phone speakers.
Ambience: five distinct map beds following MAPS.md, with isolated optional
wind, leaf, rain and chime accents. Avoid recognizably short repeating cycles.
Include author/source, license or assignment terms, loop markers and file list.
```

Không có giá/budget mua asset được cam kết. Nếu cần paid pack, ghi đúng URL, điều khoản, giá tại lúc kiểm tra, nội dung thiếu và lý do chọn trước khi mua.
