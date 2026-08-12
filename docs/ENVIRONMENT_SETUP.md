# Environment Setup — Windows CLI Only

**Trạng thái:** `PASS` trên máy development đã audit ngày 2026-08-12.

**Ràng buộc:** Không sử dụng Android Studio.

## Kết quả audit 2026-08-12

Toolchain đã được cài user-local, không dùng Android Studio:

- Windows 11 Home Single Language x64, build 26200.
- Flutter 3.44.9 stable; Dart 3.12.2.
- Temurin OpenJDK 17.0.20+8.
- Android Command-line Tools 22.0.
- Android SDK Platform/Build-tools 36.0.0, platform-tools/ADB 37.0.1.
- Android licenses accepted.
- Không có Android device tại thời điểm kiểm tra; debug APK build đã PASS.

User variables hiện được cấu hình cho `JAVA_HOME`, `ANDROID_HOME`, `ANDROID_SDK_ROOT` và PATH. Mở lại VS Code/terminal để nhận biến mới.

## 1. Flutter SDK

1. Tải Flutter stable Windows bundle từ tài liệu chính thức: <https://docs.flutter.dev/install/manual>.
2. Giải nén vào đường dẫn ngắn, không có khoảng trắng và không nằm trong OneDrive, ví dụ `C:\dev\flutter`.
3. Thêm `C:\dev\flutter\bin` vào **User PATH**.
4. Đóng/mở lại VS Code và terminal, rồi kiểm tra:

```powershell
flutter --version
dart --version
```

Không pin version trong tài liệu này trước khi project được scaffold. Sau khi chọn version, phải ghi version vào `docs/PROJECT_STATUS.md` và giữ CI/developer environment đồng nhất.

## 2. JDK

Cài OpenJDK phù hợp với Flutter/Android Gradle Plugin được chọn. JDK 17 là điểm khởi đầu hợp lý cho toolchain Android hiện đại, nhưng kết quả cuối cùng phải do `flutter doctor -v` và build thực tế xác nhận. Thêm `JAVA_HOME` và `%JAVA_HOME%\bin` vào User PATH.

```powershell
java -version
```

Không dùng JDK đi kèm Android Studio.

## 3. Android SDK Command-line Tools

1. Tải **Command line tools only for Windows** từ Android Developers: <https://developer.android.com/studio#command-tools>.
2. Dùng SDK root riêng, ví dụ `%LOCALAPPDATA%\Android\Sdk`.
3. Sau giải nén, cấu trúc bắt buộc phải có:

```text
%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat
```

4. Đặt User environment variables:

```text
ANDROID_SDK_ROOT=%LOCALAPPDATA%\Android\Sdk
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

Nếu dùng emulator, tạo AVD bằng `sdkmanager` + `avdmanager` sau khi chọn system image phù hợp; Android Studio không cần thiết.

## 5. Acceptance checklist

- [ ] `flutter --version` thành công.
- [ ] `dart --version` thành công.
- [ ] `java -version` thành công.
- [ ] `sdkmanager --list` thành công.
- [ ] `adb version` thành công.
- [ ] `flutter doctor -v` không còn lỗi Android toolchain cản build.
- [ ] Ít nhất một Android device/emulator ở trạng thái `device` trong `adb devices -l`.
- [ ] Sau khi scaffold: `flutter analyze`, `flutter test`, `flutter build apk --debug` đều PASS.

Không tự cài hoặc sửa machine-wide settings từ automation nếu người dùng chưa duyệt.
