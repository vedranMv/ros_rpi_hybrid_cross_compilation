#!/bin/bash
#
# Prepare chroot environemnt: copy needed binaries and their
# dependencies to workspace 
#

# Source environment folder paths
source ../build.env

# Create directories inside chroot for new libraries
mkdir $WS/piroot/lib64
mkdir $WS/piroot/lib/x86_64-linux-gnu

# Copy library dependencies for the few commands used in this chroot
cp /lib/x86_64-linux-gnu/libtinfo.so.5 $WS/piroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libdl.so.2 $WS/piroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libc.so.6 $WS/piroot/lib/x86_64-linux-gnu/
cp /lib64/ld-linux-x86-64.so.2 $WS/piroot/lib64/
cp /lib/x86_64-linux-gnu/libselinux.so.1 $WS/piroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libacl.so.1 $WS/piroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libattr.so.1 $WS/piroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libpcre.so.3 $WS/piroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libdl.so.2 $WS/piroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libpthread.so.0 $WS/piroot/lib/x86_64-linux-gnu/

# Copy required executables
cp /bin/bash $WS/piroot
cp /bin/cp $WS/piroot
cp /usr/bin/find $WS/piroot
cp /bin/ls $WS/piroot

# Copy script to be run in chroot
cp $IMG_PROC/_chroot_script.bash $WS/piroot
