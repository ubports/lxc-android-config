#!/bin/sh

# Sometimes /etc/ssh isn't writable when this job starts. Work around that.
# For some reason we can't rely on 'mounted /etc/ssh', it doesn't always fire
check-writable() {
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
    check-writable
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -e /etc/ssh/ssh_host_dsa_key ]; then
    check-writable
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi