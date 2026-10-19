TARGET = iphone:clang:latest:16.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless
include $(THEOS)/makefiles/common.mk
APPLICATION_NAME = MTDuoFaceShell
MTDuoFaceShell_FILES = MTDuoFaceShell.m
MTDuoFaceShell_FRAMEWORKS = UIKit Foundation
MTDuoFaceShell_CFLAGS = -fobjc-arc
MTDuoFaceShell_INSTALL_PATH = /Applications
include $(THEOS_MAKE_PATH)/application.mk
