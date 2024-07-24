#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Create a user for Node Exporter
echo "Creating node_exporter user..."
sudo useradd --no-create-home --shell /bin/false node_exporter

# Download and install Node Exporter
NODE_EXPORTER_VERSION="1.8.2"
echo "Downloading Node Exporter version $NODE_EXPORTER_VERSION..."
cd /tmp
curl -LO https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

echo "Extracting Node Exporter..."
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/

echo "Setting ownership for node_exporter..."
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service file for Node Exporter
echo "Creating systemd service file for Node Exporter..."
sudo bash -c 'cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --collector.disable-defaults \
  --collector.cpu \
  --collector.meminfo \
  --collector.loadavg

[Install]
WantedBy=default.target
EOF'

# Reload systemd, start, and enable Node Exporter service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Starting Node Exporter service..."
sudo systemctl start node_exporter

echo "Enabling Node Exporter service to start on boot..."
sudo systemctl enable node_exporter

echo "Node Exporter installation and configuration complete."

# Output status of Node Exporter service
sudo systemctl status node_exporter --no-pager
