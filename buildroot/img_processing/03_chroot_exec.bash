#!/bin/bash
#
# Execute chroot_script 
#

# Source environment folder paths
source ../build.env

chroot $WS/piroot /bash -c "./_chroot_script.bash"
