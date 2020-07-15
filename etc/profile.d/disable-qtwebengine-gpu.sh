#!/bin/sh
# Disable the GPU for QtWebEngine on Android-based devices
# This file is part of lxc-android-config
export QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu --disable-viz-display-compositor"
