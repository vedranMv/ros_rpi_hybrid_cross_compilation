#/bin/bash
#
# Execute chroot script
#

# Copy *_orig directories to * by converting symilnks to actual files
./cp -rl /lib_orig/. /lib
./cp -rl /usr_orig/. /usr
