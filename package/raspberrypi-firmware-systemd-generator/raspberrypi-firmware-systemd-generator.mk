################################################################################
#
# raspberrypi-firmware-systemd-generator
#
################################################################################

RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_VERSION = 3139d6263259b3a4acec3b37b42fbdcf4de38052
RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_SITE = $(call github,Rtone,raspberrypi-firmware-systemd-generator,$(RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_VERSION))
RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_LICENSE = LGPL-2.1+
RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_LICENSE_FILES = LICENSE

define RASPBERRYPI_FIRMWARE_SYSTEMD_GENERATOR_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) PREFIX=/usr DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))
