THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MyTweak
MyTweak_FILES = Tweak.x MTBridgeCoordinator.m MTBridgeWindow.m \
	MTBridgeRootViewController.m MTSplitContainerViewController.m \
	MTAppSlotViewController.m MTAppPickerViewController.m \
	MTAppLibrary.m MTAppLauncher.m MTSceneHost.m
MyTweak_CFLAGS = -fobjc-arc
MyTweak_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
