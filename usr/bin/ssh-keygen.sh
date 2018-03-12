#!/bin/sh

# Sometimes /etc/ssh isn't writable when the ssh job starts. Also, for some 
# reason we can't rely on the 'mounted /etc/ssh' event, it doesn't always fire.
# This script works around both of those problems.
wait_for_writable() {
    while [ ! $WRITABLE ]; do
        touch /etc/ssh/testfile && {
            rm /etc/ssh/testfile
            WRITABLE=true
            break
        }
        sleep 1
    done
}

if [ ! -e /etc/ssh/ssh_host_rsa_key ]; then
    wait_for_writable
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -e /etc/ssh/ssh_host_dsa_key ]; then
    wait_for_writable
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi