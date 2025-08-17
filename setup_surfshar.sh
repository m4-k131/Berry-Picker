#!/bin/bash

# A script to install, configure, and automate Surfshark VPN on a Debian-based system.
# Accepts one optional argument: the location code.
# If no argument is provided, it prompts the user interactively.

# --- Color Definitions for clearer output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Pre-run Checks ---
# 1. Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root. Please use 'sudo ./setup_surfshark.sh'${NC}"
   exit 1
fi

# --- Functions ---
install_surfshark() {
    echo -e "${YELLOW}Surfshark client not found. Starting installation...${NC}"
    # Download the official installer script
    if ! wget -q https://downloads.surfshark.com/linux/debian-install.sh; then
        echo -e "${RED}Error: Failed to download the installation script.${NC}"
        exit 1
    fi
    # Run the installer
    chmod +x debian-install.sh
    ./debian-install.sh
    # Clean up the installer
    rm debian-install.sh
    # Install the package itself
    echo -e "${YELLOW}Updating package lists and installing surfshark...${NC}"
    if ! (apt-get update && apt-get install -y surfshark); then
        echo -e "${RED}Error: Failed to install the surfshark package via apt.${NC}"
        exit 1
    fi
    
    # --- IMPORTANT FIX ---
    # Reset the shell's command cache so it finds the new command
    hash -r
    
    echo -e "${GREEN}Surfshark installation complete.${NC}"
}

login_surfshark() {
    echo -e "\n${YELLOW}--- Account Login ---${NC}"
    echo "The script will now run the login command. A unique code will be displayed."
    echo "On another device (phone/computer), go to: ${GREEN}https://my.surfshark.com/account/device-login${NC}"
    echo "Log in to your account and enter the code from your terminal to authorize this device."
    echo -e "-----------------------------------------------------------------------------------"
    
    surfshark-vpn login
    
    read -p "Press [Enter] to continue after you have successfully authorized this device..."
}


# --- Main Execution ---
echo -e "${GREEN}--- Surfshark VPN Setup Script ---${NC}"

# 1. Install if necessary
if ! command -v surfshark-vpn &> /dev/null; then
    install_surfshark
else
    echo -e "${GREEN}Surfshark client is already installed.${NC}"
fi

# 2. Log in (always offer, as checking login status is tricky)
login_surfshark

# 3. Set protocol to WireGuard (recommended for performance)
echo -e "\n${YELLOW}Setting VPN protocol to WireGuard...${NC}"
surfshark-vpn set protocol wireguard

# 4. Determine VPN location from argument or user prompt
VPN_LOCATION=$1
if [ -z "$VPN_LOCATION" ]; then
    echo -e "\n${YELLOW}No location argument provided. Displaying available locations...${NC}"
    surfshark-vpn locations
    echo "----------------------------------------------------------------"
    while [ -z "$VPN_LOCATION" ]; do
        read -p "Please enter the desired location code from the list above: " VPN_LOCATION
    done
else
    echo -e "\n${GREEN}Location argument found. Using: $VPN_LOCATION${NC}"
fi

echo -e "${YELLOW}Target location set to: $VPN_LOCATION${NC}"

# 5. Create and enable the systemd service for persistence
echo -e "\n${YELLOW}Creating and configuring systemd service for auto-start...${NC}"

# Stop and disable any old version of the service first
systemctl stop surfshark.service >/dev/null 2>&1
systemctl disable surfshark.service >/dev/null 2>&1

# Create the new service file using a "here document"
cat <<EOF > /etc/systemd/system/surfshark.service
[Unit]
Description=Surfshark VPN Client - Connects to ${VPN_LOCATION}
After=network-online.target

[Service]
Type=simple
# KillMode=process is important to ensure a clean stop/restart
KillMode=process
ExecStart=/usr/bin/surfshark-vpn connect ${VPN_LOCATION}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 6. Reload daemon and start the service
systemctl daemon-reload
systemctl enable surfshark.service
systemctl start surfshark.service

echo -e "\n${GREEN}--- Setup Complete! ---${NC}"
echo "The service has been created and started. The Pi will now automatically connect to ${GREEN}${VPN_LOCATION}${NC} on boot."
echo "Giving it a few seconds to connect before showing the final status..."
sleep 5

# 7. Show final status
echo -e "\n${YELLOW}--- Current VPN Status ---${NC}"
surfshark-vpn status
echo -e "\n${YELLOW}--- Systemd Service Status ---${NC}"
systemctl status surfshark.service