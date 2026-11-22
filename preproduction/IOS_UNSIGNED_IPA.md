# Catris — thiết kế đường build IPA unsigned

**Trạng thái:** đặc tả chuẩn bị. Chưa tạo workflow, chưa có Unity project/Xcode project và chưa chạy build. Các lệnh dưới đây là mẫu cho giai đoạn sau, không phải lệnh đã kiểm chứng trên một build Catris.

## Repository và đầu ra

Repository đích: [jaxcater/Catris](https://github.com/jaxcater/Catris). Lần kiểm tra 22/11/2026 thấy `main` ở `d69e399a9d8830f7a21d54b9dc5c3d9346039ddf`, chỉ có README. Thư mục local hiện chưa có `.git`. Không tạo một repo lồng hoặc ghi đè remote dựa trên snapshot cũ; đọc lại trước khi triển khai.

Artifact mong muốn: `Catris-unsigned.ipa`, `Catris-unsigned.ipa.sha256`, log và `build-report.json` ghi commit, version Unity/URP/Xcode/SDK, architecture, bundle ID, file size và kiểm tra signing. Bundle ID đề xuất `com.jaxcater.catris`; đây là tên dự kiến, chưa kiểm tra đăng ký App ID vì unsigned artifact không làm bước đó.

## Toolchain cần có

1. Unity 6000.3 patch cụ thể, cùng iOS Build Support/IL2CPP và package lock.
2. macOS + Xcode có iPhoneOS SDK tương thích; Unity Editor/license phù hợp nếu export trực tiếp trên runner.
3. Host architecture được chọn rõ (Apple Silicon hoặc Intel) và binary Unity phù hợp. Không mặc định `macos-latest` là Intel hoặc mang đúng Xcode.
4. Source mesh/texture lớn dùng LFS khi cần; checkout thực sự tải dữ liệu, không để pointer file vào build.
5. Unity license method được cấu hình ở môi trường build; không nhầm “không ký Apple” với “không cần license Unity”. Chưa chọn/cấp license trong bộ chuẩn bị.

Unity mô tả hai bước: tạo Xcode project rồi dùng Xcode để build; Xcode chạy trên macOS. [Unity iOS build](https://docs.unity.com/en-us/engine/6000.3/manual/platform-specific/iphone/ios-building-and-delivering/build-process). Các runner macOS có nhiều nhãn và architecture, cần đối chiếu trước khi khóa CI. [GitHub runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

## Pipeline dự kiến

Checkout revision → kiểm tra engine/packages/license/SDK và disk → EditMode domain tests + content validation → Unity export iOS Release → Xcode build device archive không ký → kiểm tra app → đóng gói Payload → kiểm tra ZIP/checksum → upload artifact.

Nếu export Unity trên Windows trước, phải chuyển đủ Xcode export sang Mac; lựa chọn này không bỏ được bước macOS. Baseline ưu tiên một macOS build environment đã provision để dễ tái lập. Hosted runner cần kiểm tra dung lượng khi cài Unity; self-hosted Mac là phương án nếu runner thiếu chỗ/license automation, không tự kết nối máy khác trong giai đoạn chuẩn bị.

Workflow sản xuất sau này nên cho phép `workflow_dispatch`, permissions tối thiểu, timeout, concurrency và cache theo engine/package hash. Pin action commit đã kiểm tra; không chạy installer tải từ nhánh `main` mỗi build. Không viết `.github/workflows/*.yml` hoạt động ở giai đoạn này.

## Cấu hình Unity phải xuất

Display name Catris, target device iPhone, portrait cố định, Metal, IL2CPP, ARM64, target iOS đề xuất 17.0. Build Release không Development; scene list đủ boot + menu/M01 + các map đã nằm trong phạm vi. Chỉ nhúng assets runtime; không nhúng `preproduction/`, video gốc hoặc `.blend` nguồn.

Entry point Editor build sẽ được viết khi triển khai, dùng `BuildPipeline.BuildPlayer`, kiểm tra `BuildReport.summary.result` và exit failure nếu không succeeded. Không đặt tên một `-executeMethod` chưa tồn tại rồi ghi hướng dẫn như đang chạy được. Bản export phải có shared scheme được `xcodebuild -list` xác nhận.

## Mẫu build Xcode sau khi đã có export

Chạy trên macOS, trong checkout/build workspace riêng. Đường dẫn và scheme phải khớp export thật; mặc định phổ biến của Unity là `Unity-iPhone`.

```bash
xcodebuild -version
xcodebuild -showsdks
xcodebuild -list -project build/ios/Unity-iPhone.xcodeproj

xcodebuild \
  -project build/ios/Unity-iPhone.xcodeproj \
  -scheme Unity-iPhone \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/Catris.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  archive
```

Các flag không ký là cấu hình dự kiến cần kiểm tra trên Xcode/project thật. Nếu dependency thêm bước signing riêng, xác định target/script gây lỗi; không bật automatic signing hoặc yêu cầu certificate để che lỗi. Dùng log và build settings thực để chẩn đoán. Apple có tài liệu cho `xcodebuild`, schemes và archive; tài liệu đó không tự chứng nhận quy trình unsigned riêng của Catris. [Apple TN2339](https://developer.apple.com/library/archive/technotes/tn2339/_index.html), [Xcode build settings](https://developer.apple.com/documentation/xcode/build-settings-reference).

Không dùng `-exportArchive` với một signing export method rồi mong nó xuất unsigned. Luồng này lấy app đã build đúng platform từ archive và đóng gói riêng.

## Đóng gói và kiểm tra

Từ `build/Catris.xcarchive/Products/Applications/`, tìm app thực tế; xác minh có đúng một app cần đóng gói. Copy vào staging mới thành `Payload/Catris.app`, giữ permission/symlink/framework structure. Đổi tên thư mục app không đồng nghĩa đổi tên executable; đọc `CFBundleExecutable` từ Info.plist.

Trong staging, mẫu đóng gói là:

```bash
COPYFILE_DISABLE=1 /usr/bin/zip -qry ../Catris-unsigned.ipa Payload
unzip -t ../Catris-unsigned.ipa
shasum -a 256 ../Catris-unsigned.ipa > ../Catris-unsigned.ipa.sha256
```

Không copy một thư mục trống vào Payload để có file `.ipa`. Trước upload cần đọc/kiểm tra:

| Kiểm tra | Bằng chứng |
|---|---|
| Có `Payload/Catris.app/Info.plist` và executable không rỗng | `unzip -l`, `plutil`, `test -s` |
| Target đúng device | `CFBundleSupportedPlatforms = iPhoneOS`, `vtool -show-build` hoặc `otool -l` cho executable/framework; kiểm tra platform iOS, không iOS Simulator |
| Kiến trúc | `file`/`lipo -info` có ARM64; bước platform phía trên vẫn bắt buộc |
| Orientation | `UISupportedInterfaceOrientations` chỉ portrait cho iPhone; kiểm tra thêm key iPad nếu sau này bật universal |
| Bundle và deployment | `CFBundleIdentifier`, `CFBundleDisplayName`, `MinimumOSVersion` đúng cấu hình |
| Runtime assets | Unity Data, UnityFramework và mọi dependency có trong app |
| Không ký | `codesign -d` trên app và nested code; kết quả không có signature là kỳ vọng, không coi exit khác 0 là crash build tùy tiện |
| Không lẫn profile | Không chứa `embedded.mobileprovision` hoặc signing material của người khác |
| Nội dung archive | Payload ở root; không thêm lớp staging/Build/Products bên ngoài |

Nếu dependency mang signature có sẵn, ghi trạng thái và chỉ xử lý trên bản staging thuộc build này, theo nhu cầu packaging; không xóa signature ở source asset hoặc SDK cài trên máy. Artifact phải báo trung thực thay vì gắn nhãn unsigned khi chỉ tắt signing ở một target.

## Ý nghĩa của unsigned

IPA unsigned là artifact để ký lại, chưa phải bản có thể mở trực tiếp trên iPhone thông thường. Ký lại cần signing identity/profile phù hợp với thiết bị và quyền mà người dùng có; bước này tách khỏi pipeline artifact hiện tại.

Kiểm tra unsigned bundle không chứng minh gameplay chạy, shader đúng hoặc FPS đạt. Device test sử dụng một bản ký để thử nghiệm cùng source revision/configuration, ghi rõ sai khác signing. Chỉ đưa trạng thái “đã chạy iPhone” khi có evidence thật. Không yêu cầu tài khoản Apple/chứng chỉ riêng ở giai đoạn chuẩn bị này.
