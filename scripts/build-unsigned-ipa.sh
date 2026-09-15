#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_ROOT="${PROJECT_ROOT}/build/unsigned"
DERIVED_DATA="${BUILD_ROOT}/DerivedData"
APP_PATH="${DERIVED_DATA}/Build/Products/Release-iphoneos/YuhunBox.app"
STAGING_PATH="${BUILD_ROOT}/staging"
IPA_PATH="${BUILD_ROOT}/YuhunBox-unsigned.ipa"

/usr/bin/xcodebuild \
  -project "${PROJECT_ROOT}/YuhunBox.xcodeproj" \
  -scheme YuhunBox \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "${DERIVED_DATA}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean build

test -d "${APP_PATH}"
/bin/rm -rf "${STAGING_PATH}"
/bin/mkdir -p "${STAGING_PATH}/Payload"
/usr/bin/ditto "${APP_PATH}" "${STAGING_PATH}/Payload/YuhunBox.app"
/bin/rm -f "${IPA_PATH}"
(cd "${STAGING_PATH}" && /usr/bin/zip -qry "${IPA_PATH}" Payload)

echo "Unsigned IPA created at: ${IPA_PATH}"
echo "This IPA must be re-signed by a sideloading tool before iOS can install it."


