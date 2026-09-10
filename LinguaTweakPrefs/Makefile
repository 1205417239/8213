ARCHS = arm64e
TARGET = iphone:clang:16.5:17.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LinguaTweakPrefs

LinguaTweakPrefs_FILES = LTPrefsRootListController.m
LinguaTweakPrefs_FRAMEWORKS = UIKit
LinguaTweakPrefs_PRIVATE_FRAMEWORKS = Preferences
LinguaTweakPrefs_CFLAGS = -fobjc-arc
LinguaTweakPrefs_INSTALL_PATH = /Library/PreferenceBundles
LinguaTweakPrefs_BUNDLE_RESOURCES = Resources

include $(THEOS_MAKE_PATH)/bundle.mk
