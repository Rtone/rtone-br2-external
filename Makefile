#
# Copyright 2023 Gaël PORTAY
#           2023 Rtone
#
# SPDX-License-Identifier: GPL-2.0-only
#

override BR2_EXTERNAL += $(CURDIR)

.PHONY: _all
_all: all

buildroot:
	git clone https://git.buildroot.net/buildroot $@

%: | buildroot
	$(MAKE) -C buildroot O?="$(CURDIR)/output" BR2_EXTERNAL+="$(CURDIR)" $@
