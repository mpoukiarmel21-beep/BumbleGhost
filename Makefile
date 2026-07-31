ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = BumbleGhost

BumbleGhost_FILES = Tweak.m \
	OWSContainerManager.m \
	OWSFloatingButton.m \
	OWSLocationSpoofer.m \
	OWSDeviceSpoofer.m

BumbleGhost_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
BumbleGhost_FRAMEWORKS = Foundation UIKit CoreLocation QuartzCore
BumbleGhost_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/library.mk
