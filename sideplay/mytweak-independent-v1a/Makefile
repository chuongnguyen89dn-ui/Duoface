THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = SpringBoard CarPlay
include $(THEOS)/makefiles/common.mk

# Same in-place package ID/dylib, native Apple Dock bridge is a real
# CarPlay-process geometry observer, not a painted mock sidebar.
TWEAK_NAME = DFV1APreflight
DFV1APreflight_FILES = V1ATweak.x MTPreflight.m MTTrialLog.m MTBridgeCoordinator.m MTBridgeRootViewController.m MTSplitContainerViewController.m MTAppSlotViewController.m MTAppPickerViewController.m MTAppLibrary.m MTAppLauncher.m MTSceneHost.m MTNativeDockProbe.m
DFV1APreflight_CFLAGS = -fobjc-arc
DFV1APreflight_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
