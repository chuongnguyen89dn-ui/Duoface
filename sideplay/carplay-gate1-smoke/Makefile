THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES =
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = DFGate1SmokeAdmission
DFGate1SmokeAdmission_FILES = .generated/Gate1CarPlay.m .generated/Gate1SpringBoard.m Gate1RuntimeProbe.m
DFGate1SmokeAdmission_CFLAGS = -fobjc-arc
DFGate1SmokeAdmission_FRAMEWORKS = Foundation
include $(THEOS_MAKE_PATH)/tweak.mk
