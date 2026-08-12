# Environment Setup — Windows CLI Only

**Trạng thái:** `PASS` trên máy development sau storage migration ngày 2026-08-12.

**Ràng buộc:** Không sử dụng Android Studio.

## Kết quả audit 2026-08-12

Toolchain đã được cài user-local, không dùng Android Studio, và đã được chuyển khỏi ổ C:

- Windows 11 Home Single Language x64, build 26200.
- Flutter 3.44.9 stable; Dart 3.12.2.
- Temurin OpenJDK 17.0.20+8.
- Android Command-line Tools 22.0.
- Android SDK Platform/Build-tools 36.0.0, platform-tools/ADB 37.0.1.
- Android licenses accepted.
- Android Emulator 37.1.11, Android 35 Google APIs x86_64 system image revision 9.
- AVD `DLU_LMS_Pixel` đã boot bằng WHPX; Flutter/ADB nhận Android 15/API 35.

## Storage layout hiện tại

```text
D:\DLU-LMS\
├── Toolchains\flutter
├── Toolchains\jdk-17
├── Android\Sdk
├── Android\AVD
├── Caches\Gradle
├── Caches\Pub
├── Build\DoAnTotNghiep
├── Artifacts
└── Archives
```

User environment variables:

```text
JAVA_HOME=D:\DLU-LMS\Toolchains\jdk-17
ANDROID_HOME=D:\DLU-LMS\Android\Sdk
ANDROID_SDK_ROOT=D:\DLU-LMS\Android\Sdk
ANDROID_AVD_HOME=D:\DLU-LMS\Android\AVD
ANDROID_EMULATOR_HOME=D:\DLU-LMS\Android\EmulatorHome
GRADLE_USER_HOME=D:\DLU-LMS\Caches\Gradle
PUB_CACHE=D:\DLU-LMS\Caches\Pub
```

ADB keys nhỏ vẫn nằm trong `%USERPROFILE%\.android`; emulator config và AVD lớn lần lượt được điều hướng bằng `ANDROID_EMULATOR_HOME` và `ANDROID_AVD_HOME`.

Compatibility junctions:

- `%LOCALAPPDATA%\Android\Sdk` → `D:\DLU-LMS\Android\Sdk`.
- `%USERPROFILE%\.gradle` → `D:\DLU-LMS\Caches\Gradle`.
- Build junction bình thường được giữ ngoài OneDrive tại `%LOCALAPPDATA%\DLU-LMS\WorkspaceLinks\DoAnTotNghiep-build` → `D:\DLU-LMS\Build\DoAnTotNghiep`.

Repository source/Git vẫn ở OneDrive trong phiên Codex hiện tại. Chỉ source nhỏ được giữ trên C; generated build, toolchains, SDK, caches, AVD và artifacts đều nằm trên D.

### OneDrive-safe Flutter commands

