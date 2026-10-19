THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = SpringBoard
include $(THEOS)/makefiles/common.mk
# Combined v1a + v1b + v1c, one in-place upgrade from v1a. No vendor runtime.
TWEAK_NAME = DFV1APreflight
DFV1APreflight_FILES = V1ATweak.x MTPreflight.m MTTrialLog.m MTBridgeCoordinator.m MTBridgeRootViewController.m MTSplitContainerViewController.m MTAppSlotViewController.m MTAppPickerViewController.m MTAppLibrary.m MTAppLauncher.m MTSceneHost.m
DFV1APreflight_CFLAGS = -fobjc-arc
DFV1APreflight_FRAMEWORKS = UIKit Foundation
include $(THEOS_MAKE_PATH)/tweak.mk
