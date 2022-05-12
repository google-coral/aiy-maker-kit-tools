#!/usr/bin/env python3
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# On macOS, you might receive an error that "SSL: CERTIFICATE_VERIFY_FAILED"
# Simply run the following command to install the required certificates:
#     /Applications/Python\ 3.6/Install\ Certificates.command


import json
import sys
import urllib.request

URL = 'https://downloads.raspberrypi.org/os_list_imagingutility_v2.json'
OS_NAME = 'Raspberry Pi OS (32-bit)'


def extract_urls(root, result):
    if isinstance(root, dict):
        if 'name' in root and 'url' in root:
            result[root['name']] = root['url']
        else:
            for _, node in root.items():
                extract_urls(node, result)
    elif isinstance(root, list):
        for node in root:
            extract_urls(node, result)


def download_json(url):
    with urllib.request.urlopen(url) as f:
        return json.loads(f.read().decode('utf-8'))


def main(args):
    urls = {}
    extract_urls(download_json(URL), urls)
    print(urls[OS_NAME])


if __name__ == '__main__':
    sys.exit(main(sys.argv))
