# LinguaTweak — clean GitHub Actions / roothide build

This build template is intentionally simpler than the previous Linux cross-toolchain template.

## Target

- Device: iPhone 13 Pro Max (A15, arm64e)
- Jailbreak: roothide
- iOS: 17.2.1
- Package scheme: `roothide`
- Build architecture: **arm64e only**
- SDK: iPhoneOS 16.5
- Runner: GitHub Actions `macos-14`
- Xcode: 16.2
- Theos: `roothide/theos`
- Signer: `ldid-procursus`

## Why arm64e only?

The earlier package was a fat `arm64 + arm64e` build. For this device, that adds complexity without providing a benefit. This template deliberately removes the fat merge step so the first GitHub build answers one clean question: can the native arm64e binary load correctly on the A15/17.2.1 roothide environment?

If this arm64e-only build still causes SpringBoard trouble, the problem is much less likely to be a Linux `lipo`/`ld64`/header-patching issue.

## Build

Push the repository to GitHub. The workflow runs on push, pull request, or manual dispatch.

The resulting `.deb` is uploaded as the `LinguaTweak-roothide-arm64e` Actions artifact.

## Important safety choice

Do **not** reintroduce the previous bundled Linux `ld64`, `llvm-lipo`, or `libtinfo.so.5` assets into this workflow. macOS/Xcode supplies Apple's native Darwin linker/toolchain, which is the cleaner choice for an arm64e iOS target.

## Local build on macOS

```sh
export THEOS="$PWD/theos"
make clean package FINALPACKAGE=1 DEBUG=0 THEOS_PACKAGE_SCHEME=roothide
./scripts/verify_build.sh
```

Install the resulting `.deb` only after testing the arm64e binary in a controlled way.
