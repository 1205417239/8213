ARCHS = arm64e
TARGET = iphone:clang:16.5:17.0
PACKAGE_VERSION = 0.1.0

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LinguaTweak

LinguaTweak_FILES = Tweak.x \
Sources/Core/LTManager/LTManager.m \
Sources/Freeze/LTFreezeManager/LTFreezeManager.m \
Sources/Screenshot/LTScreenshotManager/LTScreenshotManager.m \
Sources/Translate/LTTranslateManager/LTTranslateManager.m \
Sources/AI/LTAIManager/LTAIManager.m \
Sources/Editor/LTEditorManager/LTEditorManager.m \
Sources/LongShot/LTLongShotManager/LTLongShotManager.m \
Sources/Sileo/LTSileoTranslateManager/LTSileoTranslateManager.m \
Sources/UI/LTToolbarView.m \
Sources/UI/LTTranslatePanel.m \
Sources/UI/LTHintLabel.m

LinguaTweak_CFLAGS = -fobjc-arc -Wall -Wno-deprecated-declarations \
-ISources/Core/LTManager \
-ISources/Freeze/LTFreezeManager \
-ISources/Screenshot/LTScreenshotManager \
-ISources/Translate/LTTranslateManager \
-ISources/AI/LTAIManager \
-ISources/Editor/LTEditorManager \
-ISources/LongShot/LTLongShotManager \
-ISources/Sileo/LTSileoTranslateManager \
-ISources/UI

LinguaTweak_FRAMEWORKS = UIKit Foundation

SUBPROJECTS += LinguaTweakPrefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
