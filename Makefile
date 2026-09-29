TARGET := iphone:clang:latest:14.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = SafeCache

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = SafeCache
SafeCache_FILES = $(wildcard SafeCache/*.m)
SafeCache_FRAMEWORKS = UIKit Foundation
SafeCache_CFLAGS = -fobjc-arc
SafeCache_CODESIGN_FLAGS = -SSafeCache.entitlements
SafeCache_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk

after-stage::
	@rm -rf Payload SafeCache.tipa
	@mkdir -p Payload
	@cp -a $(THEOS_STAGING_DIR)/Applications/SafeCache.app Payload/
	@zip -qry SafeCache.tipa Payload
	@rm -rf Payload
	@echo "Built SafeCache.tipa"
