#!/bin/bash
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

if [[ "$#" -ne 2 ]]; then
  echo "$0 <out_dir> <project_name>" >&2
  exit 1
fi

readonly OUT_DIR="$1"
readonly NAME="$2"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD_SCRIPTS_DIR="${SCRIPT_DIR}/../scripts/"

# WARNING: As of March, 2022, the Bullseye version of RPI OS is not compatible
# due to changes in the camera framework.
readonly RASPBIAN_IMAGE_URL=${RASPBIAN_IMAGE_URL:-https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-05-28/2021-05-07-raspios-buster-armhf.zip}
#readonly RASPBIAN_IMAGE_URL=${RASPBIAN_IMAGE_URL:-$(python3 ${SCRIPT_DIR}/latest_rpios.py)}
readonly RASPBIAN_IMAGE=${RASPBIAN_IMAGE_URL##*/}
readonly BUILD_ENGINE="${BUILD_ENGINE:-docker}"

if [[ "$OSTYPE" == "darwin"* ]]; then
  readonly MD5SUM=gmd5sum
  readonly SHA256SUM=gsha256sum
else
  readonly MD5SUM=md5sum
  readonly SHA256SUM=sha256sum
fi

mkdir -p "${OUT_DIR}"

# Download image zip
if ! ls "${OUT_DIR}/${RASPBIAN_IMAGE}"; then
  pushd "$(mktemp -d -t aiy-download.XXXXXXXXXX)"
  curl -O "${RASPBIAN_IMAGE_URL}" \
    -O "${RASPBIAN_IMAGE_URL}.sha256"
  if "${SHA256SUM}" -c "${RASPBIAN_IMAGE}.sha256"; then
    mv "${RASPBIAN_IMAGE}" "${OUT_DIR}"
  else
    echo "Image checksum check failed" >&2
    exit 1
  fi
  popd
fi

# Extract image zip (allow one unique build per day)
readonly IMAGE="${OUT_DIR}/${NAME}-$(date +%Y-%m-%d).img"
if [[ -f "${IMAGE}" ]]; then
  rm "${IMAGE}"*
fi
time unzip -p "${OUT_DIR}/${RASPBIAN_IMAGE}" >"${IMAGE}"

# Build image.
"${BUILD_SCRIPTS_DIR}/build_image_${BUILD_ENGINE}.sh" "${IMAGE}"

echo "Image ready: ${IMAGE}"

# Compress image.
xz -3 -k "${IMAGE}"
"${SHA256SUM}" "${IMAGE}.xz" >"${IMAGE}.xz.sha256"
"${MD5SUM}" "${IMAGE}.xz" >"${IMAGE}.xz.md5"
