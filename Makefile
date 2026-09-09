include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += LinguaTweakPrefs

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
