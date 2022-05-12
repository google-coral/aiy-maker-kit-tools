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

function shell_image {
  sudo PYTHONDONTWRITEBYTECODE=yes "${SCRIPT_DIR}/shell_image.py" "$@"
}

function expand_image {
  sudo PYTHONDONTWRITEBYTECODE=yes "${SCRIPT_DIR}/expand_image.py" "$@"
}

# Resize image if needed.
if ! shell_image "${IMAGE}" "ls /tmp/resized"; then
  expand_image --expand-bytes $((500*1024*1024)) "${IMAGE}"
  shell_image "${IMAGE}" "touch /tmp/resized"
fi

# Run image setup script.
shell_image \
    --mount "${SCRIPT_DIR}/../overlay:/overlay" \
    --arg /overlay \
    "${IMAGE}" < "${SCRIPT_DIR}/setup_image.sh"

# Clean /tmp.
if [[ -n "${RPIOS_CLEAN_TMP}" ]]; then
  shell_image "${IMAGE}" "rm -f /tmp/*"
fi
