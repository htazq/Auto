#!/bin/bash

# Ansible inventory file
INVENTORY_FILE="hosts"

# SSH port
SSH_PORT="10056"

# Your SSH public key file
SSH_PUBLIC_KEY="$HOME/.ssh/id_rsa.pub"

# Loop through hosts in the inventory file
while IFS= read -r HOST
do
  # Skip lines that start with '[' (group names) and empty lines
  if [[ $HOST =~ ^\[.*$|^$ ]]; then
    continue
  fi
  
  # Extract IP address and additional information from the line
  IP_ADDRESS=$(echo $HOST | awk '{print $1}')
  # You can extract additional information like hostname or alias using awk or other tools
  
  # Remove existing host key entry for the IP address and port
  ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[${IP_ADDRESS}]:${SSH_PORT}"
  
  # Generate SSH key pair if not already generated
  if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
    ssh-keygen -t rsa -b 4096
  fi
  
  # Copy SSH public key to remote host
  ssh-copy-id -i "$SSH_PUBLIC_KEY" -p "$SSH_PORT" "$IP_ADDRESS"
done < "$INVENTORY_FILE"
