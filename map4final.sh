#!/bin/bash

# Ensure necessary tools are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq or curl is not installed. Please install them and try again."
    exit 1
fi

# List of node IPs for querying
NODE_IPS=(
"104.219.237.146"
"37.27.109.215"
"136.175.9.193"
"85.10.196.25"
"209.159.154.142"
"104.243.40.149"
"65.109.54.91"
"158.220.87.136"
"38.58.183.3"
"51.159.215.215"
"65.108.142.147"
"138.201.82.234"
"38.242.234.180"
"93.159.130.38"
"141.94.73.39"
"142.132.202.87"
"95.217.225.107"
"65.109.16.220"
"15.235.218.151"
"88.198.12.182"
"162.19.19.41"
"5.9.10.222"
"64.176.57.63"
"141.95.35.218"
"57.129.1.77"
"37.27.119.173"
"116.202.217.20"
"217.160.102.31"
"62.138.24.120"
"88.99.219.120"
"94.130.35.35"
"95.216.223.149"
"91.121.55.152"
"125.253.92.7"
"64.227.18.169"
"195.14.6.178"
"45.143.198.5"
"95.217.200.98"
"136.243.176.86"
"141.94.135.203"
"162.55.65.137"
"https://celestia-testnet-rpc.itrocket.net/"
"https://celestia-testnet.rpc.kjnodes.com/"
"https://celestia-testnet-rpc.stake-town.com/"
"https://celestia.test.rpc.nodeshub.online/"
"https://celestia.rpc.testnets.services-ernventures.com/"
"https://celestia-rpc.0xcryptovestor.com"
"https://rpc.celestia.nodestake.top"
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
"34657"
"26647"
"18657"
"11657"
"443"
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

echo "Validator,IP" > result.txt
while read -r validator; do
    moniker=$(echo "$validator" | awk '{print $1}')
    address=$(echo "$validator" | awk '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk '{print $2}' | sort | uniq | head -n 1)  # Get only the first IP
    if [[ -n "$ip_list" && "$ip_list" != "None" ]]; then
        echo "$moniker,$ip_list" | tee -a result.txt
    else
        echo "$moniker,None" | tee -a result.txt
    fi
done < validators.txt

echo "Results saved to result.txt"

# Get geolocation and hosting data for IP addresses
echo "Fetching geolocation and hosting data..."
> geo_results.txt  # Initialize file
while read -r line; do
    ip=$(echo "$line" | awk -F ',' '{print $2}')
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
            echo "$line,$city,$region,$country,$lat,$lng,$org" >> geo_results.txt
        else
            echo "$line,Unknown,Unknown,Unknown,0.0,0.0,Unknown" >> geo_results.txt  # Ensure every line has the right number of fields
        fi
    else
        echo "$line,Unknown,Unknown,Unknown,0.0,0.0,Unknown" >> geo_results.txt  # Ensure every line has the right number of fields
    fi
done < result.txt

echo "Geolocation and hosting data saved to geo_results.txt"

# Transition to Python script for map display
python3 plot_map.py
