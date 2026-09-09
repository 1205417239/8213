# roothide / iPhone 13 Pro Max (A15): build the native arm64e slice only.
# Deliberately no fat merge: this keeps the first diagnostic build simple.
ARCHS = arm64e
VERSION = 0.1.0
# Fix: don't pin a single SDK patch release (17.2 hard-fails if that exact
# SDK isn't installed); use the newest available SDK while keeping the
# deployment target at 14.0. Code uses no iOS 17-only API.
TARGET = iphone:clang:16.5:17.0
INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LinguaTweak

LinguaTweak_FILES = \
	Tweak.x \
	Sources/Core/LTManager/LTManager.m \
	Sources/Freeze/LTFreezeManager/LTFreezeManager.m \
	Sources/Screenshot/LTScreenshotManager/LTScreenshotManager.m \
	Sources/Translate/LTTranslateManager/LTTranslateManager.m \
	Sources/AI/LTAIManager/LTAIManager.m \
	Sources/Editor/LTEditorManager/LTEditorManager.m \
	Sources/LongShot/LTLongShotManager/LTLongShotManager.m \
	Sources/Sileo/LTSileoTranslateManager/LTSileoTranslateManager.m \
	Sources/UI/LTToolbarView.m \
	Sources/UI/LTHintLabel.m \
	Sources/UI/LTTranslatePanel.m

LinguaTweak_CFLAGS = -fobjc-arc -Wall \
	-ISources/Core/LTManager \
	-ISources/Freeze/LTFreezeManager \
	-ISources/Screenshot/LTScreenshotManager \
	-ISources/Translate/LTTranslateManager \
	-ISources/AI/LTAIManager \
	-ISources/Editor/LTEditorManager \
	-ISources/LongShot/LTLongShotManager \
	-ISources/Sileo/LTSileoTranslateManager \
	-ISources/UI

# Fix: link Photos — LTScreenshotManager.m imports <Photos/Photos.h>
# (PHPhotoLibrary / PHAssetChangeRequest); missing it fails compile/link.
LinguaTweak_FRAMEWORKS += UIKit Foundation CoreGraphics QuartzCore Photos
LinguaTweak_PRIVATE_FRAMEWORKS =

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += LinguaTweakPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
