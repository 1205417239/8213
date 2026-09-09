ARCHS = arm64e
TARGET = iphone:clang:16.5:17.0
PACKAGE_VERSION = 0.1.0

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LinguaTweak

LinguaTweak_FILES = Tweak.x
LinguaTweak_CFLAGS = -fobjc-arc -Wall
LinguaTweak_FRAMEWORKS = UIKit Foundation

SUBPROJECTS += LinguaTweakPrefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
