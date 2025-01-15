################################################################################
#
# raspberrypi-firmware-rauc-bootloader-backend
#
################################################################################

RASPBERRYPI_FIRMWARE_RAUC_BOOTLOADER_BACKEND_VERSION = e30b1e9772d02c9ef1640c7d5fb3f9c1f7eb9217
RASPBERRYPI_FIRMWARE_RAUC_BOOTLOADER_BACKEND_SITE = $(call github,Rtone,raspberrypi-firmware-rauc-bootloader-backend,$(RASPBERRYPI_FIRMWARE_RAUC_BOOTLOADER_BACKEND_VERSION))
RASPBERRYPI_FIRMWARE_RAUC_BOOTLOADER_BACKEND_LICENSE = LGPL-2.1+
RASPBERRYPI_FIRMWARE_RAUC_BOOTLOADER_BACKEND_LICENSE_FILES = LICENSE

define RASPBERRYPI_FIRMWARE_RAUC_BOOTLOADER_BACKEND_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) PREFIX=/usr DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))
