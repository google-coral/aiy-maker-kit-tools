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

if [[ "$#" -ne 1 ]]; then
  echo "$0 <image>" >&2
  exit 1
fi

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly IMAGE="$1"

read -d '' SCRIPT << EOF || true
groupadd --gid $(id -g) $(id -g -n);
useradd -m -e "" -s /bin/bash --gid $(id -g) --uid $(id -u) $(id -u -n);
passwd -d $(id -u -n);
echo "$(id -u -n) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers;
sudo -E -u $(id -u -n) /coral/scripts/build_image_native.sh /image;
EOF

docker run --rm --privileged -i $(tty -s && echo --tty) \
  --env RPIOS_CLEAN_TMP \
  --volume "${SCRIPT_DIR}/..":/coral\
  --volume "${IMAGE}":/image \
  "${DOCKER_IMAGE:-rpios-builder}" \
  /bin/bash -c "${SCRIPT}"

