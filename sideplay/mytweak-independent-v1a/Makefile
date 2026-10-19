THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

# No app-host or UI source is linked into the diagnostic DEB.
TWEAK_NAME = DFV1APreflight
DFV1APreflight_FILES = V1ATweak.x MTPreflight.m
DFV1APreflight_CFLAGS = -fobjc-arc
DFV1APreflight_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
