#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

cp "${BOARD_DIR}/rel-ca.pem" "${BOARD_DIR}/release-1.cert.pem" "${BOARD_DIR}/release-1.pem" "${BINARIES_DIR}"

rm -rf "${GENIMAGE_TMP}"

genimage \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?
