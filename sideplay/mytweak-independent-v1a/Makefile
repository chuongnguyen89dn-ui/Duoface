THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = SpringBoard CarPlay CarPlayApp
include $(THEOS)/makefiles/common.mk

# Independent CarPlay Dashboard context observer: no Dock class hook and no painted mock sidebar.
TWEAK_NAME = DFV1APreflight
DFV1APreflight_FILES = V1ATweak.x MTPreflight.m MTTrialLog.m MTBridgeCoordinator.m MTBridgeRootViewController.m MTSplitContainerViewController.m MTAppSlotViewController.m MTAppPickerViewController.m MTAppLibrary.m MTAppLauncher.m MTSceneHost.m MTDashboardContext.m MTDashboardUsableRect.m
DFV1APreflight_CFLAGS = -fobjc-arc
DFV1APreflight_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
