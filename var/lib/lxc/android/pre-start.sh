#!/bin/sh

if [ -f "/android/system/boot/android-ramdisk.img" ]; then
    # Halium 7 or below where ramdisk is extracted to tmpfs
    for mountpoint in /android/*; do
        mount_name=`basename $mountpoint`
        desired_mount=$LXC_ROOTFS_PATH/$mount_name

        # Remove symlinks, for example bullhead has /vendor -> /system/vendor
        [ -L $desired_mount ] && rm $desired_mount

        [ -d $desired_mount ] || mkdir $desired_mount
        mount --bind $mountpoint $desired_mount
    done

    mknod -m 666 $LXC_ROOTFS_PATH/dev/null c 1 3

    # Create /dev/pts if missing
    mkdir -p $LXC_ROOTFS_PATH/dev/pts

    # Pass /sockets through
    mkdir -p /dev/socket $LXC_ROOTFS_PATH/socket
    mount -n -o bind,rw /dev/socket $LXC_ROOTFS_PATH/socket

    rm $LXC_ROOTFS_PATH/sbin/adbd

    sed -i '/on early-init/a \    mkdir /dev/socket\n\    mount none /socket /dev/socket bind' $LXC_ROOTFS_PATH/init.rc

    sed -i "/mount_all /d" $LXC_ROOTFS_PATH/init.*.rc
    sed -i "/swapon_all /d" $LXC_ROOTFS_PATH/init.*.rc
    sed -i "/on nonencrypted/d" $LXC_ROOTFS_PATH/init.rc

    # Config snippet scripts
    run-parts /var/lib/lxc/android/pre-start.d || true
else
    # Halium 9
    mkdir -p /dev/__properties__
    mkdir -p /dev/socket
fi
