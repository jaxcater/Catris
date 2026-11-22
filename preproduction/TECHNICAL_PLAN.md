# Kế hoạch kỹ thuật — chưa triển khai

## Quyết định và phần chưa khóa

| Thành phần | Quyết định preproduction | Trạng thái |
|---|---|---|
| Engine | Unity 6.3 LTS, URP, C# | Chọn dòng; patch và packages sẽ khóa khi xác nhận máy build |
| Rendering iOS | Metal, Forward URP làm baseline | Chưa profile; không chọn HDRP |
| DCC | Blender; vendor skills hướng tới 5.2+/5.3 | Chưa cài/kiểm tra Blender thực tế |
| Model interchange | FBX + texture rời; rig Generic | Round-trip và import test chưa chạy |
| UI/input | uGUI + TMP + Input System | Bản package theo editor đã khóa |
| iOS | Portrait, ARM64, IL2CPP, đề xuất iOS 17+ | Target product; cần kiểm tra deployment với Xcode thực tế |
| Device floor | iPhone 12/A14, 60 fps; Eco 30 fps | Mục tiêu thiết kế chưa đo |
| Build host | macOS + Xcode + Unity iOS Build Support | Chưa provision runner/license |
| Backend | Không cần | Save cục bộ đủ phạm vi |

