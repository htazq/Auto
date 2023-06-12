#!/bin/bash

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
  echo "Docker is already installed."
  exit 0
fi

# Check if system is Debian or Ubuntu
if [[ $(lsb_release -is) == "Debian" ]]; then
  # Update system packages
  sudo apt update
  sudo apt upgrade -y

  # Install required packages
  sudo apt install -y curl gnupg2 software-properties-common

  # Add Docker GPG key
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # Add Docker APT repository
  echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Update package list
  sudo apt update

  # Install Docker and Docker Compose
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose

  # Start Docker service and set it to start automatically at boot
  sudo systemctl start docker
  sudo systemctl enable docker

  # Verify installation
  docker --version
  docker-compose --version

elif [[ $(lsb_release -is) == "Ubuntu" ]]; then
  # Update system packages
  sudo apt update
  sudo apt upgrade -y

  # Install required packages
  sudo apt install -y curl gnupg2 software-properties-common

  # Add Docker GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # Add Docker APT repository
  echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Update package list
  sudo apt update

  # Install Docker and Docker Compose
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose

  # Start Docker service and set it to start automatically at boot
  sudo systemctl start docker
  sudo systemctl enable docker

  # Verify installation
  docker --version
  docker-compose --version

elif [[ $(cat /etc/centos-release | grep -o 'CentOS' | wc -l) -eq 1 ]]; then
  # Install required packages
  sudo yum install -y yum-utils device-mapper-persistent-data lvm2

  # Add Docker YUM repository
  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  # Install Docker and Docker Compose
  sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose

  # Start Docker service and set it to start automatically at boot
  sudo systemctl start docker
  sudo systemctl enable docker

  # Verify installation
  docker --version
  docker-compose --version

else
  echo "Unsupported operating system."
  exit 1
fi
