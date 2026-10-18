TARGET := iphone:clang:latest:16.0
ARCHS := arm64
THEOS_PACKAGE_SCHEME := rootless
include $(THEOS)/makefiles/common.mk
TWEAK_NAME := DuoFaceSidePlayDisplayQA
DuoFaceSidePlayDisplayQA_FILES := Tweak.xm ../native12-display/DFSPNativeFrame.m
DuoFaceSidePlayDisplayQA_CFLAGS := -fobjc-arc -Wall -Wextra
DuoFaceSidePlayDisplayQA_FRAMEWORKS := UIKit Foundation
include $(THEOS_MAKE_PATH)/tweak.mk