Unity 6.3 là dòng LTS có tài liệu chính thức; iOS build gồm export Unity rồi build Xcode. Đây là lý do chọn pipeline, không đảm bảo chất lượng hình ảnh tự động. [Unity release support](https://unity.com/releases/unity-6/support), [Unity iOS build process](https://docs.unity.com/en-us/engine/6000.3/manual/platform-specific/iphone/ios-building-and-delivering/build-process).

Thiết bị tối thiểu đề xuất của sản phẩm cao hơn mức iOS tối thiểu mà Unity nêu. Không thay `iOS 17+` thành “Unity yêu cầu iOS 17”. [Unity iOS compatibility](https://docs.unity.com/en-us/engine/6000.3/manual/platform-specific/iphone/ios-introducing/ios-requirements-and-compatibility).

## Kiến trúc dự kiến

`PuzzleDomain` giữ board mask, footprint, placement, validation, undo, hint solver và serialization bằng C# thuần. `Presentation` biến domain event thành transform/animation/audio. `Input` đổi touch thành intent. `Content` chứa board/map/cat definitions và references tới asset. `Platform` quản lý lifecycle, save, settings, haptic và build glue.

Camera/world đặt theo board bounds; UI bám safe area. Không dùng tên GameObject như save ID. Scene/prefab setup phải có dữ liệu lưu và tái lập, không phụ thuộc thao tác Editor không được ghi lại. Một map active; dùng local scene loading là baseline, chỉ thêm Addressables nếu đo thấy cần.

Shader parameters và quality tier là data có version; tránh tạo bản sao material mỗi frame. Spring/eye-look cập nhật không cấp phát garbage ổn định. Mesh/skin bounds đúng để animation không biến mất khi bị kéo tới rìa.

## Budget khởi điểm

Đây là budget thiết kế cho scene nặng nhất trên iPhone 12, không phải số liệu đã đạt. Điều chỉnh sau slice nếu có bằng chứng và ghi tác động hình ảnh.

| Hạng mục | Mục tiêu |
|---|---|
| Frame pacing | 60 fps; p95 frame interval ≤18,5 ms sau warmup; tránh hitch >50 ms khi kéo/thả |
| CPU/GPU | p95 CPU main thread ≤10 ms, GPU ≤13 ms; không cộng hai số như thời gian tuần tự |
| Soak | 15 phút thao tác; không tụt kéo dài dưới 50 fps do nhiệt; ghi thermal state và điều kiện thử |
| Memory | Peak resident mục tiêu ≤500 MB; texture resident ≤128 MB; theo dõi render targets riêng |
| Draw calls | Mục tiêu ≤150 trong góc chơi thường; count cả shadow/outline/pass phụ |
| Visible triangles | Mục tiêu ≤220k, gồm mèo và props; không dùng con số này thay đo GPU |
| Mèo hero LOD0 | 6k–12k triangles/con; LOD1 3k–6k; tổng scene vẫn theo budget |
| Rig | Khoảng 16–28 deform bones/con; ≤4 weights/vertex; điều chỉnh theo pose/face |
| Material slots | 1–2/con; atlas và palette dùng chung khi hợp lý |
| Texture | Hero tối đa 2K cho family atlas; props phần lớn 512–1K; normal/mask theo nhu cầu thực |
| Ánh sáng động | Một directional key có shadow; point/spot bổ sung ưu tiên bake hoặc không shadow |
| Shadow | Thử 1024 hoặc 2048, 1 cascade, khoảng cách vừa bao diorama; tune bias và chi phí |
| Post | Color grade/tone mapping; bloom nhẹ nếu cần; không mặc định SSAO/DOF/motion blur |
| Loading | Launch đến màn tương tác mục tiêu ≤4 s sau lần cài đầu đã warm dữ liệu; map switch ≤2 s |
| Kích thước | IPA compressed mục tiêu ≤350 MB; assets nguồn/clip reference/vendor không nằm trong app |

Các con số về triangle/bone không cho phép làm model góc cạnh. Tối ưu silhouette, UV, vật liệu và shader trước khi cắt geometry bừa. Khả năng tiếp cận và chất lượng board phải được giữ khi giảm hiệu ứng.

## Import và chất liệu

FBX được re-import vào file Blender trống để kiểm tra tỷ lệ/clip; trong Unity kiểm tra axes, scale, Generic rig, blendshape, clip ranges, normals/tangents và texture color space. Không tự động map rig mèo sang Humanoid. [Unity model import](https://docs.unity.com/en-us/engine/6000.3/manual/assets-and-media/asset-types/models/importing/fbximporter-model).

BaseColor sRGB; normal và mask linear. iOS texture thử ASTC 6×6 cho màu/props, 4×4 cho face/normal nếu nén làm hỏng; đánh giá ở kích thước hiển thị. Dùng mipmap khi texture 3D cần giảm alias; bảo vệ atlas bằng padding. Roughness nguồn phải được chuyển sang convention shader thật. File JPG nguồn hiện có dùng cho look development; nếu banding/block artifact lộ, lấy bản lossless cùng nguồn trước khi làm material cuối.

## URP, shadow và wind

Baseline Forward, SRP Batcher; opaque khi phù hợp, foliage dùng mesh leaf hoặc alpha cutout/blend tùy đo. Alpha blending không mặc nhiên tốt hơn cutout trên Apple GPU; kiểm tra overdraw, edges, depth và shadow. MSAA 2×/4× là các phương án cần profile, không “miễn phí”.

Deformation phải đồng nhất giữa forward, depth, shadow và outline pass. Tọa độ world/UV cần độ chính xác phù hợp; `half` chỉ dùng nơi sai số cho phép. Các lời khuyên Built-in như surface shader `noforwardadd` không phải API URP. Nếu dùng Renderer Feature, theo Render Graph của version package đã khóa; không copy nguyên pass từ phiên bản khác.

Giảm depth/opaque texture copies, HDR intermediate buffers, shadow resolution và effect passes khi profiler chỉ ra chúng tốn kém. Giữ HDR chỉ khi look cần; so sánh tổng bandwidth ở device. [Unity URP performance settings](https://docs.unity.com/en-us/engine/6000.3/manual/analysis/graphics-performance-profiling/in-urp/optimize-for-better-performance).

## Quality tiers

Balanced 60 fps là mục tiêu chính: GI bake, một key shadow, wind mềm, ít particle. Eco 30 fps giảm particle, shadow resolution, bloom và effect ngoại vi; mèo/face/grid/contact shadow vẫn rõ. High chỉ thêm độ phân giải shadow/render khi máy và nhiệt cho phép, không thay style. Không quyết định tier chỉ bằng `SystemInfo.graphicsMemorySize` trên thiết bị unified memory.

## Ma trận kiểm tra khi triển khai

- iPhone 12/A14 thật: baseline, thermal soak, frame pacing, touch latency và memory.
- Một iPhone Pro/Max mới hơn sẵn có: safe area, màn lớn, refresh rate và quality tier; ghi đúng model/OS trong report.
- Editor/device simulator: kiểm tra viewport 320×568, 375×667, 390×844, 430×932; chỉ chứng minh layout trong môi trường đó.
- Offline, reboot, interrupted drag, background/resume, volume mute, headset route, low power, Reduce Motion và save hỏng.
- iPad không phải đích v1; nếu sau này bật universal app, phải bổ sung orientation/layout/test riêng, không mặc định đã hỗ trợ.

## Dependency và build readiness

Sau lệnh triển khai, ghi chính xác Editor patch, URP/Input System/uGUI versions, Blender version/export preset, macOS runner architecture, Xcode path/SDK, Unity license method và action commit hashes. Chưa có engine project nên không tạo `Packages/manifest.json` giả ở giai đoạn chuẩn bị.

Không đưa secrets vào source hoặc tài liệu; không cần Apple signing secret cho artifact unsigned. Unity license vẫn là dependency riêng. Nếu không có license/runner thì phần build bị chặn, nhưng việc chuẩn bị và các kiểm tra độc lập khác vẫn thực hiện được. Hướng build chi tiết ở [IOS_UNSIGNED_IPA.md](IOS_UNSIGNED_IPA.md).
