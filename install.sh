#!/bin/sh
set -e  # Exit on error

# Script to install Docker on Debian-based systems
# Run this script as root
if [ "$EUID" -ne 0 ]; then
echo "This script must be run as root."
exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print usage instructions
usage() {
    echo "Usage: $0 [username]"
    echo "  username: Optional. Add this user to the Docker group."
    exit 1
}

# Handle input arguments
if [ "$#" -gt 1 ]; then
    usage
fi
USER_TO_ADD="$1"

# Uninstall conflicting packages
echo "Uninstalling conflicting Docker packages, if any..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    if dpkg -l | grep -q "$pkg"; then
        echo "Removing $pkg..."
        apt-get remove -y "$pkg"
    fi
done

# Update package list
echo "Updating package list..."
apt-get update

# Install required dependencies
echo "Installing required dependencies..."
apt-get install -y ca-certificates curl gnupg

# Ensure keyring directory exists
install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# Update package list to pull new docker packages
echo "Updating package list after adding Docker repo..."
apt-get update

# Install Docker
echo "Installing Docker..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker service
echo "Enabling and starting Docker service..."
systemctl enable --now docker

# Add user to Docker group if provided
if [ -n "$USER_TO_ADD" ]; then
    if id "$USER_TO_ADD" >/dev/null 2>&1; then
        echo "Adding user $USER_TO_ADD to the docker group..."
        usermod -aG docker "$USER_TO_ADD"
        echo "User $USER_TO_ADD has been added to the docker group. Log out and log back in for changes to take effect."
    else
        echo "Error: User $USER_TO_ADD does not exist."
        exit 1
    fi
fi

echo "Docker installation complete."

