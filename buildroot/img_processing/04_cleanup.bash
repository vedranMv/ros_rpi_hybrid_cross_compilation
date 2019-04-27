#!/bin/bash

# Source environment folder paths
source ../build.env

rm $WS/piroot/bash
rm $WS/piroot/ls
rm $WS/piroot/cp
rm $WS/piroot/find

rm $WS/piroot/lib64 -rf
rm rm $WS/piroot/lib/x86_64 -rf

rm $WS/piroot/lib_orig -rf
rm $WS/piroot/usr_orig -rf

rm $WS/piroot/_chroot_script.bash
