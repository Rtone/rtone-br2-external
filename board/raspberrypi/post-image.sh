#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

cp "${BINARIES_DIR}/rpi-firmware/cmdline.txt" "${BINARIES_DIR}/rpi-firmware/autoboot.txt"
echo "root=/dev/mmcblk0p5 rootwait console=tty1 console=serial0" >"${BINARIES_DIR}/cmdline-a.txt"
echo "root=/dev/mmcblk0p6 rootwait console=tty1 console=serial0" >"${BINARIES_DIR}/cmdline-b.txt"

rm -rf "${GENIMAGE_TMP}"

genimage \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

bmaptool create -o "${BINARIES_DIR}/sdcard.bmap" "${BINARIES_DIR}/sdcard.img"

exit $?
