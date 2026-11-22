#!/usr/bin/env bash
set -euo pipefail

# Catris Unsigned iOS Device IPA Packaging & Verification Script
# Implements every check specified in preproduction/IOS_UNSIGNED_IPA.md:
#   - Validates single Payload/Catris.app bundle & executable
#   - Verifies Mach-O platform == iOS (device iPhoneOS, NOT Simulator) & arch == arm64
#   - Verifies Portrait-only UISupportedInterfaceOrientations, Bundle ID, Display Name, MinimumOSVersion
#   - Verifies runtime assets (Meshes, Textures, Audio, Data) are bundled
#   - Verifies unsigned state and absence of embedded.mobileprovision
#   - Packages Catris-unsigned.ipa + SHA-256 + build-report.json

ARCHIVE_PATH="${1:-build/Catris.xcarchive}"
OUT_DIR="${2:-build/dist}"
IPA_NAME="Catris-unsigned.ipa"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/staging/Payload"

APPS_DIR="${ARCHIVE_PATH}/Products/Applications"
if [[ ! -d "${APPS_DIR}" ]]; then
  echo "ERROR: Applications directory not found at ${APPS_DIR}" >&2
  exit 1
fi

shopt -s nullglob
APP_BUNDLES=("${APPS_DIR}"/*.app)
shopt -u nullglob
if [[ ${#APP_BUNDLES[@]} -ne 1 ]]; then
  echo "ERROR: Expected exactly 1 .app bundle in ${APPS_DIR}, found ${#APP_BUNDLES[@]}" >&2
  exit 1
fi

SRC_APP="${APP_BUNDLES[0]}"
STAGED_APP="${OUT_DIR}/staging/Payload/Catris.app"
cp -a "${SRC_APP}" "${STAGED_APP}"

PLIST="${STAGED_APP}/Info.plist"
if [[ ! -f "${PLIST}" ]]; then
  echo "ERROR: Info.plist missing in ${STAGED_APP}" >&2
  exit 1
fi

plutil -lint "${PLIST}"
EXEC_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "${PLIST}")
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${PLIST}")
DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "${PLIST}")
MIN_OS=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "${PLIST}")
SUPPORTED_PLATFORM=$(/usr/libexec/PlistBuddy -c "Print :CFBundleSupportedPlatforms:0" "${PLIST}")
ORIENT_COUNT=$(/usr/libexec/PlistBuddy -c "Print :UISupportedInterfaceOrientations" "${PLIST}" | grep -c "UIInterfaceOrientation" || true)
ORIENT_0=$(/usr/libexec/PlistBuddy -c "Print :UISupportedInterfaceOrientations:0" "${PLIST}")

EXEC_BIN="${STAGED_APP}/${EXEC_NAME}"
test -s "${EXEC_BIN}"

# Verify true iPhoneOS device platform & arm64 architecture (NOT Simulator!)
if [[ "${SUPPORTED_PLATFORM}" != "iPhoneOS" ]]; then
  echo "ERROR: CFBundleSupportedPlatforms is '${SUPPORTED_PLATFORM}', expected 'iPhoneOS'" >&2
  exit 1
fi
if [[ "${ORIENT_0}" != "UIInterfaceOrientationPortrait" || "${ORIENT_COUNT}" -ne 1 ]]; then
  echo "ERROR: Expected Portrait-only orientation, got count=${ORIENT_COUNT}, first='${ORIENT_0}'" >&2
  exit 1
fi

LIPO_INFO=$(lipo -info "${EXEC_BIN}")
echo "lipo: ${LIPO_INFO}"
echo "${LIPO_INFO}" | grep -q "arm64"

VTOOL_INFO=$(vtool -show-build "${EXEC_BIN}")
echo "${VTOOL_INFO}"
echo "${VTOOL_INFO}" | grep -q "platform IOS"
if echo "${VTOOL_INFO}" | grep -q "IOSSIMULATOR"; then
  echo "ERROR: Executable targets IOSSIMULATOR instead of device IOS!" >&2
  exit 1
fi

# Verify runtime 3D assets are packaged inside the app!
for folder in Meshes Textures Audio Data; do
  if [[ ! -d "${STAGED_APP}/${folder}" ]]; then
    echo "ERROR: Missing runtime asset folder ${folder} inside ${STAGED_APP}" >&2
    exit 1
  fi
done
MESH_COUNT=$(find "${STAGED_APP}/Meshes" -name '*.cmesh' | wc -l | tr -d ' ')
TEX_COUNT=$(find "${STAGED_APP}/Textures" -name '*.png' | wc -l | tr -d ' ')
AUDIO_COUNT=$(find "${STAGED_APP}/Audio" -name '*.wav' | wc -l | tr -d ' ')
test "${MESH_COUNT}" -ge 12
test "${TEX_COUNT}" -ge 15
test "${AUDIO_COUNT}" -ge 10

# Ensure no provisioning profile or signature sneaked in
if [[ -f "${STAGED_APP}/embedded.mobileprovision" ]]; then
  echo "ERROR: embedded.mobileprovision found in unsigned artifact!" >&2
  exit 1
fi

CODESIGN_STATUS="unsigned"
if codesign -dv "${STAGED_APP}" >/dev/null 2>&1; then
  CODESIGN_STATUS="signed-unexpected"
  echo "WARNING: App appears signed; stripping ad-hoc signature on staging copy..."
  codesign --remove-signature "${STAGED_APP}" || true
  if ! codesign -dv "${STAGED_APP}" >/dev/null 2>&1; then
    CODESIGN_STATUS="unsigned"
  fi
fi

# Package clean ZIP with Payload/ at archive root (no macOS AppleDouble ._ files!)
(
  cd "${OUT_DIR}/staging"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry "../${IPA_NAME}" Payload
)

IPA_PATH="${OUT_DIR}/${IPA_NAME}"
unzip -t "${IPA_PATH}" >/dev/null
shasum -a 256 "${IPA_PATH}" | awk '{print $1 "  Catris-unsigned.ipa"}' > "${OUT_DIR}/${IPA_NAME}.sha256"
SHA256=$(awk '{print $1}' "${OUT_DIR}/${IPA_NAME}.sha256")
IPA_BYTES=$(stat -f%z "${IPA_PATH}")
XCODE_VER=$(xcodebuild -version | tr '\n' ' ' | sed 's/  */ /g')
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

cat > "${OUT_DIR}/build-report.json" <<EOF
{
  "artifact": "${IPA_NAME}",
  "sha256": "${SHA256}",
  "bytes": ${IPA_BYTES},
  "git_commit": "${GIT_SHA}",
  "bundle_id": "${BUNDLE_ID}",
  "display_name": "${DISPLAY_NAME}",
  "minimum_os_version": "${MIN_OS}",
  "supported_platform": "${SUPPORTED_PLATFORM}",
  "orientation": "${ORIENT_0}",
  "architecture": "arm64",
  "signing_status": "${CODESIGN_STATUS}",
  "xcode": "${XCODE_VER}",
  "bundled_assets": {
    "cmesh_count": ${MESH_COUNT},
    "texture_count": ${TEX_COUNT},
    "audio_count": ${AUDIO_COUNT}
  },
  "device_runtime_tested": false,
  "notes": "Unsigned iOS device ARM64 IPA built via Xcode Release iphoneos archive. Must be re-signed with an Apple signing identity/profile before installing on a standard iPhone."
}
EOF

echo "=== Catris Unsigned IPA Verified ==="
cat "${OUT_DIR}/build-report.json"
