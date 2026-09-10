ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LinguaTweakPrefs

LinguaTweakPrefs_FILES = LTPrefsRootListController.m
LinguaTweakPrefs_FRAMEWORKS = UIKit
LinguaTweakPrefs_CFLAGS = -fobjc-arc

LinguaTweakPrefs.bundle_RESOURCES = Resources

include $(THEOS_MAKE_PATH)/bundle.mk
