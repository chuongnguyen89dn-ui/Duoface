THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES =
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = DFFirstPartyAdmission
DFFirstPartyAdmission_FILES = DFFirstPartyAdmission.m
DFFirstPartyAdmission_CFLAGS = -fobjc-arc -Wall -Wextra
DFFirstPartyAdmission_FRAMEWORKS = Foundation CoreFoundation
include $(THEOS_MAKE_PATH)/tweak.mk
