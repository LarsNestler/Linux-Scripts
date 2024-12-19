#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Validate input argument
if [[ -z "$1" ]]; then
    echo "Usage: $0 <WAZUH_MANAGER_IP_OR_HOSTNAME>" >&2
    exit 1
fi

# Set the WAZUH_MANAGER variable
WAZUH_MANAGER="$1"

# Step 1: Import Wazuh GPG key
if curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import; then
    chmod 644 /usr/share/keyrings/wazuh.gpg
    echo "Wazuh GPG key imported successfully."
else
    echo "Failed to import Wazuh GPG key." >&2
    exit 1
fi

# Step 2: Add Wazuh repository to sources list
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# Step 3: Update package list
if apt-get update; then
    echo "Package list updated successfully."
else
    echo "Failed to update package list." >&2
    exit 1
fi

# Step 4: Install Wazuh agent
if WAZUH_MANAGER=$WAZUH_MANAGER apt-get install -y wazuh-agent; then
    echo "Wazuh agent installed successfully."
else
    echo "Failed to install Wazuh agent." >&2
    exit 1
fi

# Step 5: Enable and start Wazuh agent
systemctl daemon-reload
if systemctl enable wazuh-agent && systemctl start wazuh-agent; then
    echo "Wazuh agent enabled and started successfully."
else
    echo "Failed to enable or start Wazuh agent." >&2
    exit 1
fi

# Step 6: Hold Wazuh agent to prevent accidental updates
echo "wazuh-agent hold" | dpkg --set-selections
if [[ $? -eq 0 ]]; then
    echo "Wazuh agent hold applied successfully."
else
    echo "Failed to apply hold to Wazuh agent." >&2
    exit 1
fi

# Final message
echo "Wazuh agent setup completed successfully."
