################################################################################
#
# raspberrypi-firmware-systemd-generator
#
################################################################################

RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_VERSION = 7273665506b23c950a9c1855e9c7521ae1fb5848
RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_SITE = $(call github,gportay,raspberrypi-firmware-systemd-generator,$(RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_VERSION))
RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_LICENSE = LGPL-2.1+
RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_LICENSE_FILES = LICENSE

define RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) PREFIX=/usr DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))
