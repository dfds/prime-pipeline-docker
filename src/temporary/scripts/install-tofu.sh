#!/bin/bash

ZIPFILE=tofu_${OPENTOFU_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip
SHA256SUM_FILE=tofu_${OPENTOFU_VERSION}_SHA256SUMS

CHECKSUM=$(sha256sum "${ZIPFILE}" | cut -f 1 -d ' ')
EXPECTED_CHECKSUM=$(grep "${ZIPFILE}" tofu_*_SHA256SUMS | cut -f 1 -d ' ')

if [[ "${CHECKSUM}" = "${EXPECTED_CHECKSUM}" ]]; then
    unzip tofu_${OPENTOFU_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip
    mv tofu /usr/local/bin
    chmod +x /usr/local/bin/tofu
    tofu -install-autocomplete
else
    exit 1
fi
