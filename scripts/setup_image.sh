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

set -xe

if [ "$#" -ne 1 ]; then
    echo "$0 <overlay-dir>"
    exit 1
fi

readonly OVERLAY_DIR="$1"

export readonly DEBIAN_FRONTEND="noninteractive"

function append {
  line=$1
  file=$2
  grep "^${line}" "${file}" || echo "${line}" >> "${file}"
}

# Enable SSH.
touch /boot/ssh

# Enable camera.
append "start_x=1" /boot/config.txt

# Enable desktop even when no monitor connected to HDMI.
append "hdmi_group=2" /boot/config.txt
append "hdmi_mode=51" /boot/config.txt
append "hdmi_force_hotplug=1" /boot/config.txt

# Disable display sleep.
append "@xset s noblank" /etc/xdg/lxsession/LXDE-pi/autostart
append "@xset s off"     /etc/xdg/lxsession/LXDE-pi/autostart
append "@xset -dpms"     /etc/xdg/lxsession/LXDE-pi/autostart

# Enable VNC.
ln -s /usr/lib/systemd/system/vncserver-x11-serviced.service /etc/systemd/system/multi-user.target.wants/vncserver-x11-serviced.service
systemctl start vncserver-x11-serviced

# Install debian packages.
append "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo libedgetp1-max libedgetpu/accepted-eula boolean true | debconf-set-selections

apt-get update && apt-get -y install \
  libedgetpu1-max \
  python3-pycoral \
  python3-tflite-runtime \
  python3-pyaudio \
  python3-opencv \
  libatlas-base-dev \
  thonny \
  zip \
  unzip

# tflite-support requires numpy >=1.19, but the deb for buster is 1.16.2,
# so here we get the latest build for buster from piwheels.org, which is 1.21.4,
# plus some other tflite-support dependencies
python3 -m pip install pip --upgrade
python3 -m pip install \
  pynput \
  'flatbuffers >= 1.12, <2' \
  'numpy == 1.21.4' \
  'absl-py >= 0.7.0' \
  'pybind11 >= 2.6.0'

# Manually install tflite-support because pip refuses to install an
# arch-specific wheel that doesn't match the current host system
wget https://files.pythonhosted.org/packages/b7/4e/91466173f63978e6db6d9ab1f78099db12c308ec8adb7441d75ac8a14a16/tflite_support-0.3.1-cp37-cp37m-manylinux2014_armv7l.whl \
  -P /tmp
LOCAL_PACKAGES="/usr/local/lib/python3.7/dist-packages"
mkdir -p "${LOCAL_PACKAGES}"
unzip -d "${LOCAL_PACKAGES}" \
    /tmp/tflite_support-0.3.1-cp37-cp37m-manylinux2014_armv7l.whl

# Install aiymakerkit library
# NOTE: RPI Imager will rename the "pi" home dir if user specifies new username
cd /home/pi/
git clone https://github.com/google-coral/aiy-maker-kit
python3 -m pip install ./aiy-maker-kit
bash aiy-maker-kit/examples/download_models.sh
bash aiy-maker-kit/projects/download_models.sh
chown -R pi:pi aiy-maker-kit
# Remove unecessary/confusing files
cd aiy-maker-kit
rm -rf aiymakerkit.egg-info .git build docs

# Change the wallpaper
mkdir -p /home/pi/.config/pcmanfm/LXDE-pi
sed "s:wallpaper=.*:wallpaper=/usr/share/rpd-wallpaper/aurora.jpg:" \
               /etc/xdg/pcmanfm/LXDE-pi/desktop-items-0.conf > \
               /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
chown -R pi:pi /home/pi/.config

# Copy overlay with script to add the IP address to desktop
tar -cf - -C "${OVERLAY_DIR}" --owner=pi --group=pi . | tar -xf - -C /
ln -s /opt/aiy/ipaddress.service /lib/systemd/system
systemctl enable systemd-networkd-wait-online.service
systemctl enable /opt/aiy/ipaddress.service
