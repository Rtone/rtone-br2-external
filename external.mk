#
# Copyright 2023 Gaël PORTAY
#           2023 Rtone
#
# SPDX-License-Identifier: GPL-2.0-only
#

.PHONY: nothing
nothing:

ifneq ($(BUILD_DIR),)
.PHONY: rm-build
rm-build:
	test -d "$(BUILD_DIR)"
	rm -rf $(BUILD_DIR)/*/*

ifneq ($(BASE_TARGET_DIR),)
.PHONY: rm-target
rm-target:
	test -d "$(BASE_TARGET_DIR)"
	rm -rf $(BASE_TARGET_DIR)
	test -d "$(BUILD_DIR)"
	rm -rf $(BUILD_DIR)/*/.stamp_target_installed
endif
endif

ifneq ($(BASE_TARGET_DIR),)
define bmaptool-copy
bmaptool-copy-$(1):
	test -b "/dev/$(1)"
	sudo bmaptool copy $$(BINARIES_DIR)/sdcard.img /dev/$(1)
endef
$(foreach devname,$(shell ( cd /sys/block && ls )),$(eval $(call bmaptool-copy,$(devname))))
endif
