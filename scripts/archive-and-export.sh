#!/bin/bash
set -euo pipefail

: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your Apple team ID}"
: "${PRODUCT_BUNDLE_IDENTIFIER:?Set PRODUCT_BUNDLE_IDENTIFIER to your unique bundle identifier}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
BUILD_ROOT="${PROJECT_ROOT}/build/signed-${EXPORT_METHOD}"
ARCHIVE_PATH="${BUILD_ROOT}/YuhunBox.xcarchive"
EXPORT_PATH="${BUILD_ROOT}/export"

case "${EXPORT_METHOD}" in
  development)
    EXPORT_OPTIONS="${PROJECT_ROOT}/ExportOptions/Development.plist"
    ;;
  ad-hoc)
    EXPORT_OPTIONS="${PROJECT_ROOT}/ExportOptions/AdHoc.plist"
    ;;
  *)
    echo "EXPORT_METHOD must be development or ad-hoc" >&2
    exit 2
    ;;
esac

/usr/bin/xcodebuild \
  -project "${PROJECT_ROOT}/YuhunBox.xcodeproj" \
  -scheme YuhunBox \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "${ARCHIVE_PATH}" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
  PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER}" \
  -allowProvisioningUpdates \
  clean archive

/bin/mkdir -p "${EXPORT_PATH}"
/usr/bin/xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS}" \
  -allowProvisioningUpdates

echo "Signed export created at: ${EXPORT_PATH}"


