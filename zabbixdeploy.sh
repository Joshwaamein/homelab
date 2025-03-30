#!/bin/bash

# Set variables
ZABBIX_SERVER="100.85.45.123"
HOSTNAME=$(hostname)
DOWNLOAD_URL="https://cdn.zabbix.com/zabbix/binaries/stable/7.2/7.2.4/zabbix_agent-7.2.4-linux-3.0-amd64-static.tar.gz"
INSTALL_DIR="/opt/zabbix"
CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"

# Create necessary directories
sudo mkdir -p /etc/zabbix
sudo mkdir -p $INSTALL_DIR
sudo mkdir -p /var/log/zabbix

# Download and extract Zabbix agent
cd /tmp
wget $DOWNLOAD_URL
tar -xzvf zabbix_agent-7.2.4-linux-3.0-amd64-static.tar.gz
sudo cp -r zabbix_agent-7.2.4/* $INSTALL_DIR/

# Create zabbix user if it doesn't exist
if ! id -u zabbix >/dev/null 2>&1; then
    sudo useradd -r -M -s /bin/false zabbix
fi

# Create configuration file
sudo tee $CONFIG_FILE > /dev/null << EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$ZABBIX_SERVER
ServerActive=$ZABBIX_SERVER
Hostname=$HOSTNAME
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF

# Create directory for PID file
sudo mkdir -p /var/run/zabbix
sudo chown zabbix:zabbix /var/run/zabbix
sudo chown zabbix:zabbix /var/log/zabbix

# Create systemd service file
sudo tee /etc/systemd/system/zabbix-agent.service > /dev/null << EOF
[Unit]
Description=Zabbix Agent
After=network.target

[Service]
Type=simple
User=zabbix
ExecStart=$INSTALL_DIR/sbin/zabbix_agentd -c $CONFIG_FILE -f
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable zabbix-agent
sudo systemctl start zabbix-agent

# Check status
sudo systemctl status zabbix-agent

# Clean up
rm -rf /tmp/zabbix_agent-7.2.4*

echo "Zabbix agent installation completed!"
