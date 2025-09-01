#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---
print_step() {
    echo "----------------------------------------"
    echo "➡️  $1"
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
print_step "Installing essential packages: git, python, pip, venv, screen, firefox, and jq..."
sudo apt-get install -y git python3-pip python3-venv screen firefox-esr jq firefox

# 3. Install GeckoDriver (for Selenium)
print_step "Downloading and installing the latest GeckoDriver for ARM..."
GECKODRIVER_URL="https://github.com/mozilla/geckodriver/releases/download/v0.36.0/geckodriver-v0.36.0-linux-aarch64.tar.gz"

GECKODRIVER_URL=$(curl -s https://api.github.com/repos/mozilla/geckodriver/releases/latest | jq -r '.assets[] | select(.name | contains("arm7hf")) | .browser_download_url')

if [ -z "$GECKODRIVER_URL" ] || [ "$GECKODRIVER_URL" == "null" ]; then
    echo "ERROR: Could not find GeckoDriver URL for arm7hf. Exiting."
    exit 1
fi

echo "Found GeckoDriver URL: $GECKODRIVER_URL"
wget -O geckodriver.tar.gz "$GECKODRIVER_URL"

tar -xzf geckodriver.tar.gz
sudo mv geckodriver /usr/local/bin/
echo "GeckoDriver installed successfully to /usr/local/bin/"
rm geckodriver.tar.gz

# 4. Setup SSH Keys
print_step "Setting up SSH keys..."
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY_PATH="$SSH_DIR/id_rsa"
PUBLIC_KEY_PATH="$SSH_DIR/id_rsa.pub"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Always generate a new SSH key for this device. Backup existing keys if they exist.
if [ -f "$PRIVATE_KEY_PATH" ]; then
    echo "Existing private key found. Backing up to $PRIVATE_KEY_PATH.bak"
    mv "$PRIVATE_KEY_PATH" "$PRIVATE_KEY_PATH.bak"
fi
if [ -f "$PUBLIC_KEY_PATH" ]; then
    echo "Existing public key found. Backing up to $PUBLIC_KEY_PATH.bak"
    mv "$PUBLIC_KEY_PATH" "$PUBLIC_KEY_PATH.bak"
fi

echo "Generating a new SSH key..."
ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N "" # -N "" for no passphrase
echo "New SSH key generated for this device."

# Add authorized public keys from .env file for incoming connections
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    print_step "Found .env file. Checking for authorized keys..."
    set -a # automatically export all variables
    source "$ENV_FILE"
    set +a

    if [ -n "$AUTHORIZED_SSH_KEYS" ]; then
        AUTHORIZED_KEYS_PATH="$SSH_DIR/authorized_keys"
        echo "Adding public keys to $AUTHORIZED_KEYS_PATH"
        echo -e "$AUTHORIZED_SSH_KEYS" >> "$AUTHORIZED_KEYS_PATH"
        chmod 600 "$AUTHORIZED_KEYS_PATH"
        echo "Authorized keys added."
    else
        echo "No AUTHORIZED_SSH_KEYS variable found in .env file."
    fi
else
    echo "No .env file found. Skipping authorized key setup."
fi

# 5. Create Python Virtual Environment
VENV_DIR="$HOME/venv/crawler"
print_step "Creating Python virtual environment at $VENV_DIR..."

mkdir -p "$(dirname "$VENV_DIR")"
python3 -m venv "$VENV_DIR"
echo "Virtual environment created."

# 6. Install Python Packages from requirements.txt
REQUIREMENTS_FILE="requirements.txt"
print_step "Installing Python packages from $REQUIREMENTS_FILE..."

if [ -f "$REQUIREMENTS_FILE" ]; then
    # Use the pip from the venv directly to avoid activation issues in scripts
    "$VENV_DIR/bin/pip" install -r "$REQUIREMENTS_FILE"
    echo "Python packages installed."
else
    echo "WARNING: $REQUIREMENTS_FILE not found. Skipping Python package installation."
fi

# 7. Add Custom Bash Aliases
ALIASES_FILE="bash_aliases"
print_step "Adding custom aliases to ~/.bash_aliases..."

if [ -f "$ALIASES_FILE" ]; then
    echo "" >> ~/.bash_aliases # Add a newline for separation
    cat ./"$ALIASES_FILE" >> ~/.bash_aliases
    echo "Custom aliases added."
else
    echo "WARNING: '$ALIASES_FILE' file not found in repo. Skipping."
fi


print_step "Setup Complete!"
echo "----------------------------------------"
echo "To apply the new aliases, please run:"
echo "source ~/.bashrc"
echo "or restart your terminal session."
echo ""
echo "You can activate the crawler's environment with the 'start_crawler' command."

# --- Optional: Setup Surfshark OpenVPN ---
# Uncomment the following line to run the Surfshark setup script.
sudo ./setup_surfshark_openvpn.sh
