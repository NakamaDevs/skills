# Platform checklist

## macOS

- Install Git and `mise`.
- Install the Xcode version supported by the pinned Flutter SDK.
- Select it with `xcode-select` and accept its license.
- Provision Flutter through the repository's `mise` task when one exists.
- Keep Flutter and other large caches outside the Actions work directory.
- Validate with `flutter doctor -v`, a native build, and the repository's macOS
  verification task.

## Windows

- Install Git for Windows and `mise`.
- Enable long paths for the provisioning clone rather than globally where
  possible.
- Install Visual Studio with **Desktop development with C++**, CMake, and a
  supported Windows SDK.
- For ARM64 builds, add the ARM64 MSVC tools. Add Clang/LLVM when a native
  dependency does not support MSVC ARM64.
- Use a short persistent Flutter path when generated paths approach Windows'
  legacy path limit.
- Validate with `flutter doctor -v`, a native build, and the repository's
  Windows verification task.

## Lean Flutter pattern

1. Pin a stable Flutter tag and exact commit.
2. Clone that tag with `--depth 1 --single-branch`.
3. Verify the checkout commit before use.
4. Run `flutter precache` only for the host target.
5. Expose `flutter` and `dart` through repository shims or `mise`.
6. Reuse the SDK between jobs; do not upload and download a multi-gigabyte SDK
   cache for a persistent self-hosted host.

Native desktop targets are built on their native operating system.
