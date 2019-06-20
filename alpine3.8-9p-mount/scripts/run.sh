#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

VMLINUZ=/Users/$USER/.slim/registry/alpine3.8-9p-mount/vmlinuz
INITRD=/Users/$USER/.slim/registry/alpine3.8-9p-mount/initrd

# Set 9pfs server path
# This is built from https://bitbucket.org/plan9-from-bell-labs/u9fs/src/default/ -- there are some go 9p servers that might be better.
EXE=$SCRIPTPATH/u9fs

# Update template variables (this should all be nuked and replaced with mustache/node.js script)
cp 9pfs.plist.template 9pfs.plist

plutil -replace Sockets.Listeners.SockPathName -string /Users/$USER/.slim/sockets/slimshare.socket 9pfs.plist 
plutil -replace Program            -string $EXE  9pfs.plist
plutil -remove ProgramArguments.0                9pfs.plist 
plutil -replace ProgramArguments.0 -string $EXE  9pfs.plist
plutil -remove ProgramArguments.6                9pfs.plist 
plutil -replace ProgramArguments.6 -string $USER 9pfs.plist

if ! `launchctl list | grep "com.slim.u9fs." > /dev/null`; then
    echo "Starting u9fs server"
    launchctl load $SCRIPTPATH/9pfs.plist
fi

SOCKETDIR=/Users/$USER/.slim/sockets
mkdir -p $SOCKETDIR

SHARE="-s 3,virtio-9p,path=$SOCKETDIR/slimshare.socket,tag=shared"

sudo hyperkit -m 2G -s 0:0,hostbridge -s 31,lpc -s 2:0,virtio-net -l com1,stdio $SHARE -f kexec,$VMLINUZ,$INITRD,"modules=virtio_net console=ttyS0"
