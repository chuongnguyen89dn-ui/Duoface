THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES =
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = DFNativeDockOwnerProbe
DFNativeDockOwnerProbe_FILES = Tweak.x
DFNativeDockOwnerProbe_CFLAGS = -fobjc-arc
DFNativeDockOwnerProbe_FRAMEWORKS = UIKit Foundation QuartzCore
include $(THEOS_MAKE_PATH)/tweak.mk
