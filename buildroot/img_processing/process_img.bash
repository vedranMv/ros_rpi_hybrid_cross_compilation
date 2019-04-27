#!/bin/bash

# Source environment folder paths
source ../build.env

# Check argument validity
if (( $# != 1 )); then
    echo "Illegal number of arguments"
    echo "Usage: process_img <path_to_root_dir_of_image>"
    exit 0
fi

# Rock'n'roll
printf "Copying data from mounted directory..."
$IMG_PROC/01_dir_extraction.bash $1
printf "done\n"

printf "Prepring environment for chroot..."
$IMG_PROC/02_chroot_prep.bash
printf "done\n"

printf "Executing the script in chroot"...
$IMG_PROC/03_chroot_exec.bash
printf "done\n"

printf "Housekeeping..."
$IMG_PROC/04_cleanup.bash
printf "done\n"

printf "\nYour environment is now ready for crosscompiling\n"
