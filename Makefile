ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = TinderGhost

TinderGhost_FILES = Tweak.m \
	OWSContainerManager.m \
	OWSFloatingButton.m \
	OWSLocationSpoofer.m \
	OWSDeviceSpoofer.m \
	OWSMapPickerViewController.m

TinderGhost_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
TinderGhost_FRAMEWORKS = Foundation UIKit CoreLocation MapKit QuartzCore
TinderGhost_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/library.mk
