THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES =
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = DFNativeSceneJoinProbe
DFNativeSceneJoinProbe_FILES = Tweak.x DFNativeSceneProbe.m DFCarPlayLiveOwnerSnapshot.m DFNativeSceneContract.m
DFNativeSceneJoinProbe_CFLAGS = -fobjc-arc -Wall -Wextra
DFNativeSceneJoinProbe_FRAMEWORKS = UIKit Foundation CoreGraphics
include $(THEOS_MAKE_PATH)/tweak.mk
