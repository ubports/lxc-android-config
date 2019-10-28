#!/bin/sh -e

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

# Determine correct Android library path
# FIXME: is this appropriate?
BITS="$(dpkg-architecture -qDEB_BUILD_ARCH_BITS)"
if [ "$BITS" = 32 ]; then
  ANDROID_LIB_PREFIX="/system/lib"
else
  ANDROID_LIB_PREFIX="/system/lib64"
fi

GST_ANDROID_LIB="${ANDROID_LIB_PREFIX}/libdroidmedia.so"
AAL_ANDROID_LIB="${ANDROID_LIB_PREFIX}/libcamera_compat_layer.so"

UBUNTU_LIB_PREFIX="/usr/lib/$(dpkg-architecture -q DEB_BUILD_MULTIARCH)/qt5/plugins/mediaservice"
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
  ANDROID_MAJOR="$(getprop ro.build.version.release|cut -f1 -d'.')"
  if [ "$ANDROID_MAJOR" -ge 7 ]; then
    # We prefer gst-droid on Android 7 and up because Halium 7
    # doesn't have the patch required for audio in video recording.
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
