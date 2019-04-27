#!/bin/bash
#
# Create directory structure and copy important data from the 
# OS image locally to workspace. First argument is path to
# the mount folder of the SD-card
#

# Source environment folder paths
source ../build.env

# Remove existing piroot
rm $WS/piroot -rf
mkdir $WS/piroot

# Make directories for copying data directly form image
mkdir $WS/piroot/lib_orig
mkdir $WS/piroot/opt_orig
mkdir $WS/piroot/usr_orig
mkdir $WS/piroot/lib
mkdir $WS/piroot/opt
mkdir $WS/piroot/usr

#Copy riectories form image
cp -r $1/lib/. $WS/piroot/lib_orig
cp -r $1/usr/. $WS/piroot/opt_orig
cp -r $1/usr/. $WS/piroot/usr_orig

