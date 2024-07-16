#!/bin/bash

# This script configures a static IP address for a specified network interface on a Linux system.
# It logs the process to a log file located at /var/log/static_ip_setup.log for troubleshooting and auditing purposes.
# The script performs the following steps:
# 1. Logs the start of the script execution.
# 2. Defines the network interface (default: eth0).
# 3. Runs dhclient to obtain current DHCP settings.
# 4. Extracts the DHCP-assigned IP address from the dhclient output.
# 5. Retrieves the default gateway from the current routing table.
# 6. Derives the base IP address (removing the last octet).
# 7. Constructs a new static IP address by appending ".242" to the base IP.
# 8. Retrieves the connection name associated with the network interface.
# 9. Waits for a few seconds to ensure the connection name retrieval has settled.
# 10. Writes the new static IP configuration to /etc/network/interfaces.d/<interface>.
# 11. Logs the applied static IP setting.
# 12. Restarts the networking service to apply the new configuration.
# 13. Logs the completion of the script execution.

# Log file
LOG_FILE="/var/log/static_ip_setup.log"

# Log function
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log "Starting static IP setup script."

# Define the network interface
interface="eth0"

# Run dhclient to get the current DHCP settings (if needed)
output=$(sudo /sbin/dhclient -v 2>&1)
log "DHClient output: $output"

# Extract the DHCP-assigned IP address
dhcp_ack=$(echo "$output" | grep -oP 'DHCPACK of \K[0-9.]+')
log "DHCP ACK IP: $dhcp_ack"

# Get the default gateway
default_gateway=$(ip route | grep default | awk '{print $3}')
log "Default gateway: $default_gateway"
# Extract the base IP address (excluding the last octet)
base_ip=$(echo $dhcp_ack | sed 's/\.[0-9]\+$//')
log "Base IP: $base_ip"

# Define the new static IP address ending with 141
static_ip="${base_ip}.242"
log "Static IP: $static_ip"

# Get the connection name associated with wlan0
connection_name=$(sudo nmcli -t -f NAME,DEVICE connection show | grep ":$interface" | cut -d: -f1)
log "Connection name: $connection_name"

# Sleep to ensure that the connection name retrieval has settled
sleep 3

outfile="/etc/network/interfaces.d/$interface"
echo "" > $outfile
echo "auto $interface" >> $outfile
echo "iface $interface inet static" >> $outfile
echo "    address $static_ip" >> $outfile
echo "    netmask 255.255.255.0" >> $outfile
#echo "    gateway $default_gateway" >> $outfile
#echo "    dns-nameservers 8.8.8.8" >> $outfile
log "Applied static IP settig"

sudo systemctl restart networking
log "Restarted connection."

log "Static IP setup script completed."