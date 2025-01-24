#
# Copyright 2023-2025 Gaël PORTAY
#           2023-2025 Rtone
#
# SPDX-License-Identifier: GPL-2.0-only
#

override BR2_EXTERNAL += $(CURDIR)
O ?= $(CURDIR)/output

.PHONY: _all
_all: all

.PRECIOUS: buildroot
buildroot:
	git clone https://git.buildroot.net/buildroot $@

.PHONY: start-qemu
start-qemu:
	$(O)/images/start-qemu.sh --serial-only

%: | buildroot
	$(MAKE) -C buildroot BR2_EXTERNAL+="$(CURDIR)" $@
