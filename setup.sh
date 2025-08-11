#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
print_step() {
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

# --- Main Execution ---

# Ensure the script is not run as root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root. It will prompt for sudo password when needed."
  exit 1
fi

print_step "Starting Raspberry Pi Crawler Setup (Berry-Picker)"

# 1. System Update and Upgrade
print_step "Updating and upgrading system packages..."
sudo apt-get update && sudo apt-get full-upgrade -y

# 2. Install Core Dependencies
print_step "Installing essential packages: python, pip, venv, screen, firefox, and jq..."
sudo apt-get install -y python3-pip python3-venv screen firefox-esr jq

# 3. Install GeckoDriver (for Selenium)
print_step "Downloading and installing the latest GeckoDriver for ARM..."

# Get the latest geckodriver download URL for arm7hf architecture from GitHub API
GECKODRIVER_URL=$(curl -s https://api.github.com/repos/mozilla/geckodriver/releases/latest | jq -r '.assets[] | select(.name | contains("arm7hf")) | .browser_download_url')

if [ -z "$GECKODRIVER_URL" ] || [ "$GECKODRIVER_URL" == "null" ]; then
    echo "ERROR: Could not find GeckoDriver URL for arm7hf. Exiting."
    exit 1
fi

echo "Found GeckoDriver URL: $GECKODRIVER_URL"
wget -O geckodriver.tar.gz "$GECKODRIVER_URL"

# Extract and install
tar -xzf geckodriver.tar.gz
sudo mv geckodriver /usr/local/bin/
echo "GeckoDriver installed successfully to /usr/local/bin/"

# Clean up downloaded file
rm geckodriver.tar.gz

# 4. Create Python Virtual Environment
VENV_DIR="$HOME/venv/crawler"
print_step "Creating Python virtual environment at $VENV_DIR..."

# Create the parent directory if it doesn't exist
mkdir -p "$(dirname "$VENV_DIR")"

# Create the virtual environment
python3 -m venv "$VENV_DIR"
echo "Virtual environment created."

# 5. Install Python Packages from requirements.txt
REQUIREMENTS_FILE="requirements.txt"
print_step "Installing Python packages from $REQUIREMENTS_FILE..."

if [ -f "$REQUIREMENTS_FILE" ]; then
    # Use the pip from the venv directly to avoid activation issues in scripts
    "$VENV_DIR/bin/pip" install -r "$REQUIREMENTS_FILE"
    echo "Python packages installed."
else
    echo "WARNING: $REQUIREMENTS_FILE not found. Skipping Python package installation."
fi

# 6. Overwrite .bashrc
BASHRC_FILE="bashrc"
print_step "Updating .bashrc..."

if [ -f "$BASHRC_FILE" ]; then
    # Create a backup of the original .bashrc
    echo "Backing up current .bashrc to ~/.bashrc.bak"
    cp ~/.bashrc ~/.bashrc.bak
    
    # Copy the new bashrc file from the repo
    echo "Copying new bashrc file to home directory..."
    cp ./"$BASHRC_FILE" ~/.bashrc
    echo ".bashrc updated."
else
    echo "WARNING: 'bashrc' file not found in repo. Skipping update."
fi


print_step "Setup Complete!"
echo "----------------------------------------"
echo "To apply the new .bashrc changes, please run:"
echo "source ~/.bashrc"
echo "or restart your terminal session."
echo ""
echo "You can activate the crawler's environment with the 'crawler' command."