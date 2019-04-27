#!/bin/bash

# Source environment variables
source buildroot/build.env

# Create container from image, use shared directory in /usr/local/build
# Make sure that shared directory is updated in build.env
CONT_ID=$(docker create -h buildserver -v ${WS}:${WS} vedranmv/buildserver:latest)
echo $CONT_ID

# Find the name of the container with the returned ID
CONT_NAME=$(docker ps -af "id=${CONT_ID}" | tail -n 1 | awk '{print $NF}')

# Copy entrypoint file to the container
docker cp entrypoint.sh ${CONT_ID}:entrypoint.sh

# Copy keys for git server
docker cp ssh/buildserver_rsa ${CONT_ID}:/root/.ssh
docker cp ssh/buildserver_rsa.pub ${CONT_ID}:/root/.ssh
docker cp ssh/known_hosts ${CONT_ID}:/root/.ssh

# Patch .bashrc to source build.env 
echo "source $WS/build.env" >> profile/.bashrc_patched

# Copy user profile files
docker cp profile/profile ${CONT_ID}:/etc/profile
docker cp profile/.bashrc_patched ${CONT_ID}:/root/.bashrc

rm profile/.bashrc_patched

# Copy buildroot folder content to actual build root
docker cp buildroot/build.env ${CONT_ID}:${WS}
docker cp buildroot/toolchain.cmake ${CONT_ID}:${WS}
docker cp buildroot/bin ${CONT_ID}:${WS}
docker cp buildroot/img_processing ${CONT_ID}:${WS}

# Start container in the background
docker start ${CONT_NAME}

# Use 'docker exec -ti ${CONT_NAME} bash' to log into the container
