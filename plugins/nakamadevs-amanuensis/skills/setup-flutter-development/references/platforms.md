# Flutter target matrix

Use the repository's pinned Flutter version. Requirements below are target
toolchains, not a reason to install every platform.

| Target | Host | Required tooling | Validation |
| --- | --- | --- | --- |
| Web | macOS or Windows | Chrome or Edge | `flutter devices`; `flutter build web` |
| Android | macOS or Windows | Latest stable Android Studio, Android SDK platform, Build-Tools, command-line tools, Emulator, Platform-Tools, CMake, NDK | `flutter doctor --android-licenses`; `flutter emulators`; `flutter devices` |
| macOS | macOS only | Compatible Xcode and command-line tools | `flutter build macos` |
| iOS | macOS only | Compatible Xcode, simulator or device, signing when deploying to hardware | `flutter build ios --simulator` |
| Windows | Windows only | Visual Studio Desktop development with C++, CMake, Windows SDK; architecture-specific tools when building ARM64 | `flutter build windows` |

For Android emulators, choose an ARM image on arm64 hosts and an x86/x64 image
on x64 hosts. Accept SDK licenses interactively only after reviewing them.

For web debugging, Chrome or Edge is the supported direct device. Other browsers
can use `flutter run -d web-server` with reduced debugging support.

Official references:

- https://docs.flutter.dev/install/custom
- https://docs.flutter.dev/platform-integration/android/setup
- https://docs.flutter.dev/platform-integration/web/setup
- https://docs.flutter.dev/platform-integration/macos
- https://docs.flutter.dev/platform-integration/windows/setup
