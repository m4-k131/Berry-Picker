#!/bin/bash

# A script to set up a Surfshark OpenVPN connection from the official config zip.
# Reads credentials from a .env file, or prompts the user if not found.

# --- Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Configuration ---
CONFIG_ZIP="Surfshark_Config.zip"
CONFIG_DIR="Surfshark_Configs"
AUTH_FILE="/etc/openvpn/client/surfshark.auth"

# --- Pre-run Checks ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root. Please use 'sudo ./setup_openvpn.sh'${NC}"
   exit 1
fi

if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}unzip could not be found. Installing...${NC}"
    apt-get update && apt-get install -y unzip
fi

if [ ! -f "$CONFIG_ZIP" ]; then
    echo -e "${RED}Error: '$CONFIG_ZIP' not found in the current directory.${NC}"
    exit 1
fi

# --- Main Execution ---
echo -e "${GREEN}--- Surfshark OpenVPN Setup ---${NC}"

# 0. Aggressive Cleanup of any previous connections
echo -e "\n${YELLOW}Stopping and cleaning up any old OpenVPN connections...${NC}"
sudo systemctl stop 'openvpn-client@*.service' >/dev/null 2>&1
sudo killall openvpn >/dev/null 2>&1
sleep 1 # Give the system a moment to release resources

# 1. Unzip the configuration files...
# ... rest of your script

# 1. Unzip the configuration files
echo -e "${YELLOW}Unzipping '$CONFIG_ZIP' into './$CONFIG_DIR/'...${NC}"
unzip -o "$CONFIG_ZIP" -d "$CONFIG_DIR" > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to unzip the configuration file.${NC}"
    exit 1
fi

# 2. Get Location and Protocol from user or arguments
LOCATION=$1
PROTOCOL=$2

if [ -z "$LOCATION" ]; then
    echo -e "\n${YELLOW}Please provide the server location code (e.g., de-ber, us-nyc, au-syd).${NC}"
    read -p "Enter location code: " LOCATION
fi

if [ -z "$PROTOCOL" ]; then
    PS3="Select a protocol: "
    select proto in "udp" "tcp"; do
        PROTOCOL=$proto
        break
    done
fi

# 3. Validate that the config file exists
OVPN_FILENAME="${LOCATION}.prod.surfshark.com_${PROTOCOL}.ovpn"
OVPN_SOURCE_PATH="./${CONFIG_DIR}/${OVPN_FILENAME}"

echo -e "\n${YELLOW}Checking for configuration file: $OVPN_SOURCE_PATH...${NC}"
if [ ! -f "$OVPN_SOURCE_PATH" ]; then
    echo -e "${RED}Error: Configuration file not found for location '$LOCATION' with protocol '$PROTOCOL'.${NC}"
    rm -rf "$CONFIG_DIR"
    exit 1
fi
echo -e "${GREEN}Configuration file found!${NC}"

# 4. Get user credentials from .env file or interactive prompt
echo -e "\n${YELLOW}Attempting to load credentials...${NC}"
if [ -f ".env" ]; then
    echo "Found .env file, reading variables..."
    # Safely read variables from the .env file
    OVPN_USER=$(grep '^surfshark_username=' .env | cut -d'=' -f2-)
    OVPN_PASS=$(grep '^surfshark_password=' .env | cut -d'=' -f2-)
fi

# Fallback to prompt if variables are empty
if [ -z "$OVPN_USER" ]; then
    echo -e "${YELLOW}Username not found in .env, please provide it now.${NC}"
    echo "(Credentials are found in your account under VPN -> Manual setup -> Router -> OpenVPN)"
    read -p "Enter Username: " OVPN_USER
else
    echo -e "${GREEN}Username loaded from .env file.${NC}"
fi

if [ -z "$OVPN_PASS" ]; then
    echo -e "${YELLOW}Password not found in .env, please provide it now.${NC}"
    read -s -p "Enter Password: " OVPN_PASS
    echo "" # Newline after silent password entry
else
    echo -e "${GREEN}Password loaded from .env file.${NC}"
fi

# 5. Create and secure the authentication file
echo -e "\n${YELLOW}Creating and securing credentials file at '$AUTH_FILE'...${NC}"
echo -e "$OVPN_USER\n$OVPN_PASS" | sudo tee "$AUTH_FILE" > /dev/null
sudo chmod 600 "$AUTH_FILE"

# 6. Set up the OpenVPN connection file
SERVICE_NAME="surfshark-${LOCATION}-${PROTOCOL}"
CONFIG_DEST_PATH="/etc/openvpn/client/${SERVICE_NAME}.conf"

echo -e "${YELLOW}Copying config to '$CONFIG_DEST_PATH'...${NC}"
sudo cp "$OVPN_SOURCE_PATH" "$CONFIG_DEST_PATH"

echo -e "${YELLOW}Modifying config to use the credentials file...${NC}"
sudo sed -i "s|^auth-user-pass$|auth-user-pass $AUTH_FILE|" "$CONFIG_DEST_PATH"

# 7. Enable and start the service
echo -e "\n${YELLOW}Enabling and starting the OpenVPN service...${NC}"
sudo systemctl disable --now openvpn-client@* >/dev/null 2>&1
sudo systemctl enable --now "openvpn-client@${SERVICE_NAME}"

# 8. Clean up and report status
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -rf "$CONFIG_DIR"

echo -e "\n${GREEN}--- Setup Complete! ---${NC}"
echo "Giving it a few seconds to connect before checking status..."
sleep 5
sudo systemctl status "openvpn-client@${SERVICE_NAME}"