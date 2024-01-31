#!/bin/bash

# Ansible inventory file
INVENTORY_FILE="hosts"

# SSH port
SSH_PORT="10056"

rm -rf $HOME/.ssh/id_rsa.pub

ssh-keygen -t rsa -b 4096




# Your SSH public key file
SSH_PUBLIC_KEY="$HOME/.ssh/id_rsa.pub"

# Loop through hosts in the inventory file under the [servers] group
while IFS= read -r HOST
do
  # Skip lines that start with '[' (group names) and empty lines
  if [[ $HOST =~ ^\[.*$|^$ ]]; then
    continue
  fi
  
  # Extract IP address from the line
  IP_ADDRESS=$(echo $HOST | awk '{print $1}')
  
  # Copy SSH public key to remote host
  ssh-copy-id -i $SSH_PUBLIC_KEY -p $SSH_PORT $IP_ADDRESS
done < "$INVENTORY_FILE"
