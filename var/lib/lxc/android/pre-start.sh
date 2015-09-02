#!/bin/sh

if [ -e /android/system/boot/android-ramdisk.img ]; then
    INITRD=/android/system/boot/android-ramdisk.img
elif [ -e /boot/android-ramdisk.img ]; then
    rm -Rf $LXC_ROOTFS_PATH
    mkdir -p $LXC_ROOTFS_PATH
    INITRD=/boot/android-ramdisk.img
    cd $LXC_ROOTFS_PATH
    cat $INITRD | gzip -d | cpio -i
else
    exit 1
fi

# Create /dev/pts if missing
mkdir -p $LXC_ROOTFS_PATH/dev/pts

# Pass /sockets through
mkdir -p /dev/socket $LXC_ROOTFS_PATH/socket
mount -n -o bind,rw /dev/socket $LXC_ROOTFS_PATH/socket

# run config snippet scripts
run-parts /var/lib/lxc/android/pre-start.d || true

sed -i '/on early-init/a \    mkdir /dev/socket\n\    mount none /socket /dev/socket bind' $LXC_ROOTFS_PATH/init.rc

if [ "$INITRD" = "/android/system/boot/android-ramdisk.img" ]; then
    sed -i "/mount_all /d" $LXC_ROOTFS_PATH/init.*.rc
    sed -i "/on nonencrypted/d" $LXC_ROOTFS_PATH/init.rc

    rm -Rf $LXC_ROOTFS_PATH/vendor
    ln -s /system/vendor $LXC_ROOTFS_PATH/vendor

    for dir in /android/*; do
        mkdir -p $LXC_ROOTFS_PATH/$(basename $dir)
        mount -n -o bind,recurse $dir $LXC_ROOTFS_PATH/$(basename $dir)
    done
fi
