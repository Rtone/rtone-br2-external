################################################################################
#
# rpi-eeprom
#
################################################################################

RPI_EEPROM_VERSION = 54d9c333a9d39941b4fc881275f433821c7b5cde
RPI_EEPROM_SITE = $(call github,raspberrypi,rpi-eeprom,$(RPI_EEPROM_VERSION))
RPI_EEPROM_LICENSE = BSD-3-Clause
RPI_EEPROM_LICENSE_FILES = LICENSE

RPI_EEPROM_FIRMWARES = $(if $(BR2_PACKAGE_RPI_EEPROM_BCM2711), 2711) \
		       $(if $(BR2_PACKAGE_RPI_EEPROM_BCM2712), 2712)

define RPI_EEPROM_INSTALL_FIRMWARES
	$(INSTALL) -d $(TARGET_DIR)/lib/firmware/raspberrypi/
	$(foreach f,$(RPI_EEPROM_FIRMWARES), \
		cp -dprf $(@D)/firmware-$f $(TARGET_DIR)/lib/firmware/raspberrypi/bootloader-$f
	)
endef

define RPI_EEPROM_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/rpi-eeprom-config $(TARGET_DIR)/bin/rpi-eeprom-config
	$(INSTALL) -D -m 0755 $(@D)/rpi-eeprom-digest $(TARGET_DIR)/bin/rpi-eeprom-digest
	$(INSTALL) -D -m 0755 $(@D)/rpi-eeprom-update $(TARGET_DIR)/bin/rpi-eeprom-update
	$(INSTALL) -D -m 0644 $(@D)/rpi-eeprom-update-default $(TARGET_DIR)/etc/default/rpi-eeprom-update
	$(RPI_EEPROM_INSTALL_FIRMWARES)
endef

$(eval $(generic-package))
