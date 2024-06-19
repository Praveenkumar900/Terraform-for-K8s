#!/bin/bash

# Uninstall the previously installed awscli (if present)
sudo apt-get remove awscli -y

# Download the AWS CLI installer
curl -L "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install unzip (if not already installed)
if ! command -v unzip &> /dev/null; then
  sudo apt-get install unzip -y
fi

# Extract the downloaded installer
unzip awscliv2.zip

# Install the AWS CLI (using sudo for elevated privileges)
sudo ./aws/install

# Print success message (optional)
echo "AWS CLI installation complete!"
