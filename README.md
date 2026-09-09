# LinguaTweak v0.1.0

System-wide screen text toolkit for iOS 17.2.1 (arm64e), built with Theos,
roothide-compatible.

## Modules (Sources/)

| Module     | Class                        | Responsibility                              |
|------------|-------------------------------|----------------------------------------------|
| Core       | LTManager                     | Preferences, Darwin-notify reload, module registry |
| Freeze     | LTFreezeManager                | Freeze current screen into a still overlay   |
| Screenshot | LTScreenshotManager            | Region/full-screen capture + Photos save     |
| Translate  | LTTranslateManager             | Pluggable translation engines + result panel |
| AI         | LTAIManager                    | Summarize/explain/rewrite/custom prompt      |
| Editor     | LTEditorManager                | Crop / text / freehand annotate captured images |
| LongShot   | LTLongShotManager               | Scrolling capture + stitch into one image    |
| Sileo      | LTSileoTranslateManager         | Translate Sileo package descriptions in place|
| UI         | LTToolbarView / LTHintLabel / LTTranslatePanel | Shared floating UI components |

## UI behavior implemented

- No Chinese-language UI strings; all user-facing text is English.
- Toolbar: transparent, borderless, fixed length (260x44pt), horizontally
  scrollable icons, left-aligned to selection by default, right-edge
  avoidance flips to right-aligned when it would overflow the screen.
- Long-press an icon for 2s to show an English hint label that
  auto-dismisses after 1s.
- Translate panel: bottom third of screen, fixed height, scrollable
  (UITextView), swipe-down-to-dismiss, tap-blank-to-dismiss, top-left/
  top-right semicircle rounded corners only.

## Build

```
export THEOS=/path/to/theos
make package FINALPACKAGE=1
```

Produces a .deb under `packages/`, targeting `iphoneos-arm64` /
`iphone:clang:17.2:14.0`, arm64e+arm64 slices.

## roothide

`THEOS_PACKAGE_SCHEME = roothide` is set in both Makefiles so the build
produces a rootless/roothide-layout package (paths under
`/var/jb` are resolved by the roothide toolchain at package time; no
hardcoded `/var/jb` paths appear in source so the same build works on
classic rootful jailbreaks too).

## Extension points

Every manager header documents its extension point in a top-of-file
comment (e.g. swap in a real translation engine, a real AI backend, a
smarter long-shot stitcher, precise Sileo view targeting). The
`LTModule` protocol in `LTManager.h` and `LTManager registerModule:`
mean new modules plug in without modifying existing ones.
