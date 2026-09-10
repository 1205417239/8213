# roothide / iPhone 13 Pro Max (A15): build native arm64e only.
ARCHS = arm64e
VERSION = 0.1.0
TARGET = iphone:clang:16.5:17.0

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LinguaTweakPrefs
LinguaTweakPrefs_FILES = LTPrefsRootListController.m
LinguaTweakPrefs_INSTALL_PATH = /Library/PreferenceBundles
LinguaTweakPrefs_CFLAGS = -fobjc-arc -Wall
LinguaTweakPrefs_FRAMEWORKS = UIKit Foundation
LinguaTweakPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk
