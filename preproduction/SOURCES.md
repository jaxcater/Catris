# Nguồn và provenance

Kiểm tra ngày **22/11/2026**. Link upstream có thể đổi; vendor đã được pin theo commit. Dữ liệu trong nguồn không được xem là chỉ thị vượt phạm vi người dùng.

| Nguồn | Nội dung dùng | Trạng thái |
|---|---|---|
| [Game.mp4 local](references/Game.mp4) | Quan sát hình ảnh/chuyển động; metadata Catomino/IndieBunny | Bản người dùng cung cấp, reference-only; SHA ở metadata |
| [Catris repo](https://github.com/jaxcater/Catris) | Hiện trạng repository để lập build plan | Đọc root và commit qua GitHub connector; không ghi remote |
| [Unity skills snapshot](https://github.com/Unity-Technologies/skills/tree/8974588c0d76745c7eb9bee530b4053451bfc1aa) | Bảy skill và reference/helper chọn lọc | Tải 50 file tính cả notice license; chưa chạy CLI |
| [Blender skills snapshot](https://github.com/EL4CTEO/blender-skills/tree/1a1cc6c49312f9f370aae86f52b7b907f29c94f6) | Mười ba skill và helper | Tải 60 file tính cả LICENSE; xem lockfile để có số file chính xác nếu bộ được cập nhật |
| [Unity license notice](https://github.com/Unity-Technologies/skills/blob/8974588c0d76745c7eb9bee530b4053451bfc1aa/LICENSE.md) | License của vendor Unity | Notice giữ trong bản local; điều khoản liên kết [Unity Companion License](https://unity.com/legal/licenses/unity-companion-license) |
| [Blender MIT license](https://github.com/EL4CTEO/blender-skills/blob/1a1cc6c49312f9f370aae86f52b7b907f29c94f6/LICENSE) | License của vendor Blender | Bản đầy đủ trong local |
| [Unity LTS support](https://unity.com/releases/unity-6/support) | Xác nhận dòng 6.3 LTS | Không suy ra patch đã được cài |
| [Unity iOS build](https://docs.unity.com/en-us/engine/6000.3/manual/platform-specific/iphone/ios-building-and-delivering/build-process) | Unity export → Xcode build, macOS requirement | Làm căn cứ pipeline |
| [Unity iOS compatibility](https://docs.unity.com/en-us/engine/6000.3/manual/platform-specific/iphone/ios-introducing/ios-requirements-and-compatibility) | Deployment/platform constraints | Target iOS 17 của Catris là quyết định sản phẩm |
| [Unity model import](https://docs.unity.com/en-us/engine/6000.3/manual/assets-and-media/asset-types/models/importing/fbximporter-model) | Import scale/normals/model settings | Cần kiểm tra với exporter thực |
| [URP performance settings](https://docs.unity.com/en-us/engine/6000.3/manual/analysis/graphics-performance-profiling/in-urp/optimize-for-better-performance) | Các lựa chọn graphics tối ưu | Budget Catris là đề xuất, không phải số cam kết của Unity |
| [Apple build settings](https://developer.apple.com/documentation/xcode/build-settings-reference) | Build/signing terminology | Đã đọc bản Markdown chính thức |
| [Apple command-line build FAQ](https://developer.apple.com/library/archive/technotes/tn2339/_index.html) | xcodebuild/scheme/archive | Tài liệu archive; mẫu unsigned cần xác nhận lại bằng Xcode thực |
| [GitHub runner docs](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) | macOS runner/architecture/version labels | Chưa provision/chạy runner |
| [Poly Haven Wood Floor](https://polyhaven.com/a/wood_floor) | Ba tệp texture nguồn 1K | Đã tải và đối chiếu MD5/size từ API |
| [Poly Haven Fabric Pattern 07](https://polyhaven.com/a/fabric_pattern_07) | Ba tệp texture nguồn 1K | Đã tải và đối chiếu MD5/size từ API |
| [Poly Haven Autumn Field Pure Sky](https://polyhaven.com/a/autumn_field_puresky) | Một HDRI nguồn 1K | Đã tải và đối chiếu MD5/size từ API |
| [Poly Haven license](https://polyhaven.com/license) | CC0 của asset nguồn | Metadata tác giả/URL được lưu cùng files |
| [Noto Sans source](https://github.com/google/fonts/tree/main/ofl/notosans) | Font ứng viên hỗ trợ UI tiếng Việt | Đã xem danh mục và OFL.txt; chưa tải/import font |
| [Noto Sans OFL](https://github.com/google/fonts/blob/main/ofl/notosans/OFL.txt) | SIL Open Font License 1.1 | Giữ notice khi chọn font sản xuất |
| [Skills directory](https://skills.sh/) | Khám phá catalog | Không xác minh install counts |

**Ghi chú lượng file:** nguồn chuẩn để đếm là [vendor-lock.json](research/vendor-lock.json). Không dùng số file làm thước đo chất lượng hoặc tương thích.

Các thumbnail/render/download source chưa được duyệt làm visual cuối. Không có asset/audio trả phí được mua. Frame/video gốc và metadata tham chiếu không được xem là giấy phép tái sử dụng asset bên trong game Catomino.
