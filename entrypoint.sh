#! /bin/bash

echo "Entered entrypoint.sh"

# Make sure we have the profile sourced, it starts ssh-agent
source /etc/profile
# Add server SSH key for accesing git
ssh-add /root/.ssh/buildserver_rsa


# Prevent container from closing once this script is finished
while true; do sleep 1000; done
