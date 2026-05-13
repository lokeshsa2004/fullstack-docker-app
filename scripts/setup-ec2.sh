#!/bin/bash

# EC2 Setup Script for Portfolio Manager
# Run this once on your EC2 instance to prepare it for deployment

set -e

echo "======================================"
echo "Portfolio Manager EC2 Setup"
echo "======================================"

# Update system
echo "Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y -qq curl
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add current user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
echo "Installing Docker Compose..."
sudo apt-get install -y -qq docker-compose-plugin

# Create app directory
echo "Creating app directory..."
sudo mkdir -p /opt/portfolio-app
sudo chown $USER:$USER /opt/portfolio-app
chmod 755 /opt/portfolio-app

# Verify installations
echo "======================================"
echo "Verifying installations..."
docker --version
docker compose version
echo "======================================"
echo "✓ EC2 setup complete!"
echo ""
echo "Next steps:"
echo "1. Set required GitHub secrets:"
echo "   - EC2_HOST"
echo "   - EC2_USER"
echo "   - EC2_KEY"
echo "   - DB_USER"
echo "   - DB_PASSWORD"
echo "   - DB_NAME"
echo ""
echo "2. Push to main branch to trigger deployment"
echo "3. Monitor GitHub Actions for deployment status"
