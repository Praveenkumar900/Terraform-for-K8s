#!/bin/bash

# Update package lists
sudo apt-get update

# Install dependencies
sudo apt-get install -y gnupg software-properties-common

# Download and add HashiCorp GPG key
wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Verify key fingerprint (optional)
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update package lists again
sudo apt-get update

# Install Terraform
sudo apt-get install -y terraform

# Print success message
echo "Terraform installation complete!"