OneDrive không hỗ trợ reparse point trong synced root. Không để repository `build\` junction tồn tại khi OneDrive đang sync. Dùng wrapper sau thay cho lệnh Flutter trực tiếp:

```powershell
.\tool\flutter_dlu.ps1 doctor -v
.\tool\flutter_dlu.ps1 analyze
.\tool\flutter_dlu.ps1 test
.\tool\flutter_dlu.ps1 build apk --debug -t lib/main.dart
.\tool\flutter_dlu.ps1 run -d emulator-5554 -t lib/main_development.dart
```

Wrapper kiểm tra storage gate, dừng OneDrive nhẹ nhàng, đưa junction vào repository, chạy Flutter, sau đó cất junction về AppData và khởi động OneDrive lại trong `finally`. Các VS Code launch profiles cũng gọi `preLaunchTask`/`postDebugTask` tương ứng.

Kiểm tra hoặc phục hồi thủ công nếu một debug session bị kết thúc bất thường:

```powershell
.\tool\build_storage.ps1 -Action Status
.\tool\build_storage.ps1 -Action Cleanup
```

## 1. Flutter SDK

1. Tải Flutter stable Windows bundle từ tài liệu chính thức: <https://docs.flutter.dev/install/manual>.
2. Giải nén vào `D:\DLU-LMS\Toolchains\flutter`.
3. Thêm `D:\DLU-LMS\Toolchains\flutter\bin` vào **User PATH**.
4. Đóng/mở lại VS Code và terminal, rồi kiểm tra:

```powershell
flutter --version
dart --version
```

Không pin version trong tài liệu này trước khi project được scaffold. Sau khi chọn version, phải ghi version vào `docs/PROJECT_STATUS.md` và giữ CI/developer environment đồng nhất.

## 2. JDK

JDK đã được cài tại `D:\DLU-LMS\Toolchains\jdk-17`. Đặt `JAVA_HOME` tới đường dẫn này và thêm `%JAVA_HOME%\bin` vào User PATH.

```powershell
java -version
```

Không dùng JDK đi kèm Android Studio.

## 3. Android SDK Command-line Tools

1. Tải **Command line tools only for Windows** từ Android Developers: <https://developer.android.com/studio#command-tools>.
2. Dùng SDK root `D:\DLU-LMS\Android\Sdk`.
3. Sau giải nén, cấu trúc bắt buộc phải có:

```text
D:\DLU-LMS\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat
```

4. Đặt User environment variables:

```text
ANDROID_SDK_ROOT=D:\DLU-LMS\Android\Sdk
PATH += %ANDROID_SDK_ROOT%\cmdline-tools\latest\bin
PATH += %ANDROID_SDK_ROOT%\platform-tools
PATH += %ANDROID_SDK_ROOT%\emulator
```

5. Mở terminal mới và kiểm tra package có sẵn trước khi chọn SDK platform:

```powershell
sdkmanager --sdk_root="$env:ANDROID_SDK_ROOT" --list
```

6. Cài các package nền tảng. `platforms;android-XX` và `build-tools;XX.X.X` phải khớp Flutter template/Gradle configuration được tạo ở Phase 2, không chọn theo phỏng đoán:

```powershell
sdkmanager --sdk_root="$env:ANDROID_SDK_ROOT" "platform-tools" "cmdline-tools;latest"
sdkmanager --sdk_root="$env:ANDROID_SDK_ROOT" "platforms;android-XX" "build-tools;XX.X.X"
sdkmanager --sdk_root="$env:ANDROID_SDK_ROOT" --licenses
```

Tài liệu `sdkmanager` chính thức: <https://developer.android.com/tools/sdkmanager>.

## 4. Kết nối Flutter với Android SDK

```powershell
flutter config --android-sdk "$env:ANDROID_SDK_ROOT"
flutter doctor -v
adb version
adb devices -l
```

Để dùng thiết bị thật: bật Developer options/USB debugging, dùng cáp tin cậy và xác nhận RSA prompt trên thiết bị. Không bypass device policy.

Nếu dùng emulator, cài system image vào `D:\DLU-LMS\Android\Sdk` và tạo AVD trong `D:\DLU-LMS\Android\AVD` bằng `sdkmanager` + `avdmanager`; Android Studio không cần thiết. Máy hiện tại đã cài `system-images;android-35;google_apis;x86_64` và tạo `DLU_LMS_Pixel` bằng profile Pixel 7.

## 5. Acceptance checklist

- [x] `flutter --version` thành công từ D.
- [x] `dart --version` thành công từ D.
- [x] `java -version` thành công từ D.
- [x] `sdkmanager --list` thành công từ D.
- [x] `adb version` thành công từ D.
- [x] `flutter doctor -v` không còn lỗi Android toolchain cản build.
- [x] `DLU_LMS_Pixel` ở trạng thái `device` trong `adb devices -l` và xuất hiện trong `flutter devices`.
- [x] `flutter analyze`, `flutter test`, `flutter build apk --debug` đều PASS sau migration.

Không tự cài hoặc sửa machine-wide settings từ automation nếu người dùng chưa duyệt.
