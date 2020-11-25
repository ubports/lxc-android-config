#!/bin/bash -e

# Copyright (C) 2019 UBports foundation.
# Author(s): Ratchanan Srirattanamet <ratchanan@ubports.com>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3, as published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranties of MERCHANTABILITY,
# SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script make sure that the system loads the correct Qt plugin
# for camera, based on available Android library & Android version.

# Determine the phone's architecture. This could also be done using dpkg-
# architecture, but that's not available in the phone image.

MULTIARCH_MAP="\
armhf arm-linux-gnueabihf 32
arm64 aarch64-linux-gnu 64
i386 i386-linux-gnu 32
amd64 x86_64-linux-gnu 64
"

HOST_DEBARCH="$(dpkg --print-architecture)"

while read -r DEBARCH MULTIARCH BITS; do
  if [ "$DEBARCH" = "$HOST_DEBARCH" ]; then
    break
  fi
done <<< "$MULTIARCH_MAP" # bash-specific

if [ "$DEBARCH" != "$HOST_DEBARCH" ]; then
  echo "Cannot find multiarch triplet for \"$HOST_DEBARCH\". Update this script."
  exit 1
fi

# Determine correct Android library path
if [ "$BITS" = 32 ]; then
  ANDROID_LIB_PREFIX="/system/lib"
else
  ANDROID_LIB_PREFIX="/system/lib64"
fi

GST_ANDROID_LIB="${ANDROID_LIB_PREFIX}/libdroidmedia.so"
AAL_ANDROID_LIB="${ANDROID_LIB_PREFIX}/libcamera_compat_layer.so"

UBUNTU_LIB_PREFIX="/usr/lib/${MULTIARCH}/qt5/plugins/mediaservice"
GST_UBUNTU_LIB="${UBUNTU_LIB_PREFIX}/libgstcamerabin.so"
AAL_UBUNTU_LIB="${UBUNTU_LIB_PREFIX}/libaalcamera.so"

# Allow the override to be read from Android property. The wait is just-in-case.
# We should be called after the "android" event anyway.
while [ ! -e /dev/socket/property_service ]; do
  sleep 0.1
done

PLUGIN="$(getprop ro.ubuntu.camera_plugin)"
case "$PLUGIN" in
  aal|gst|"")
    ;;
  *)
    echo "Plugin \"${PLUGIN}\" is not a valid plugin. Override not used."
    PLUGIN=""
esac

if [ -z "$PLUGIN" ]; then
  # If one lib is missing we need to use the other one. This helps for older
  # Halium port that's been built before Droidmedia is included by default.
  if ! [ -e $GST_ANDROID_LIB ]; then
    PLUGIN="aal"
  elif ! [ -e $AAL_ANDROID_LIB ]; then
    PLUGIN="gst"
  fi
fi

if [ -z "$PLUGIN" ]; then
  # Well, it's a bit complicated. Initially Halium 7 and up doesn't have the
  # required patch for video recording with audio on aal plugin. But then
  # Nikita (@NotKit) comes in and forward-port the patch for Halium 9, so now
  # only Halium 7 doesn't have the patch. Also, there's a problem with 64-bit
  # devices using droidmedia that prevents video recording completely. Although
  # on aal plugin video recording it can completely freeze too, so it's better
  # to fix the future then try to fix the past.
  ANDROID_MAJOR="$(getprop ro.build.version.release|cut -f1 -d'.')"
  if [ "$ANDROID_MAJOR" = 7 ]; then
    PLUGIN="gst"
  else
    PLUGIN="aal"
  fi
fi

case "$PLUGIN" in
  aal)
    mount -o bind /dev/null "$GST_UBUNTU_LIB"
    ;;
  gst)
    mount -o bind /dev/null "$AAL_UBUNTU_LIB"
    ;;
esac

echo "Successfully make Qt uses \"$PLUGIN\" as the camera plugin."
