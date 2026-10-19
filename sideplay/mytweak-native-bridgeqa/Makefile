THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES =
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = DFNativeDashboardBridgeQA
DFNativeDashboardBridgeQA_FILES = Tweak.x DFCPNativeBridgeQA.m DFNativeSidebarTrial.m ../mytweak-independent-v1a/prototype/MTCPBridgeContract.m ../mytweak-independent-v1a/prototype/MTCPCommandRelay.m ../mytweak-independent-v1a/prototype/MTCPRemoteLayer.m ../mytweak-independent-v1a/prototype/MTCPNativeChromeLayout.m ../mytweak-independent-v1a/prototype/MTCPDashboardOwner.m
DFNativeDashboardBridgeQA_CFLAGS = -fobjc-arc
DFNativeDashboardBridgeQA_FRAMEWORKS = UIKit Foundation QuartzCore
include $(THEOS_MAKE_PATH)/tweak.mk
