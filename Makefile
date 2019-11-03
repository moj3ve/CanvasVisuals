ARCHS = armv7s arm64 arm64e
FINALPACKAGE=1

THEOS_DEVICE_IP=192.168.0.20

SHARED_CFLAGS = -fobjc-arc
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CanvasVisualsDL
CanvasVisualsDL_FILES = CanvasVisualsDL.xm MBProgressHUD.m ALAssetsLibrary+CustomPhotoAlbum.m UIColor+Hexadecimal.m

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 Spotify"
	install.exec "open -9 Spotify"