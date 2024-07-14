#!/bin/bash

# Ensure necessary tools are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq or curl is not installed. Please install them and try again."
    exit 1
fi

# List of node IPs for querying
NODE_IPS=(
"104.219.237.146:26667"
"37.27.109.215:26657"
"136.175.9.193:26657"
"85.10.196.25:26657"
"209.159.154.142:26657"
"104.243.40.149:26657"
"65.109.54.91:21657"
"158.220.87.136:26657"
"38.58.183.3:26657"
"51.159.215.215:26657"
"65.108.142.147:27657"
"138.201.82.234:26657"
"38.242.234.180:26657"
"93.159.130.38:35657"
"141.94.73.39:43657"
"142.132.202.87:26698"
"95.217.225.107:26657"
"65.109.16.220:26657"
"15.235.218.151:26667"
"88.198.12.182:26657"
"https://celestia-testnet-rpc.itrocket.net"
"https://celestia-testnet.rpc.kjnodes.com"
"https://celestia-testnet-rpc.stake-town.com"
"162.19.19.41:26657"
"5.9.10.222:26657"
"64.176.57.63:26657"
"141.95.35.218:26657"
"57.129.1.77:26657"
"37.27.119.173:26657"
"116.202.217.20:34657"
"217.160.102.31:26647"
"62.138.24.120:26657"
"88.99.219.120:43657"
"94.130.35.35:18657"
"95.216.223.149:26657"
"91.121.55.152:26657"
"125.253.92.7:26657"
"64.227.18.169:26657"
"195.14.6.178:26657"
"45.143.198.5:26657"
"95.217.200.98:21657"
"136.243.176.86:26657"
"141.94.135.203:26657"
"https://rpc-t.celestia.nodestake.top"
"162.55.65.137:11657"
)

# Port for querying
PORTS=(
"26667"
"26657"
"21657"
"27657"
"35657"
"43657"
"26698"
"443"
"34657"
"26647"
"18657"
"11657"
)

# Fetch list of validators
echo "Fetching list of validators..."
validators=$(celestia-appd q staking validators --output json)

# Check if validators list was obtained
if [[ -z "$validators" ]]; then
    echo "Failed to get list of validators"
    exit 1
fi

# Initialize peers file
> peers.txt

# Get peer information from nodes
for NODE_IP in "${NODE_IPS[@]}"; do
    for PORT in "${PORTS[@]}"; do
        echo "Querying node $NODE_IP on port $PORT..."
        response=$(curl -s --max-time 10 --connect-timeout 5 http://$NODE_IP:$PORT/net_info)
        
        if [[ $? -ne 0 || -z "$response" ]]; then
            echo "Failed to get response from node $NODE_IP:$PORT."
            continue
        fi

        if echo "$response" | jq empty &> /dev/null; then
            echo "$response" | jq -r '.result.peers[] | .node_info.moniker + " " + .remote_ip' >> peers.txt
            break  # Exit inner loop after getting first IP
        else
            echo "No valid data from node $NODE_IP:$PORT"
        fi
    done
done

# Parse JSON and match validators with IP addresses
echo "$validators" | jq -r '.validators[] | .description.moniker + " " + .operator_address' > validators.txt

echo "List of validators and their IP addresses:" > result.txt
while read -r validator; do
    moniker=$(echo "$validator" | awk '{print $1}')
    address=$(echo "$validator" | awk '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk '{print $2}' | sort | uniq | head -n 1)  # Get only the first IP
    if [[ -n "$ip_list" && "$ip_list" != "None" ]]; then
        echo "Validator: $moniker, Address: $address, IP: $ip_list" | tee -a result.txt
    else
        echo "Validator: $moniker, Address: $address, IP: None" | tee -a result.txt
    fi
done < validators.txt

echo "Results saved to result.txt"

# Get geolocation and hosting data for IP addresses
echo "Fetching geolocation and hosting data..."
> geo_results.txt  # Initialize file
while read -r line; do
    ip=$(echo "$line" | awk -F 'IP: ' '{print $2}')
    if [[ "$ip" != "None" ]]; then
        echo "Querying geolocation for IP: $ip..."
        geo_info=$(curl -s ipinfo.io/$ip)
        if [[ -n "$geo_info" ]]; then
            city=$(echo "$geo_info" | jq -r '.city // "Unknown"')
            region=$(echo "$geo_info" | jq -r '.region // "Unknown"')
            country=$(echo "$geo_info" | jq -r '.country // "Unknown"')
            loc=$(echo "$geo_info" | jq -r '.loc // "0.0,0.0"')
            org=$(echo "$geo_info" | jq -r '.org // "Unknown"')
            lat="${loc%%,*}"
            lng="${loc##*,}"
            echo "$line, $city, $region, $country, $lat, $lng, $org" >> geo_results.txt
        else
            echo "$line, Unknown, Unknown, Unknown, 0.0, 0.0, Unknown" >> geo_results.txt  # Ensure every line has the right number of fields
        fi
    else
        echo "$line, Unknown, Unknown, Unknown, 0.0, 0.0, Unknown" >> geo_results.txt  # Ensure every line has the right number of fields
    fi
done < result.txt

echo "Geolocation and hosting data saved to geo_results.txt"

# Transition to Python script for map display
python3 plot_map.py
